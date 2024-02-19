import 'package:flutter/material.dart';

import 'utils/exports.dart';
import 'view/splash_view/splash_view.dart';

class InitMinesweeper extends StatefulWidget {
  const InitMinesweeper({super.key});

  @override
  State<InitMinesweeper> createState() => _InitMinesweeperState();
}

class _InitMinesweeperState extends State<InitMinesweeper> {
  @override
  Widget build(BuildContext context) {
    GameSizes.init(context);

    return const SplashView();
  }
}
