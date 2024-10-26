import 'package:flutter/material.dart';

import '../../helper/shared_helper.dart';
import '../../utils/game_sizes.dart';
import '../home_view/home_view.dart';
import '../how_to_play_view/how_to_play_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  Future<void> _init() async {
    await SharedHelper.init().then((sharedHelper) async {
      await sharedHelper.getHowToPlayShown().then((hasShown) {
        if (hasShown) {
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext ctx) => const MinesweeperHomeView(),
            ),
          );
        } else {
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const HowToPlayView(redirectToHome: true),
            ),
          );
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/games/minesweeper/images/logo.png',
          width: GameSizes.getWidth(0.5),
        ),
      ),
    );
  }
}
