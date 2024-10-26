import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'gamer/gamer.dart';
import 'gamer/keyboard.dart';
import 'material/audios.dart';
import 'panel/page_portrait.dart';

class InitTetris extends StatefulWidget {
  const InitTetris({super.key});

  @override
  State<InitTetris> createState() => _InitTetrisState();
}

class _InitTetrisState extends State<InitTetris> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Sound(child: Game(child: KeyboardController(child: _HomePage()))),
    );
  }
}

class _HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //only Android/iOS support land mode
    bool land = MediaQuery.of(context).orientation == Orientation.landscape;
    return PopScope(
      canPop: false,
      // 退出游戏界面前，先重置设备方向为竖向
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;

        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);

        Navigator.pop(context);
      },
      child: land ? const PageLand() : const PagePortrait(),
    );
  }
}
