// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../common/utils/global_styles.dart';

import 'all.dart';
import 'playlist.dart';
import 'widgets/music_player_mini_bar.dart';

/// 正常来讲，应该把AudioPlayer处理成全局单例的，例如使用get_it，palyer的所有操作封装为一个service class，然后全局使用。
/// 这里简单测试，就在最外层初始化，然后传递给子组件（虽然麻烦，但暂时不需要其他依赖）

class LocalMusic extends StatelessWidget {
  const LocalMusic({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Center(
        child: Column(
          children: <Widget>[
            Container(
              height: 30.sp,
              color: Colors.brown, // 用來看位置，不需要的话这个Container可以改为SizedBox
              child: TabBar(
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(
                      width: 3.0.sp, color: Colors.lightBlue), // 下划线的粗度和颜色
                  // 下划线的四边的间距horizontal橫向
                  insets: EdgeInsets.symmetric(horizontal: 2.0.sp),
                ),
                indicatorWeight: 0,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: [
                  Tab(
                      child: Text("播放列表",
                          style: TextStyle(fontSize: sizeHeadline3))),
                  Tab(
                      child: Text("全部",
                          style: TextStyle(fontSize: sizeHeadline3))),
                  Tab(
                      child: Text("艺术家",
                          style: TextStyle(fontSize: sizeHeadline3))),
                  Tab(
                      child: Text("专辑",
                          style: TextStyle(fontSize: sizeHeadline3))),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: <Widget>[
                  LocalMusicPlaylist(),
                  LocalMusicAll(),
                  Center(child: Text("艺术家 占位")),
                  Center(child: Text("专辑 占位")),
                ],
              ),
            ),
            SizedBox(
              height: 60.sp,
              width: 1.sw,
              child: const MusicPlayerMiniBar(),
            ),
          ],
        ),
      ),
    );
  }
}
