import 'dart:async';

import 'package:flutter/material.dart';

import '../../../utils/game_images.dart';
import '../../../utils/game_sizes.dart';
import '../../../widgets/custom_button.dart';
import '../../game_view/game_view.dart';

class AnimatedPlayButton extends StatefulWidget {
  const AnimatedPlayButton({super.key});

  @override
  State<AnimatedPlayButton> createState() => _AnimatedPlayButtonState();
}

class _AnimatedPlayButtonState extends State<AnimatedPlayButton> {
  double _top = 0;
  double _left = 0;
  double _axeSize = GameSizes.getWidth(0.38);

  Timer? _timer;

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (mounted) {
        setState(() {
          _axeSize = _axeSize > GameSizes.getWidth(0.2)
              ? GameSizes.getWidth(0.2)
              : GameSizes.getWidth(0.25);
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _killTimer() {
    _timer?.cancel();
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    super.dispose();
    _killTimer();
  }

  void _onTapDown() {
    setState(() {
      _top = GameSizes.getWidth(0.03);
      _left = GameSizes.getWidth(0.02);
    });
  }

  void _onTapUp() {
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _top = 0;
        _left = 0;
      });
    });
  }

  void _onTapDownWithDetails(TapDownDetails details) {
    _onTapDown();
  }

  void _onTapUpWithDetails(TapUpDetails details) {
    _onTapUp();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: GameSizes.getWidth(0.38),
          height: GameSizes.getWidth(0.32),
          margin: EdgeInsets.only(
            top: GameSizes.getWidth(0.03),
            left: GameSizes.getWidth(0.02),
          ),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: GameSizes.getRadius(22),
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 100),
          top: _top,
          left: _left,
          curve: Curves.easeIn,
          child: GestureDetector(
            onTap: _onTapDown,
            onTapUp: _onTapUpWithDetails,
            onTapDown: _onTapDownWithDetails,
            onTapCancel: _onTapUp,
            child: CustomButton(
              text: '',
              onPressed: () {
                Future.delayed(const Duration(milliseconds: 200), () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GameView(),
                      ));
                });
              },
              radius: 16,
              elevation: 20,
              width: GameSizes.getWidth(0.38),
              height: GameSizes.getWidth(0.32),
              padding: GameSizes.getPadding(0.025),
              color: Colors.grey.shade200,
              textColor: Colors.white,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  decoration: BoxDecoration(
                    // color: Colors.grey.shade200,
                    borderRadius: GameSizes.getRadius(16),
                  ),
                  width: _axeSize,
                  height: _axeSize,
                  child: Image.asset(
                    Images.pickaxe.toPath,
                    width: _axeSize,
                    height: _axeSize,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
