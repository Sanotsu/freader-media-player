import 'package:flutter/material.dart';

import '../const/constant.dart';
import '../gamer/gamer.dart';
import '../material/bricks.dart';
import '../material/images.dart';

Size getBrickSizeForScreenWidth(double width) {
  return Size.square((width - PLAYER_PANEL_PADDING) / GAME_PAD_MATRIX_W);
}

///the matrix of player content
class PlayerPanel extends StatelessWidget {
  //the size of player panel
  final Size size;

  PlayerPanel({
    super.key,
    required double width,
  })  : assert(width != 0),
        size = Size(width, width * 2);

  @override
  Widget build(BuildContext context) {
    debugPrint("size : $size");
    return SizedBox.fromSize(
      size: size,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
        ),
        child: Stack(
          children: <Widget>[
            _PlayerPad(),
            _GameUninitialized(),
          ],
        ),
      ),
    );
  }
}

class _PlayerPad extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: GameState.of(context).data.map((list) {
        return Row(
          children: list.map((b) {
            return b == 1
                ? const Brick.normal()
                : b == 2
                    ? const Brick.highlight()
                    : const Brick.empty();
          }).toList(),
        );
      }).toList(),
    );
  }
}

class _GameUninitialized extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (GameState.of(context).states == GameStates.none) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconDragon(animate: true),
            SizedBox(height: 16),
            Text(
              "俄罗斯方块",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    } else {
      return Container();
    }
  }
}
