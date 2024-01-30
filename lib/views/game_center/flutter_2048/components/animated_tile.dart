import 'package:flutter/material.dart';

import '../models/tile.dart';

///
/// 添加 AnimatedTile 小部件，它将渲染动画图块本身
///
class AnimatedTile extends AnimatedWidget {
// AnimatedTile 扩展了 AnimatedWidget，它将监听传递给可监听参数的 2 个动画，并在需要时触发重建，这也是使用动画时最推荐的方法
// 使用 Listenable.merge，以便在两个控制都发生变化时都更新动画部件
  AnimatedTile({
    super.key,
    required this.moveAnimation,
    required this.scaleAnimation,
    required this.tile,
    required this.child,
    required this.size,
  }) : super(listenable: Listenable.merge([moveAnimation, scaleAnimation]));

  /// 一些自定义参数：
  // 保存图块的索引、编号等
  final Tile tile;
  // 传入的图块部件(如果是可合并的就有合并动画，不能合并的就是原部件)
  final Widget child;
  // 创建的图块移动动画
  final CurvedAnimation moveAnimation;
  // 创建的曲线缩放动画
  final CurvedAnimation scaleAnimation;
  // 计算左侧/顶部位置时所依据的图块大小
  final double size;
  // 图块的当前顶部/左侧位置。
  //Get the current top position based on current index of the tile
  late final double _top = tile.getTop(size);
  //Get the current left position based on current index of the tile
  late final double _left = tile.getLeft(size);
  // 图块将移动到的位置（如果有）
  //Get the next top position based on current next index of the tile
  late final double _nextTop = tile.getNextTop(size) ?? _top;
  //Get the next top position based on next index of the tile
  late final double _nextLeft = tile.getNextLeft(size) ?? _left;

/*
 * 为了使用AnimationController（在本例中为CurvedAnimation）对运动进行动画处理，需要告诉它动画需要如何运行，
 * 在本例中需要告诉它动画应该如何从A点运行到B点，可以实现使用补间动画(Tweens)。
 * 因此，补间用于在一定范围内插入值，在本例中，这将使用每个图块的相应方法插入从上/左到下一个顶部/下一个左的移动，
 * 这就是为什么有类型为 Animation<double> 的表示图块的开始位置的top/left变量，和表示图块的结束位置的 nextTop/nextLeft 变量。 
 */
  //top tween used to move the tile from top to bottom
  late final Animation<double> top = Tween<double>(
        begin: _top,
        end: _nextTop,
      ).animate(
        moveAnimation,
      ),
      //left tween used to move the tile from left to right
      left = Tween<double>(
        begin: _left,
        end: _nextLeft,
      ).animate(
        moveAnimation,
      ),
      //scale tween used to use give "pop" effect when a merge happens

      // 对于缩放动画，还将使用 Tween，更具体地说是 TweenSequence，它允许我们传递多个要按顺序执行的补间，
      // 在这种情况下，为了实现弹出效果，希望图块从 1.0 放大到 1.5，然后缩放从 1.5 降回 1.0，
      // 并且所有这些都应该在序列补间期间以 50/50 执行（这就是为什么将每个补间的权重设置为 50%）。
      scale = TweenSequence<double>(
        <TweenSequenceItem<double>>[
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1.0, end: 1.5).chain(
              CurveTween(curve: Curves.easeOut),
            ),
            weight: 50.0,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1.5, end: 1.0).chain(
              CurveTween(curve: Curves.easeIn),
            ),
            weight: 50.0,
          ),
        ],
      ).animate(scaleAnimation);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top.value,
      left: left.value,
      //Only use scale animation if the tile was merged
      // 只有当前图块已经合并时才应该使用缩放动画
      child: tile.merged ? ScaleTransition(scale: scale, child: child) : child,
    );
  }
}
