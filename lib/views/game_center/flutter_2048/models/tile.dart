import 'package:flutter_screenutil/flutter_screenutil.dart';

class Tile {
  // 用作方块部件 TileWidget 的 ValueKey 的唯一id
  final String id;
  // 方块上的数值
  final int value;
  // 棋盘上数字方块的索引，通过该索引计算数字方块的位置
  final int index;
  // 棋盘上下一个数字方块的索引
  final int? nextIndex;
  // 数字方块是否与其他方块合并
  final bool merged;

  Tile(this.id, this.value, this.index, {this.nextIndex, this.merged = false});

  /// 根据图块的索引计算顶部和左侧位置
  ///
  // Calculate the current top position based on the current index
  // 根据当前索引计算当前的最高位置
  double getTop(double size) {
    var i = ((index + 1) / 4).ceil();
    return ((i - 1) * size) + (12.sp * i);
  }

  // Calculate the current left position based on the current index
  // 根据当前索引计算当前左侧位置
  double getLeft(double size) {
    var i = (index - (((index + 1) / 4).ceil() * 4 - 4));
    return (i * size) + (12.sp * (i + 1));
  }

  /// 这两个方法将用于根据 nextIndex 获取图块的下一个位置，
  /// 因此当将图块从 A 点移动到 B 点时，这两个函数将用于决定 B 点。
  ///
  // Calculate the next top position based on the next index
  // 根据下一个索引计算下一个最高位置
  double? getNextTop(double size) {
    if (nextIndex == null) return null;
    var i = ((nextIndex! + 1) / 4).ceil();
    return ((i - 1) * size) + (12.sp * i);
  }

  // Calculate the next left position based on the next index
  // 根据下一个索引计算下一个左侧位置
  double? getNextLeft(double size) {
    if (nextIndex == null) return null;
    var i = (nextIndex! - (((nextIndex! + 1) / 4).ceil() * 4 - 4));
    return (i * size) + (12.sp * (i + 1));
  }

  // Create an immutable copy of the tile
  // 创建数字方块的不可变副本
  Tile copyWith({
    String? id,
    int? value,
    int? index,
    int? nextIndex,
    bool? merged,
  }) =>
      Tile(
        id ?? this.id,
        value ?? this.value,
        index ?? this.index,
        nextIndex: nextIndex ?? this.nextIndex,
        merged: merged ?? this.merged,
      );

  // Create a Tile from json data
  // 根据 json 数据创建数字方块(应该是用于恢复之前保存的数据)
  factory Tile.fromJson(Map<String, dynamic> json) => Tile(
        json['id'] as String,
        json['value'] as int,
        json['index'] as int,
        nextIndex: json['nextIndex'] as int?,
        merged: json['merged'] as bool? ?? false,
      );

  // Generate json data from the Tile
  // 从数字方块生成 json 数据(应该是用于保存当前棋盘的数据)
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'value': value,
        'index': index,
        'nextIndex': nextIndex,
        'merged': merged,
      };
}
