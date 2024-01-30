// ignore_for_file: avoid_print

import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_swipe_detector/flutter_swipe_detector.dart';
import 'package:uuid/uuid.dart';

import '../../../../services/my_get_storage.dart';
import '../../../../services/service_locator.dart';
import '../models/tile.dart';
import '../models/board.dart';

import 'next_direction.dart';
import 'round.dart';

///
/// 这一个状态通知器应该是游戏的主要状态管理，
/// 包括创建新游戏、结束游戏、移动图块、合并图块等
///
class BoardManager extends StateNotifier<Board> {
  // 统一简单存储操作的工具类实例
  final _simpleStorage = getIt<MyGetStorage>();

  // We will use this list to retrieve the right index when user swipes up/down
  // which will allow us to reuse most of the logic.
  // 当玩家向上/向下(即垂直方向)滑动时，将使用该列表来检索正确的索引，这样就可以重复使用大部分逻辑。
  final verticalOrder = [12, 8, 4, 0, 13, 9, 5, 1, 14, 10, 6, 2, 15, 11, 7, 3];

  ///  垂直方向滑动时，棋盘4*4 的方块索引如下左边，水平方向滑动索引如右边:
  ///  这样垂直方向的滑动和水平方向的滑动的逻辑就可以通用了
  ///  12, 8,  4, 0,  ↑↓      0, 1, 2, 3,    ←→
  ///  13, 9,  5, 1,  ↑↓      4, 5, 6, 7,    ←→
  ///  14, 10, 6, 2,  ↑↓      8, 9, 10,11,   ←→
  ///  15, 11, 7, 3,  ↑↓      12,13,14,15,   ←→

  final StateNotifierProviderRef ref;
  BoardManager(this.ref) : super(Board.newGame(0, 0, [])) {
    // 加载上一次保存的状态或者开始新游戏
    load();
  }

  // 从本地缓存获取上一次的棋盘状态
  void load() async {
    var oldState = _simpleStorage.get2048BoardState();

    // 如果没有本地缓存，将启动一个新游戏。
    state = oldState ?? _newGame();

    // 2024-01-30 一点小修复：如果上次保存时已经是游戏结束的状态，则本次初始化也是开始新游戏
    // 重复赋值上面的state也会覆盖，所以不用管它
    if (oldState != null && oldState.over) {
      newGame();
    }
  }

  // 创建一个新游戏棋盘状态
  Board _newGame() {
    return Board.newGame(state.best + state.score, state.bestNum, [random([])]);
  }

  // 开始新游戏
  void newGame() {
    state = _newGame();
  }

  // 检查索引是否在棋盘的同一行或列中。
  //   对照上面横向滑动或纵向滑动时不同的索引矩阵设定，那么同一行或者列的判断是通用的，就是
  //    当前索引 [0.4)   且下一步索引 [0.4)  ，或
  //    当前索引 [4,8)   且下一步索引 [4,8)  ，或
  //    当前索引 [8,12)  且下一步索引 [8,12) ，或
  //    当前索引 [12,16) 且下一步索引 [12,16)
  bool _inRange(index, nextIndex) {
    return index < 4 && nextIndex < 4 ||
        index >= 4 && index < 8 && nextIndex >= 4 && nextIndex < 8 ||
        index >= 8 && index < 12 && nextIndex >= 8 && nextIndex < 12 ||
        index >= 12 && nextIndex >= 12;
  }

