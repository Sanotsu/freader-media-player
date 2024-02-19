import 'package:flutter/material.dart';

import '../controller/game_controller.dart';
import '../utils/exports.dart';
import 'custom_button.dart';

class SkipButton extends StatelessWidget {
  final GameController gameController;
  const SkipButton({super.key, required this.gameController});

  @override
  Widget build(BuildContext context) {
    if (!gameController.isMineAnimationOn) return const SizedBox();

    return Positioned(
      bottom: GameSizes.getHeight(0.1),
      child: CustomButton(
        onPressed: () {
          gameController.minesAnimation = false;
        },
        text: "跳过",
        icon: Icons.fast_forward_sharp,
        width: GameSizes.getWidth(0.4),
        iconSize: GameSizes.getWidth(0.08),
      ),
    );
  }
}
