import '../models/tile.dart';

class Board {
  // 当前棋盘上的分数
  final int score;
  // 历史最佳分数
  final int best;
  // 2024-01-29 因为分数的计算(上面两个值)并不能直观看到已经合成的最大整数，新加一个来保存合成的最大数值
  // 历史最佳合成整数(当前最大棋盘一眼就看到，就不保存了)
  final int bestNum;
  // 棋盘上显示的当前数字方块列表
  final List<Tile> tiles;
  // 游戏是否结束了
  // ??? todo，应该还有达成2048后继续的功能、4096、8192……，直到失败
  final bool over;
  // 游戏是否赢了
  final bool won;
  // 保留用于撤消功能的上一轮棋盘状态
  final Board? undo;

  Board(
    this.score,
    this.best,
    this.bestNum,
    this.tiles, {
    this.over = false,
    this.won = false,
    this.undo,
  });

  // 新游戏时创建一个初始化的 board 模型
  Board.newGame(this.best, this.bestNum, this.tiles)
      : score = 0,
        over = false,
        won = false,
        undo = null;

  // 创建一个不可变的 board 副本
  Board copyWith({
    int? score,
    int? best,
    int? bestNum,
    List<Tile>? tiles,
    bool? over,
    bool? won,
    Board? undo,
  }) =>
      Board(
        score ?? this.score,
        best ?? this.best,
        bestNum ?? this.bestNum,
        tiles ?? this.tiles,
        over: over ?? this.over,
        won: won ?? this.won,
        undo: undo ?? this.undo,
      );

  // Create a Board from json data
  // 根据 json 数据创建棋盘(应该是用于恢复之前保存的数据)
  factory Board.fromJson(Map<String, dynamic> json) => Board(
        json['score'] as int,
        json['best'] as int,
        json['bestNum'] as int,
        (json['tiles'] as List<dynamic>)
            .map((e) => Tile.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        over: json['over'] as bool? ?? false,
        won: json['won'] as bool? ?? false,
        undo: json['undo'] == null
            ? null
            : Board.fromJson(Map<String, dynamic>.from(json['undo'] as Map)),
      );

  // Generate json data from the Board
  // 从棋盘方块生成 json 数据(应该是用于保存当前棋盘的数据)
  Map<String, dynamic> toJson() => <String, dynamic>{
        'score': score,
        'best': best,
        'bestNum': bestNum,
        'tiles': tiles.map((e) => e.toJson()).toList(),
        'over': over,
        'won': won,
        'undo': undo?.toJson(),
      };
}
