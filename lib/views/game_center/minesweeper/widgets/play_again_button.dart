import 'package:flutter/material.dart';

import '../controller/game_controller.dart';
import '../helper/audio_player.dart';
import '../utils/exports.dart';
import 'custom_button.dart';

class PlayAgainButton extends StatelessWidget {
  final GameController controller;
  final bool win;
  const PlayAgainButton(
      {super.key, required this.controller, required this.win});

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: win ? "再来一局" : "再试一次",
      onPressed: () {
        Navigator.pop(context);
        controller.createNewGame();
        GameAudioPlayer().resetPlayer(controller.volumeOn);
      },
      icon: Icons.refresh,
      textColor: Colors.white,
      iconSize: GameSizes.getWidth(0.08),
      color: GameColors.popupPlayAgainButton,
      padding: GameSizes.getSymmetricPadding(0.05, 0.015),
      borderColor: Colors.white,
    );
  }
}
