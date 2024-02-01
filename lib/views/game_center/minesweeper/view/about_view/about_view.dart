import 'package:flutter/material.dart';

import '../../utils/game_colors.dart';
import '../../utils/game_sizes.dart';

class AboutView extends StatefulWidget {
  const AboutView({super.key});

  @override
  State<AboutView> createState() => _AboutViewState();
}

class _AboutViewState extends State<AboutView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.background,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text('关于'),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: GameSizes.getWidth(0.05),
        ),
      ),
      body: SingleChildScrollView(
        padding: GameSizes.getSymmetricPadding(0.05, 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: GameSizes.getSymmetricPadding(0.05, 0.02),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/games/minesweeper/images/logo.png',
                    width: GameSizes.getWidth(0.25),
                  ),
                  SizedBox(width: GameSizes.getWidth(0.05)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'minesweeper',
                        style: TextStyle(
                          fontSize: GameSizes.getWidth(0.06),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: GameSizes.getHeight(0.005)),
                      Text(
                        'version 1.0.3',
                        style: TextStyle(
                          fontSize: GameSizes.getWidth(0.04),
                        ),
                      ),
                      SizedBox(height: GameSizes.getHeight(0.005)),
                      Text(
                        '原开发者信息:',
                        style: TextStyle(
                          fontSize: GameSizes.getWidth(0.04),
                        ),
                      ),
                      SizedBox(height: GameSizes.getHeight(0.005)),
                      Text(
                        '  Recep Oğuzhan Şenoğlu',
                        style: TextStyle(
                          fontSize: GameSizes.getWidth(0.04),
                        ),
                      ),
                      Text(
                        '  İstanbul, Türkiye',
                        style: TextStyle(
                          fontSize: GameSizes.getWidth(0.035),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: GameSizes.getHeight(0.02)),
          ],
        ),
      ),
    );
  }
}
