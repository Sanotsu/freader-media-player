// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:freader_music_player/common/global/constants.dart';
import 'package:provider/provider.dart';

import '../../common/utils/global_styles.dart';

import '../../models/is_long_press.dart';
import 'album.dart';
import 'all.dart';
import 'artist.dart';
import 'playlist.dart';
import 'widgets/music_player_mini_bar.dart';

/// 正常来讲，应该把AudioPlayer处理成全局单例的，例如使用get_it，palyer的所有操作封装为一个service class，然后全局使用。
/// 这里简单测试，就在最外层初始化，然后传递给子组件（虽然麻烦，但暂时不需要其他依赖）

class LocalMusic extends StatefulWidget {
  const LocalMusic({super.key});

  @override
  State<LocalMusic> createState() => _LocalMusicState();
}

class _LocalMusicState extends State<LocalMusic> {
  @override
  Widget build(BuildContext context) {
    return _buildTab(context);
  }

  _buildTab(context) {
    return DefaultTabController(
      length: 4,
      child: Builder(builder: (BuildContext context) {
        final TabController tabController = DefaultTabController.of(context);
        AudioInList alp = context.read<AudioInList>();
        tabController.addListener(() {
          // 如果tab的所以改变了，这里可以获取到，同时修改provide当前tab的名称
          if (!tabController.indexIsChanging) {
            // Your code goes here.
            // To get index of current tab use tabController.index
            print("当前tab ${tabController.index}");
            setState(() {
              if (tabController.index == 0) {
                alp.changeCurrentTabName(AudioListTypes.playlist);
              } else if (tabController.index == 1) {
                alp.changeCurrentTabName(AudioListTypes.all);
              } else if (tabController.index == 2) {
                alp.changeCurrentTabName(AudioListTypes.artist);
              } else if (tabController.index == 3) {
                alp.changeCurrentTabName(AudioListTypes.album);
              }
            });
          }
        });
        return Center(
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
                    LocalMusicArtist(),
                    LocalMusicAlbum(),
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
        );
      }),
    );
  }
}
