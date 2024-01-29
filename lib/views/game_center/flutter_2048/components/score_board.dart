import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../const/colors.dart';
import '../managers/board.dart';

///
/// 计分板组件显示当前分数和历史最佳分数
///
class ScoreBoard extends ConsumerWidget {
  const ScoreBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 从棋盘的状态管理中获取当前分数和历史最佳分数
    final score = ref.watch(boardManager.select((board) => board.score));
    final best = ref.watch(boardManager.select((board) => board.best));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Score(label: '当前分数', score: '$score'),
        SizedBox(width: 8.sp),
        Score(label: '历史最佳', score: '$best'),
      ],
    );
  }
}

// 历史合成最大整数
class MaxValueBoard extends ConsumerWidget {
  const MaxValueBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 从棋盘的状态管理中获取当前分数和历史最佳分数
    final bestNum = ref.watch(boardManager.select((board) => board.bestNum));

    return Score(label: '历史最大', score: '$bestNum');
  }
}

class Score extends StatelessWidget {
  const Score({
    super.key,
    required this.label,
    required this.score,
    this.padding,
  });

  final String label;
  final String score;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: 16.sp,
            vertical: 8.sp,
          ),
      decoration: BoxDecoration(
        color: scoreColor,
        borderRadius: BorderRadius.circular(8.sp),
      ),
      child: Column(
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: color2)),
          Text(
            score,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
            ),
          )
        ],
      ),
    );
  }
}
