import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../utils/game_colors.dart';
import '../../../utils/game_sizes.dart';

/// 
/// 微型雷区
/// 
class MiniatureMinefield extends StatefulWidget {
  const MiniatureMinefield({super.key});

  @override
  State<MiniatureMinefield> createState() => _MiniatureMinefieldState();
}

class _MiniatureMinefieldState extends State<MiniatureMinefield> {
  Timer? timer;

  void startTimer() {
    timer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted) {
        setState(() {});
      } else {
        timer.cancel();
      }
    });
  }

  void stopTimer() {
    timer?.cancel();
  }

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    super.dispose();
    stopTimer();
  }

  @override
  Widget build(BuildContext context) {
    var rnd = Random();
    List<int> minePlaces = [
      rnd.nextInt(20),
      rnd.nextInt(20),
      rnd.nextInt(20),
    ];

    return SizedBox(
      height: GameSizes.getWidth(0.6),
      child: Center(
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10),
          itemCount: 40,
          itemBuilder: (BuildContext context, index) {
            Color? mineColor;
            bool mineCell = minePlaces.contains(index - 19);
            if (mineCell) {
              var rnd = Random();

              mineColor = GameColors
                  .mineColors[rnd.nextInt(GameColors.mineColors.length)];
            }
            return Container(
              decoration: BoxDecoration(
                color: mineCell
                    ? mineColor
                    : (index / 10).floor() < 2
                        ? index % 2 == (index / 10).floor() % 2
                            ? GameColors.grassLight
                            : GameColors.grassDark
                        : index % 2 != (index / 10).floor() % 2
                            ? GameColors.tileDark
                            : GameColors.tileLight,
              ),
              alignment: Alignment.center,
              padding: GameSizes.getPadding(0.02),
              child: mineCell
                  ? CircleAvatar(
                      backgroundColor: GameColors.darken(mineColor!),
                    )
                  : const SizedBox(),
            );
          },
        ),
      ),
    );
  }
}
