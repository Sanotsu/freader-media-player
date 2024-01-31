import 'package:flutter/widgets.dart';

import '../const/constants.dart';
import '../models/game_object.dart';
import '../models/sprite.dart';

///
/// 云朵
///
Sprite cloudSprite = Sprite()
  ..imagePath = "assets/games/dinosaur/cloud.png"
  ..imageWidth = 92
  ..imageHeight = 27;

class Cloud extends GameObject {
  final Offset worldLocation;

  Cloud({required this.worldLocation});

  @override
  Rect getRect(Size screenSize, double runDistance) {
    return Rect.fromLTWH(
      (worldLocation.dx - runDistance) * worlToPixelRatio / 5,
      screenSize.height / 3 - cloudSprite.imageHeight - worldLocation.dy,
      cloudSprite.imageWidth.toDouble(),
      cloudSprite.imageHeight.toDouble(),
    );
  }

  @override
  Widget render() {
    return Image.asset(cloudSprite.imagePath);
  }
}
