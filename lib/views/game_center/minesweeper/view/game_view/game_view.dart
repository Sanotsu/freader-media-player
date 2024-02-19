import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controller/game_controller.dart';
import '../../helper/audio_player.dart';
import '../../widgets/skip_button.dart';
import 'mine_field.dart';
import 'top_bar.dart';

class GameView extends StatefulWidget {
  const GameView({super.key});

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      GameAudioPlayer.resume();
    } else {
      GameAudioPlayer.pause();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GameController>(
      create: (_) => GameController(),
      child: Consumer<GameController>(builder: (context, gameController, _) {
        return PopScope(
          canPop: !gameController.gameHasStarted,
          onPopInvoked: (popped) {
            gameController.exitGame(context);
          },
          child: SafeArea(
            child: Scaffold(
              backgroundColor: Colors.black,
              body: Column(
                children: [
                  const GameTopBar(),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        MineField(gameController: gameController),
                        SkipButton(gameController: gameController),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
