import 'package:flutter/widgets.dart';

///
/// 游戏对象抽象类
///
/// 每个部件都可能有的，需要跟着恐龙跑的过程中渲染图片和更新贴图。
/// 渲染实例、需要获取贴图元素所在方块的位置(用于计算是否碰撞判断游戏结束与否)、根据上次更新时间和运行时间更新贴图
///
abstract class GameObject {
  Widget render();
  Rect getRect(Size screenSize, double runDistance);
  void update(Duration lastUpdate, Duration elapsedTime) {}
}
