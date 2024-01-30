import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../const/colors.dart';

///
/// 空板小部件，即 4x4 的图块板(方块)，Tile 方块将在其上移动
///
class EmptyBoardWidget extends StatelessWidget {
  const EmptyBoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // 决定板子的最大尺寸，是基于屏幕的最短尺寸。
    final size = max(
      290.sp,
      min(
        (MediaQuery.of(context).size.shortestSide * 0.90).floorToDouble(),
        460.sp,
      ),
    );

    // 根据板子的大小减去每块方块之间的空隙(12.sp)来决定方块的大小。
    final sizePerTile = (size / 4).floorToDouble();
    final tileSize = sizePerTile - 12.sp - (12.sp / 4);
    final boardSize = sizePerTile * 4;
    return Container(
      width: boardSize,
      height: boardSize,
      decoration: BoxDecoration(
        color: boardColor,
        borderRadius: BorderRadius.circular(6.sp),
      ),
      child: Stack(
        children: List.generate(16, (i) {
          //使用 GridView 渲染一个4 x 4 的空板子
          var x = ((i + 1) / 4).ceil();
          var y = x - 1;

          var top = y * (tileSize) + (x * 12.sp);
          var z = (i - (4 * y));
          var left = z * (tileSize) + ((z + 1) * 12.sp);

          return Positioned(
            top: top,
            left: left,
            child: Container(
              width: tileSize,
              height: tileSize,
              decoration: BoxDecoration(
                color: emptyTileColor,
                borderRadius: BorderRadius.circular(6.sp),
              ),
            ),
          );
        }),
      ),
    );
  }
}
