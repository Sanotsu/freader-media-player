import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'gamer.dart';

///keyboard controller to play game
class KeyboardController extends StatefulWidget {
  final Widget child;

  const KeyboardController({super.key, required this.child});

  @override
  State<KeyboardController> createState() => _KeyboardControllerState();
}

class _KeyboardControllerState extends State<KeyboardController> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  bool _onKey(KeyEvent event) {
    if (event is KeyUpEvent) {
      // Return false to indicate the event was not handled
      return false;
    }

    final key = event.logicalKey;
    final game = Game.of(context);

    if (key == LogicalKeyboardKey.arrowUp) {
      game.rotate();
    } else if (key == LogicalKeyboardKey.arrowDown) {
      game.down();
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      game.left();
    } else if (key == LogicalKeyboardKey.arrowRight) {
      game.right();
    } else if (key == LogicalKeyboardKey.space) {
      game.drop();
    } else if (key == LogicalKeyboardKey.keyP) {
      game.pauseOrResume();
    } else if (key == LogicalKeyboardKey.keyS) {
      game.soundSwitch();
    } else if (key == LogicalKeyboardKey.keyR) {
      game.reset();
    } else {
      // Return false to indicate the event was not handled
      return false;
    }

    // Return true to indicate the event was handled
    return true;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
