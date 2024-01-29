// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../common/global/constants.dart';
import 'flutter_2048/game_2048.dart';

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
    // 计算屏幕剩余的高度
    // 设备屏幕的总高度
    //  - 屏幕顶部的安全区域高度，即状态栏的高度
    //  - 屏幕底部的安全区域高度，即导航栏的高度或者虚拟按键的高度
    //  - 应用程序顶部的工具栏（如 AppBar）的高度
    //  - 应用程序底部的导航栏的高度
    //  - 组件的边框间隔(不一定就是2)
    double screenHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom -
        kToolbarHeight -
        kBottomNavigationBarHeight -
        2 * 12.sp; // 减的越多，上下空隙越大

    return Scaffold(
      // 避免搜索时弹出键盘，让底部的minibar位置移动到tab顶部导致溢出的问题
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("休闲游戏"),
      ),
      body: buildFixedBody(screenHeight),
    );
  }

  // 可视页面固定等分居中、不可滚动的首页
  buildFixedBody(double screenHeight) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: SizedBox(height: screenHeight / 4, child: Container()),
          ),
          Expanded(
            child: SizedBox(
              height: screenHeight / 4,
              child: buildChildWidgetCard(
                context,
                const InitGame2048(),
                "2048",
              ),
            ),
          ),
          // Expanded(
          //   child: SizedBox(
          //     height: screenHeight / 4,
          //     child: buildChildWidgetCard(
          //       context,
          //       Container(),
          //       "俄罗斯方块",
          //     ),
          //   ),
          // ),
          Expanded(
            child: SizedBox(height: screenHeight / 4, child: Container()),
          ),
          Expanded(
            child: SizedBox(height: screenHeight / 4, child: Container()),
          ),
        ],
      ),
    );
  }
}

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
  String? routeName,
}) {
  return Card(
    clipBehavior: Clip.hardEdge,
    elevation: 5,
    child: InkWell(
      onTap: () {
        if (routeName != null) {
          // 这里需要使用pushName 带上指定的路由名称，后续跨层级popUntil的时候才能指定路由名称进行传参
          Navigator.pushNamed(context, routeName);
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext ctx) => widget,
            ),
          );
        }
      },
      child: Center(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(5.sp),
                child: Image.asset(
                  imageUrl ?? placeholderImageUrl,
                  fit: BoxFit.scaleDown,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: ListTile(
                title: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                subtitle: Text(subtitle ?? ""),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