  /// ？？？还不是很明白
  ///  _calculate 函数计算当前数字方块的 nextIndex
  /// tile 是目标移动的方块；tiles 是要棋盘上各个索引中的所有方块，dirrection 是滑动方向
  Tile _calculate(Tile tile, List<Tile> tiles, direction) {
    // 是否是升序（手势向左或者向上滑动，方块移动的顺序是从左往后或者从上往下的顺序移动）
    // 比如(0处有方块，无法移动；1处有方块，尝试移动到0；2处有方块，尝试移动到0；以此类推，后续加上是否合并等)
    bool asc =
        direction == SwipeDirection.left || direction == SwipeDirection.up;
    // 是否是纵向（向上或者向下滑动使用的棋盘索引和默认水平的有一点区别）
    bool vert =
        direction == SwipeDirection.up || direction == SwipeDirection.down;

    /// 从左侧获取该行的第一个索引
    ///
    /// 示例：向左滑动时，可以是 0, 4, 8, 12，向右滑动可以是 3, 7, 11, 15，取决于需要在棋盘上的哪一行哪一列中进行操作。
    /// 假设 title.index = 6（这是第二行左起第三张、右起第二张的数字方块）
    ///
    /// ceil() 表示它“总是”向上取整到下一个最大整数
    /// 注意：不要将 ceil 与 floor 或 round 混淆，因为即使值是 2.1，输出也会是 3。
    ///  ((6 + 1) / 4) = 1.75; ceil(1.75) = 2
    ///
    /// 如果是升序(ascending)：  2 * 4 - 4 = 4，这是第二行左起的第一个索引
    /// 如果是降序(descending)： 2 * 4 - 1 = 7，这是第二行左起的最后一个索引、右起的第一个索引
    ///
    /// 如果用户垂直滑动，则使用 verticalOrder 列表检索上/下索引，否则使用现有的默认索引
    int index = vert ? verticalOrder[tile.index] : tile.index;
    int nextIndex = ((index + 1) / 4).ceil() * 4 - (asc ? 4 : 1);

    // 如果要渲染的新的数字方块列表不为空，则获取最后一个数字方块；
    // 如果该方块与当前方块位于同一行，则将当前方块的下一个索引设置为在上一个方块之后
    if (tiles.isNotEmpty) {
      var last = tiles.last;

      // 如果用户垂直方向滑动，则使用 verticalOrder 列表获取上/下方向的索引，否则使用现有索引
      var lastIndex = last.nextIndex ?? last.index;
      lastIndex = vert ? verticalOrder[lastIndex] : lastIndex;
      if (_inRange(index, lastIndex)) {
        // If the order is ascending set the tile after the last processed tile
        // If the order is descending set the tile before the last processed tile
        nextIndex = lastIndex + (asc ? 1 : -1);
      }
    }

    // Return immutable copy of the current tile with the new next index
    // which can either be the top left index in the row or the last tile nextIndex/index + 1
    // 返回当前数字方块的不可变副本和该方块的 nextIndex；
    // 这个新的nextIndex可以是行中左上角的索引，也可以是上一个方块 nextIndex/index + 1
    return tile.copyWith(
        nextIndex: vert ? verticalOrder.indexOf(nextIndex) : nextIndex);
  }

  /// ？？？还不是很明白
  /// 核心逻辑：数字方块的移动逻辑 (Move the tile in the direction)
  ///
  /// 要理解一点：假设用户向左滑动，图块从右到左移动，但数字方块合并和移动是从左到右发生的。
  /// 比如现在的棋盘如下(0表示空白)，棋盘上的索引如右边
  /// 0 2 2 0   -   [0, 1, 2, 3,
  /// 0 0 0 0   -    4, 5, 6, 7,
  /// 0 0 0 0   -    8, 9, 10,11,
  /// 0 0 0 0   -    12,13,14,15]
  ///
  ///  想法是保留一个Tiles 列表，每次需要向某个方向移动（本例中为从右向左移动）时，就在列表中循环（从索引 0 开始），
  ///  并将每个 tile 与数组中的下一个 tile 进行比较，然后决定是否采用某些规则(合并、紧挨等等)。
  ///
  ///  暂时把 索引1 处的方块命名为 tileA ，索引2 处的方块命名为 tileB
  ///  手势从右往左滑动时，但方块是从左到右先移动 tileA 再移动 tileB:
  ///   首先 tileA 的 nextIndex 会是 0 ,然后考虑 tileB 能否移动到索引0
  ///     结果是可以，那么 tileB 的 nextIndex 也是0
  ///     如果不可以(比如tileB数值其实是4)，那么 tileB 的 nextIndex = TileA 的 NextIndex + 1，此时 TileB 将紧邻 TileA
  ///   分配新索引后，将使用特殊方法来计算每个图块的左侧和顶部，并告诉动画系统如何将每个图块从棋盘上的 A 点移动到 B 点.
  ///   移动完成后，将通过求和它们的值来合并具有相同索引的图块。
  bool move(SwipeDirection direction) {
    bool asc =
        direction == SwipeDirection.left || direction == SwipeDirection.up;
    bool vert =
        direction == SwipeDirection.up || direction == SwipeDirection.down;

    // 按索引对列表进行排序，如果是垂直方向滑动使用对应的索引列表去获取上下个索引（在向左/上滑动的情况下从最低到最大）
    // 以水平滑动为例：如果向左滑动，保持compareTo输出的倍数为1，列表滑块升序排序；否则将其乘以-1，这将按降序对方块进行排序。
    state.tiles.sort(((a, b) =>
        (asc ? 1 : -1) *
        (vert
            ? verticalOrder[a.index].compareTo(verticalOrder[b.index])
            : a.index.compareTo(b.index))));

    List<Tile> tiles = [];

    for (int i = 0, l = state.tiles.length; i < l; i++) {
      var tile = state.tiles[i];

      // Calculate nextIndex for current tile.
      // 计算数字方块的下一个索引
      tile = _calculate(tile, tiles, direction);
      tiles.add(tile);

      if (i + 1 < l) {
        var next = state.tiles[i + 1];
        // Assign current tile nextIndex or index to the next tile if its allowed to be moved.
        // 如果允许移动，则将当前方块的 nextIndex 或 index 分配给下一个方块。
        if (tile.value == next.value) {
          // 如果用户垂直滑动，则使用垂直顺序列表检索上/下索引，否则使用现有索引
          // If user swipes vertically use the verticalOrder list to retrieve the up/down index else use the existing index
          var index = vert ? verticalOrder[tile.index] : tile.index,
              nextIndex = vert ? verticalOrder[next.index] : next.index;
          if (_inRange(index, nextIndex)) {
            tiles.add(next.copyWith(nextIndex: tile.nextIndex));
            // Skip next iteration if next tile was already assigned nextIndex.
            // 如果已经分配了 nextIndex，则跳过下一次迭代。
            i += 1;
            continue;
          }
        }
      }
    }

    // Assign immutable copy of the new board state and trigger rebuild.
    // 分配新的棋盘状态的不可变副本并触发重建。
    state = state.copyWith(tiles: tiles, undo: state);
    return true;
  }

