// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../common/utils/global_styles.dart';
import '../views/local_music/index.dart';
import '../views/local_media/index.dart';

/// 主页面

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    LocalMusic(),
    LocalMedia(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    /// 全层提供通知
    /// （因为歌单、全部歌曲、艺术家、专辑是tab一层，除`全部`外，需要长按列表改变app中显示的功能）
    /// 而在音频列表中长按音频，也有改变内部app bar显示的功能内容。这样`全部`这个没有中间层的也比较特殊
    ///
    ///

    return PopScope(
      // 点击返回键时暂停返回
      canPop: false,
      onPopInvoked: (didPop) async {
        print("didPop-----------$didPop");
        if (didPop) {
          return;
        }
        final NavigatorState navigator = Navigator.of(context);
        // 如果确认弹窗点击确认返回true，否则返回false
        final bool? shouldPop = await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('关闭'),
              content: const Text("确定要退出播放器吗?"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text("取消"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text("确定"),
                ),
              ],
            );
          },
        ); // 只有当对话框返回true 才 pop(返回上一层)
        if (shouldPop ?? false) {
          // 如果还有可以关闭的导航，则继续pop
          if (navigator.canPop()) {
            navigator.pop();
          } else {
            // 如果已经到头来，则关闭应用程序
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        // home页的背景色(如果下层还有设定其他主题颜色，会被覆盖)
        body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.music_note),
              label: '本地音乐',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.video_file),
              label: '图片视频',
            ),
          ],
          currentIndex: _selectedIndex,
          // 底部导航栏的颜色
          backgroundColor: Theme.of(context).primaryColor,
          // 被选中的item的图标颜色和文本颜色
          selectedIconTheme: const IconThemeData(color: Colors.white),
          selectedItemColor: Colors.white,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

buildDrawer(BuildContext context) {
  return Drawer(
    // 使用list view 内容高度超过页面可以滚动；
    child: ListView(
      // 删除任何填充
      padding: EdgeInsets.zero,
      children: [
        // 用户信息标头
        DrawerHeader(
          // 背景色蓝色
          decoration: BoxDecoration(color: Theme.of(context).primaryColor),
          child: Center(
            child: ListTile(
              title: Text(
                ' Named 小流',
                style: TextStyle(
                  fontSize: sizeHeadline1,
                  // color: Theme.of(context).canvasColor,
                ),
              ),
              subtitle: const Text('故君子居必择乡，游必就士，所以防邪僻而中正也。'),
              leading: Icon(Icons.account_box, size: 50.sp),
              onTap: null,
            ),
          ),
        ),
        const ListTile(
          leading: Icon(Icons.abc),
          title: Text('预留列表'),
          subtitle: Text('不积跬步，无以至千里；'),
        ),
        const ListTile(
          leading: Icon(Icons.abc),
          title: Text('预留列表'),
          subtitle: Text('不积小流，无以成江海。'),
        )
      ],
    ),
  );
}
