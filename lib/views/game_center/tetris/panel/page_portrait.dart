import 'package:flutter/material.dart';

import '../const/constant.dart';
import 'controller.dart';
import 'screen.dart';

part 'page_land.dart';

class PagePortrait extends StatelessWidget {
  const PagePortrait({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenW = size.width * 0.8;

    return SizedBox.expand(
      child: Container(
        color: BACKGROUND_COLOR,
        child: Padding(
          padding: MediaQuery.of(context).padding,
          child: Column(
            children: <Widget>[
              const Spacer(),
              ScreenDecoration(child: Screen(width: screenW)),
              const Spacer(flex: 2),
              const GameController(),
            ],
          ),
        ),
      ),
    );
  }
}

class ScreenDecoration extends StatelessWidget {
  final Widget child;

  const ScreenDecoration({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF987f0f), width: SCREEN_BORDER_WIDTH),
          left:
              BorderSide(color: Color(0xFF987f0f), width: SCREEN_BORDER_WIDTH),
          right:
              BorderSide(color: Color(0xFFfae36c), width: SCREEN_BORDER_WIDTH),
          bottom:
              BorderSide(color: Color(0xFFfae36c), width: SCREEN_BORDER_WIDTH),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.black54)),
        child: Container(
          padding: const EdgeInsets.all(3),
          color: SCREEN_BACKGROUND,
          child: child,
        ),
      ),
    );
  }
}