  // Generates tiles at random place on the board
  // 在棋盘上随机生成一个初始的数字方块2
  Tile random(List<int> indexes) {
    var i = 0;
    var rng = Random();
    do {
      i = rng.nextInt(16);
    } while (indexes.contains(i));

    return Tile(const Uuid().v4(), 2, i);
  }

  //Merge tiles
  // 移动图块(数字方块)后，与相同数字重叠的图块将被合并
  void merge() {
    List<Tile> tiles = [];
    var tilesMoved = false;
    List<int> indexes = [];
    var score = state.score;

    // 循环遍历每个图块，如果下一个图块与当前图块具有相同的索引，则将两个图块的值相加，并将其添加为新图块的值
    for (int i = 0, l = state.tiles.length; i < l; i++) {
      // 从当前棋盘状态中获取对应索引的方块
      var tile = state.tiles[i];

      // 取得该方块的数字值，默认是不可合并
      var value = tile.value, merged = false;

      if (i + 1 < l) {
        //sum the number of the two tiles with same index and mark the tile as merged and skip the next iteration.
        /// 求两个具有相同索引(表示可以合并)的图块的数量之和，并将该图块标记为已合并的图块，跳过下一次迭代。

        // 取得下一个图块实例
        var next = state.tiles[i + 1];
        // 如果当前图块和下一个图片的nextIndex一样，则表示可以合并
        if (tile.nextIndex == next.nextIndex ||
            tile.index == next.nextIndex && tile.nextIndex == null) {
          // 把两个可以合并的图块的数字值想加
          value = tile.value + next.value;
          // 标记为已合并
          merged = true;
          // 更新分数为加上已合并方块的值
          score += tile.value;
          // 继续遍历下一个方块
          i += 1;
        }
      }

      // 如果已经合并了，或者当前图块的索引和下一个索引不一样(就是不可合并)，则修改图块是否移动的标识为true
      if (merged || tile.nextIndex != null && tile.index != tile.nextIndex) {
        tilesMoved = true;
      }

      // 图块列表添加这个合并后的图块
      tiles.add(
        tile.copyWith(
          index: tile.nextIndex ?? tile.index,
          nextIndex: null,
          value: value,
          merged: merged,
        ),
      );

      // 索引列表也添加最后一个图块的索引
      indexes.add(tiles.last.index);
    }

    //If tiles got moved then generate a new tile at random position of the available positions on the board.
    // 如果图块被移动，则会在随机位置生成一个新图块。
    if (tilesMoved) {
      tiles.add(random(indexes));
    }

    // 更新此时的棋盘状态
    state = state.copyWith(score: score, tiles: tiles);
  }

