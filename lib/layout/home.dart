import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../common/utils/tool_widgets.dart';
import '../services/my_audio_handler.dart';
import '../services/my_get_storage.dart';
import '../services/service_locator.dart';
import '../views/game_center/index.dart';
import '../views/local_all_media/index.dart';
import '../views/local_music/index.dart';
import '../views/local_photo/index.dart';
import '../views/local_video/index.dart';

/// 主页面

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.selectedIndex});

  // 2024-02-01 新加可以指定默认选中的底部导航索引
  // 主要是游戏中心的扫雷游戏，退出游戏界面后是使用pushAndRemoveUntil导航到home页面，
  // 所以可以指定索引以便显示的是正确的游戏中心而不是初始化的第一个导航栏
  final int? selectedIndex;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //  // 当前选中项的索引 默认选中第一个底部导航条目
  int _currentIndex = 0;
  // 2024-02-02 新加记录上一个底部导航索引，如果是从休闲游戏模块切换到其他模块。需要重新构建音频播放列表
  // 因为目前游戏中心的背景音乐播放器和本地音乐模块播放器是同一个，因为背景播放插件的限制
  // 上一个选中项的索引
  int _previousIndex = 0;

  final _audioHandler = getIt<MyAudioHandler>();
  // 统一简单存储操作的工具类实例
  final _simpleStorage = getIt<MyGetStorage>();

  // 是否音频初始化加载完成
  bool isLoading = false;

  // 2024-01-25 彩蛋功能，底部导航栏的数量和页面根据缓存中的值来改变
  List<Widget> _widgetOptions = [];
  List<BottomNavigationBarItem> bottomNavBarItems = [];

  @override
  void initState() {
    super.initState();

    // 2024-01-25 根据缓存值显示底部导航条目数量
    changeBottomNavItemNum();

    // app初次启动时要获取相关授权，取得之后就不需要重复请求了
    initAudio();

    if (widget.selectedIndex != null) {
      _currentIndex = widget.selectedIndex!;
    }
  }

  /// 2024-01-25 彩蛋功能，根据缓存展示底部导航栏条目的数量
  /// 2 个时就只显示本地音乐盒全部资源；否则就4个全部显示
  changeBottomNavItemNum() {
    setState(() {
      // 2024-01-25 注意，因为可能在4切换成2的时候，当前标签tab在2或者3,那就找不到对应的了。所以默认都改成第一个。
      _currentIndex = 0;

      var num = _simpleStorage.getBottomNavItemMun();

      if (num > 3) {
        _widgetOptions = const [
          LocalMusic(),
          LocalVideo(),
          LocalPhoto(),
          LocalAllMedia(),
          GameCenter(),
        ];

        bottomNavBarItems = const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.audiotrack), label: '本地音乐'),
          BottomNavigationBarItem(icon: Icon(Icons.video_file), label: '本地视频'),
          BottomNavigationBarItem(icon: Icon(Icons.image), label: '本地图片'),
          BottomNavigationBarItem(icon: Icon(Icons.all_inbox), label: '全部资源'),
          BottomNavigationBarItem(icon: Icon(Icons.games), label: '休闲游戏'),
        ];
      } else {
        _widgetOptions = const [
          LocalMusic(),
          LocalAllMedia(),
          GameCenter(),
        ];
        bottomNavBarItems = const [
          BottomNavigationBarItem(icon: Icon(Icons.audiotrack), label: '本地音乐'),
          BottomNavigationBarItem(icon: Icon(Icons.all_inbox), label: '全部资源'),
          BottomNavigationBarItem(icon: Icon(Icons.games), label: '休闲游戏'),
        ];
      }
    });
  }

  // 获取存储权限
  initAudio() async {
    if (isLoading) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    // 获得授权后，音频控制初始化（主要从持久化数据中获取数据构建当前正在播放的音频和播放列表，没有持久化数据则是默认初始值）
    await _audioHandler.myAudioHandlerInit();

    setState(() {
      isLoading = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _previousIndex = _currentIndex; // 更新上一个索引值
      _currentIndex = index; // 更新当前索引值

      // 2024-02-02
      // 检查是否是从游戏中心tab切换到其他tab
      int gameCenterIndex = _simpleStorage.getBottomNavItemMun() > 3 ? 4 : 2;
      if (_previousIndex == gameCenterIndex &&
          _currentIndex != _previousIndex) {
        initAudio();
      }

      // 如果是从其他tab进入游戏中心，则暂停音乐播放
      var num = _simpleStorage.getBottomNavItemMun();
      if (num > 3 ? _currentIndex == 4 : _currentIndex == 2) {
        // 默认是暂停状态
        _audioHandler.pause();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    /// 全层提供通知
    /// （因为歌单、全部歌曲、艺术家、专辑是tab一层，除`全部`外，需要长按列表改变app中显示的功能）
    /// 而在音频列表中长按音频，也有改变内部app bar显示的功能内容。这样`全部`这个没有中间层的也比较特殊
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
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
              // content: const Text("确定要退出FMP播放器吗?"),
              /// 2024-01-25 彩蛋功能，长按退出的正文，可切换底部导航栏item的数量
              content: GestureDetector(
                onLongPress: () async {
                  if (_simpleStorage.getBottomNavItemMun() > 3) {
                    await _simpleStorage.setBottomNavItemMun(3);
                  } else {
                    await _simpleStorage.setBottomNavItemMun(5);
                  }

                  setState(() {
                    changeBottomNavItemNum();
                  });
                  if (!context.mounted) return;
                  Navigator.pop(context, false);

                  showSnackMessage(
                    context,
                    "恭喜你找到隐藏彩蛋。\n长按退出弹窗正文，可切换底部导航栏数量！",
                    seconds: 5,
                  );
                },
                child: const Text("确定要退出FMP播放器吗?"),
              ),
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
            // 同时关闭音乐播放
            _audioHandler.stop();
            _audioHandler.dispose();

            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        // appBar: AppBar(title: const Text("HOME")),
        // home页的背景色(如果下层还有设定其他主题颜色，会被覆盖)
        body: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    SizedBox(height: 16.sp),
                    const Text("扫描本地音频中……"),
                    const Text("首次使用可能耗时较长"),
                    ValueListenableBuilder<SongModel?>(
                      valueListenable: currentProcessingAudio,
                      builder: (context, value, child) {
                        return Text(value?.displayName ?? '');
                      },
                    ),
                  ],
                ),
              )
            : Center(child: _widgetOptions.elementAt(_currentIndex)),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: bottomNavBarItems,
          currentIndex: _currentIndex,
          // // 底部导航栏的颜色
          // backgroundColor: Theme.of(context).primaryColor,
          // // 被选中的item的图标颜色和文本颜色
          // selectedIconTheme: const IconThemeData(color: Colors.white),
          // selectedItemColor: Colors.white,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
