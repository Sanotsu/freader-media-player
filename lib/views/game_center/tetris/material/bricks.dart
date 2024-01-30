// ignore_for_file: constant_identifier_names, use_key_in_widget_constructors

import 'package:flutter/material.dart';

/// 俄罗斯方块中的砖块(Brick,一个一个小方块)定义
const _COLOR_NORMAL = Colors.black87;

const _COLOR_NULL = Colors.black12;

// 方块下落后接触到下面的方块时，会闪一下，然后就是这个高亮颜色
const _COLOR_HIGHLIGHT = Color(0xFF560000);

class BrickSize extends InheritedWidget {
  const BrickSize({
    super.key,
    required this.size,
    required super.child,
  });

  final Size size;

  static BrickSize of(BuildContext context) {
    final brickSize = context.dependOnInheritedWidgetOfExactType<BrickSize>();
    assert(brickSize != null, "....");
    return brickSize!;
  }

  @override
  bool updateShouldNotify(BrickSize oldWidget) {
    return oldWidget.size != size;
  }
}

///the basic brick for game panel
class Brick extends StatelessWidget {
  final Color color;

  const Brick._({super.key, required this.color});

  const Brick.normal() : this._(color: _COLOR_NORMAL);

  const Brick.empty() : this._(color: _COLOR_NULL);

  const Brick.highlight() : this._(color: _COLOR_HIGHLIGHT);

  @override
  Widget build(BuildContext context) {
    final width = BrickSize.of(context).size.width;
    return SizedBox.fromSize(
      size: BrickSize.of(context).size,
      child: Container(
        margin: EdgeInsets.all(0.05 * width),
        padding: EdgeInsets.all(0.1 * width),
        decoration: BoxDecoration(
          border: Border.all(width: 0.10 * width, color: color),
        ),
        child: Container(
          color: color,
        ),
      ),
    );
  }
}