  //Finish round, win or loose the game.
  // 在合并图块后，需要结束回合并将合并的图块标记为 false
  void _endRound() {
    // 先设定游戏结束和游戏胜利的状态
    var gameOver = true, gameWon = false;
    List<Tile> tiles = [];

    //If there is no more empty place on the board
    // 如果棋盘上没有空白的位置了
    if (state.tiles.length == 16) {
      // 先把棋盘的图块排序
      state.tiles.sort(((a, b) => a.index.compareTo(b.index)));

      // 对于每个图块，我们检查该图块是否可以左/右/上/下合并，
      // 如果可以，则游戏不会失败，如果不能，则游戏将失败
      for (int i = 0, l = state.tiles.length; i < l; i++) {
        var tile = state.tiles[i];

        //If there is a tile with 2048 then the game is won.
        // 如果图块中有值为2048的，玩家赢得了游戏(注意，此时棋盘没有剩余空位，游戏也结束了)
        if (tile.value == 2048) {
          gameWon = true;
        }

        var x = (i - (((i + 1) / 4).ceil() * 4 - 4));

        // 如果图块可以与左边的图块合并，那么游戏就还没输。
        if (x > 0 && i - 1 >= 0) {
          //If tile can be merged with left tile then game is not lost.
          var left = state.tiles[i - 1];
          if (tile.value == left.value) {
            gameOver = false;
          }
        }

        // 如果图块可以与右边的图块合并，那么游戏就还没输。
        if (x < 3 && i + 1 < l) {
          //If tile can be merged with right tile then game is not lost.
          var right = state.tiles[i + 1];
          if (tile.value == right.value) {
            gameOver = false;
          }
        }

        // 如果图块可以与上边的图块合并，那么游戏就还没输。
        if (i - 4 >= 0) {
          //If tile can be merged with above tile then game is not lost.
          var top = state.tiles[i - 4];
          if (tile.value == top.value) {
            gameOver = false;
          }
        }

        // 如果图块可以与下边的图块合并，那么游戏就还没输。
        if (i + 4 < l) {
          //If tile can be merged with the bellow tile then game is not lost.
          var bottom = state.tiles[i + 4];
          if (tile.value == bottom.value) {
            gameOver = false;
          }
        }
        //Set the tile merged: false
        // 将每个图块是否合并的标志置为false
        tiles.add(tile.copyWith(merged: false));
      }
    } else {
      // 如果棋盘上的图块少于 16 个，则意味着仍有地方可以添加新图块，这自动意味着游戏不会失败
      //There is still a place on the board to add a tile so the game is not lost.

      gameOver = false;
      for (var tile in state.tiles) {
        //If there is a tile with 2048 then the game is won.
        // (注意，此时棋盘还有剩余空位，玩家虽然已经赢了但游戏没有结束)
        if (tile.value == 2048) {
          gameWon = true;
        }

        //Set the tile merged: false
        tiles.add(tile.copyWith(merged: false));
      }
    }

    // 2024-01-29 在每次移动结束后，都看看是不是已经有新的最大合成整数了
    var maxValue = state.tiles
        .map((tile) => tile.value)
        .reduce((value, element) => value > element ? value : element);

    state = state.copyWith(
      tiles: tiles,
      bestNum: max(maxValue, state.bestNum),
      won: gameWon,
      over: gameOver,
    );
  }

  // Mark the merged as false after the merge animation is complete.
  // 当合并动画完成后标记是否合并为false
  bool endRound() {
    //End round.
    // 在每一次移动后进行结束回合判断
    _endRound();
    // 并更新状态为回合已经结束，避免动画延迟问题，在上一个移动未完成前就开始新的动画
    ref.read(roundManager.notifier).end();

    //If player moved too fast before the current animation/transition finished, start the move for the next direction
    // 如果玩家在当前动画/过渡结束前移动过快，则开始下一个方向的移动
    var nextDirection = ref.read(nextDirectionManager);
    // 如果有任何方向排队，则自动开始下一轮。
    if (nextDirection != null) {
      move(nextDirection);
      ref.read(nextDirectionManager.notifier).clear();

      // 为了保持状态更及时，每个回合结束就直接保存
      // 也可以在调用endRound()的地方调用save，这里图省事
      save();

      return true;
    }

    save();
    return false;
  }

  //undo one round only
  void undo() {
    if (state.undo != null) {
      state = state.copyWith(
        score: state.undo!.score,
        best: state.undo!.best,
        bestNum: state.undo!.bestNum,
        tiles: state.undo!.tiles,
      );
    }
  }

  //Move the tiles using the arrow keys on the keyboard.
  // 如果是桌面应用，可以用键盘方向键控制图块移动
  bool onKey(RawKeyEvent event) {
    SwipeDirection? direction;
    if (event.isKeyPressed(LogicalKeyboardKey.arrowRight)) {
      direction = SwipeDirection.right;
    } else if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft)) {
      direction = SwipeDirection.left;
    } else if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
      direction = SwipeDirection.up;
    } else if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
      direction = SwipeDirection.down;
    }

    if (direction != null) {
      move(direction);
      return true;
    }
    return false;
  }

  // 保存当前棋盘状态到缓存
  void save() async {
    try {
      await _simpleStorage.set2048BoardState(state);
    } catch (e) {
      print("保存棋盘状态出错:$e");
    }
  }
}

final boardManager = StateNotifierProvider<BoardManager, Board>((ref) {
  return BoardManager(ref);
});
