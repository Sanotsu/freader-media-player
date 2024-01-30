import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../const/colors.dart';
import '../managers/board.dart';

import 'animated_tile.dart';
import 'button.dart';

///
/// 这是带有数字方块的棋盘
/// 和之前作为背景的空白板类似，区别是这个棋盘将实际的数字方块渲染在空棋盘的上层。
///
class TileBoardWidget extends ConsumerWidget {
  const TileBoardWidget({
    super.key,
    required this.moveAnimation,
    required this.scaleAnimation,
  });

  final CurvedAnimation moveAnimation;
  final CurvedAnimation scaleAnimation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 需要侦听游戏主体状态，根据状态显示内容
    final board = ref.watch(boardManager);

    // 棋盘的大小、数字方块的大小和背景空白板是一样的，不然就奇怪了，位置还可能对不上
    final size = max(
      290.sp,
      min(
        (MediaQuery.of(context).size.shortestSide * 0.90).floorToDouble(),
        460.sp,
      ),
    );

    final sizePerTile = (size / 4).floorToDouble();
    final tileSize = sizePerTile - 12.sp - (12.sp / 4);
    final boardSize = sizePerTile * 4;
    return SizedBox(
      width: boardSize,
      height: boardSize,
      child: Stack(
        children: [
          ...List.generate(board.tiles.length, (i) {
            var tile = board.tiles[i];

            /// 这里使用在图块合并时可以产生合并动画，具体实现看AnimatedTile细节
            ///
            // 每个 AnimatedTile 代表一个游戏数字的动画方块。每个方块使用传入的动画参数进行移动和缩放。
            // 方块的尺寸由传入的尺寸计算得出，并使用Container进行包装，设置背景颜色和圆角，并在其中居中显示方块的值。
            return AnimatedTile(
              key: ValueKey(tile.id),
              tile: tile,
              moveAnimation: moveAnimation,
              scaleAnimation: scaleAnimation,
              size: tileSize,
              // 为了优化性能并防止不必要的重新渲染，实际数字方块将作为子方块传递给动画方块，
              // 因为数字方块在移动过程中不会发生变化（除了位置）。除了图块的位置和数量之外，样式将保持不变。
              child: Container(
                width: tileSize,
                height: tileSize,
                decoration: BoxDecoration(
                  // 预设颜色到2048,超过的就不变了
                  color: tileColors[tile.value] ?? tileColors[2048],
                  // 这是棋盘上数字方块的圆角
                  borderRadius: BorderRadius.circular(6.sp),
                ),
                child: Center(
                  child: Text(
                    '${tile.value}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24.sp,
                      color: tile.value < 8 ? textColor : textColorWhite,
                    ),
                  ),
                ),
              ),
            );
          }),
          // 如果游戏结束，会在Stack中添加一个覆盖整个屏幕的Container，显示游戏结束的提示信息和一个按钮。
          // 点击按钮后，会调用 boardManager 的 newGame 方法重新开始游戏。

          // 2024-01-29 原本以为是达到了2048之后，游戏胜利了就结束了，想着增加一个继续挑战最大值的功能按钮
          // 但实际查看逻辑，发现won 不等于 over。判断逻辑是棋盘没有空白位置添加数值为2的卡片(棋盘被铺满)游戏就结束了：
          //    此时再判断，如果合成的数值中有2048,那么玩家获胜；没有2048,玩家失败。
          // 所以不必要什么继续挑战
          if (board.over)
            // fill将会让这条消息覆盖整个棋盘
            Positioned.fill(
              child: Container(
                color: overlayColor,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      board.won ? '您赢了!' : '游戏结束!',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 64.sp,
                      ),
                    ),
                    ButtonWidget(
                      text: board.won ? '新游戏' : '再来一次',
                      onPressed: () {
                        ref.read(boardManager.notifier).newGame();
                      },
                    ),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
}
