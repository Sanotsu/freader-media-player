// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../common/utils/global_styles.dart';
import '../models/change_display_mode.dart';
import '../views/local_music/index.dart';
import '../views/local_video/index.dart';
import '../views/user_center/index.dart';

/// 主页面

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1;

  static const List<Widget> _widgetOptions = <Widget>[
    LocalMusic(),
    LocalVideo(),
    UserCenter(),
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
    ChangeDisplayMode cdm = context.watch<ChangeDisplayMode>();

    return Scaffold(
      // home页的背景色(如果下层还有设定其他主题颜色，会被覆盖)
      // backgroundColor: Colors.red,
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.music_note), label: 'Music'),
          // BottomNavigationBarItem(icon: Icon(Icons.cloud), label: 'Online'),
          BottomNavigationBarItem(icon: Icon(Icons.video_file), label: 'Video'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        // 底部导航栏的颜色
        // backgroundColor: dartThemeMaterialColor3,
        backgroundColor: cdm.currentDisplayMode == DisplayMode.DARK
            ? dartThemeMaterialColor3
            : Theme.of(context).primaryColor,
        // 被选中的item的图标颜色和文本颜色
        selectedIconTheme: const IconThemeData(color: Colors.white),
        selectedItemColor: Colors.white,
        onTap: _onItemTapped,
      ),
    );
  }
}
