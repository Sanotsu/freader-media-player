import 'package:flutter/widgets.dart';

import '../const/constants.dart';
import '../models/game_object.dart';
import '../models/sprite.dart';

///
/// 地面
///
Sprite groundSprite = Sprite()
  ..imagePath = "assets/games/dinosaur/ground.png"
  ..imageWidth = 2399
  ..imageHeight = 24;

class Ground extends GameObject {
  final Offset worldLocation;

  Ground({required this.worldLocation});

  @override
  Rect getRect(Size screenSize, double runDistance) {
    return Rect.fromLTWH(
      (worldLocation.dx - runDistance) * worlToPixelRatio,
      screenSize.height / 1.75 - groundSprite.imageHeight,
      groundSprite.imageWidth.toDouble(),
      groundSprite.imageHeight.toDouble(),
    );
  }

  @override
  Widget render() {
    return Image.asset(groundSprite.imagePath);
  }
}
