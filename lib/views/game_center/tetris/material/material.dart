import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 游戏界面的材质
class GameMaterial extends StatefulWidget {
  final Widget child;

  const GameMaterial({super.key, required this.child});

  @override
  State<GameMaterial> createState() => _GameMaterialState();

  static ui.Image getMaterial(BuildContext context) {
    final state = context.findAncestorStateOfType<_GameMaterialState>();
    assert(state != null, "can not find GameMaterial widget");
    return state!.material!;
  }
}

class _GameMaterialState extends State<GameMaterial> {
  ///the image data of /assets/games/tetris/material.png
  ui.Image? material;

  @override
  void initState() {
    super.initState();
    _doLoadMaterial();
  }

  void _doLoadMaterial() async {
    if (material != null) {
      return;
    }
    final bytes = await rootBundle.load("assets/games/tetris/material.png");
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    setState(() {
      material = frame.image;
    });
  }

  @override
  Widget build(BuildContext context) {
    return material == null ? Container() : widget.child;
  }
}
