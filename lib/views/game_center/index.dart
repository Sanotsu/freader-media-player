// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../common/global/constants.dart';
import 'flutter_2048/index.dart';
import 'minesweeper/index.dart';

import 'snake/index.dart';
import 't-rex_dinosaur/index.dart';
import 'tetris/index.dart';

class GameCenter extends StatefulWidget {
  const GameCenter({super.key});

  @override
  State<GameCenter> createState() => _GameCenterState();
}

class _GameCenterState extends State<GameCenter> {
  @override
  void initState() {
    // 进入运动模块就获取存储授权(应该是启动app就需要这个请求)
    // _requestPermission();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // 2024-01-30 暂时设定进入游戏中心强制是竖屏(主要是偷懒横屏游戏的一些适配)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    return Scaffold(
      // 避免搜索时弹出键盘，让底部的minibar位置移动到tab顶部导致溢出的问题
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("休闲游戏"),
      ),
      body: buildFixedBody(),
    );
  }

  // 可视页面固定等分居中、不可滚动的首页
  buildFixedBody() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Expanded(flex: 1, child: Container()),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(
                  child: buildCoverCardColumn(
                    context,
                    const InitGame2048(),
                    "2048",
                    imageUrl: cover2048ImageUrl,
                  ),
                ),
                Expanded(
                  child: buildCoverCardColumn(
                    context,
                    const InitTetris(),
                    "俄罗斯方块",
                    imageUrl: coverTetrisImageUrl,
                  ),
                )
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(
                  child: buildCoverCardColumn(
                    context,
                    const TRexDinosaur(),
                    "恐龙快跑",
                    imageUrl: coverDinosaurImageUrl,
                  ),
                ),
                Expanded(
                  child: buildCoverCardColumn(
                    context,
                    const SnakeGame(),
                    "贪吃蛇",
                    imageUrl: coverSnakeImageUrl,
                  ),
                )
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(
                  child: buildCoverCardColumn(
                    context,
                    const InitMinesweeper(),
                    "扫雷",
                    imageUrl: coverMinesweeperImageUrl,
                  ),
                ),
                Expanded(
                  child: Container(),
                )
              ],
            ),
          ),
          // Expanded(flex: 1, child: Container()),
        ],
      ),
    );
  }
}

buildCoverCardColumn(
  BuildContext context,
  Widget widget,
  String title, {
  String? subtitle,
  String? imageUrl,
}) {
  return Card(
    clipBehavior: Clip.hardEdge,
    elevation: 5,
    child: InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext ctx) => widget,
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.all(5.sp),
            child: Image.asset(
              imageUrl ?? placeholderImageUrl,
              fit: BoxFit.contain,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    ),
  );
}

// 下面两个暂时留在这里
buildChildWidgetCard(
  BuildContext context,
  Widget widget,
  String title,
) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 20.sp),
    child: Card(
      clipBehavior: Clip.hardEdge,
      elevation: 5,
      color: Theme.of(context).buttonTheme.colorScheme?.onPrimary,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext ctx) => widget,
            ),
          );
        },
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 48.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ),
    ),
  );
}

/// 子组件是带listtile和图片的一行row容器的卡片
/// 用于显示模块首页一排一个带封面图的标题
buildCoverCard(
  BuildContext context,
  Widget widget,
  String title, {
  String? subtitle,
  String? imageUrl,
}) {
  return Card(
    clipBehavior: Clip.hardEdge,
    elevation: 5,
    child: InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext ctx) => widget,
          ),
        );
      },
      child: Center(
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Padding(
                padding: EdgeInsets.all(5.sp),
                child: Image.asset(
                  imageUrl ?? placeholderImageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
