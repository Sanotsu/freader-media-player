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
import 'widgets/build_add_to_playlist_dialog.dart';
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
    return ChangeNotifierProvider(
      create: (context) => AudioInList(),
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildBody(context),
      ),
    );
  }

  /// 构建标题工具栏
  _buildAppBar() {
    return AppBar(
      title: const Text("本地音乐"),
      actions: <Widget>[
        // 因为使用了consumer，在其他组件中改变了其中类的属性，这里也会识别到
        Consumer<AudioInList>(
          builder: (context, alp, child) {
            print(
              "xxxxxxxxxxxxxxxxxxxxxxxxxxx ${alp.isLongPress} ${alp.isAddToList} ${alp.isRemoveFromList}",
            );

            /// 在“全部”tab长按，是根据音频来显示按钮。其他3个，则是类型子列表来显示
            return alp.isLongPress && alp.currentTabName == AudioListTypes.all
                ? Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        tooltip: '加入歌单',
                        onPressed: () => buildAddToPlaylistDialog(context, alp),
                      ),
                      IconButton(
                        icon: const Icon(Icons.info),
                        tooltip: '查看信息(暂不做)',
                        onPressed: () {},
                      )
                    ],
                  )
                : Container();
          },
        ),
      ],
    );
  }

  /// 构建主体内容（是个 TabBarView）
  _buildBody(context) {
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
                print(
                    "22222222222222222222 ${tabController.index} ${alp.currentTabName}");
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
                        child: Text("歌单",
                            style: TextStyle(fontSize: sizeHeadline3))),
                    Tab(
                        child: Text("全部",
                            style: TextStyle(fontSize: sizeHeadline3))),
                    Tab(
                        child: Text("歌手",
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

  Widget buildLongPressButtons() {
    var alp = context.read<AudioInList>();

    print(
        "buildLongPressButtonsXXXXXXXXXXXXXXX  ${alp.isLongPress}  ${alp.currentTabName} ");

    return SizedBox(
      height: 20.sp,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            tooltip: '从列表中移除',
            onPressed: () {
              setState(() {
                // 修改移除歌单中指定音频标志为true
                alp.changeIsRemoveFromList(true);
                // 单击了功能按钮之后，立马切回长按状态为否
                alp.changeIsLongPress(false);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.info),
            tooltip: '详细信息',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This is a 详细信息'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: '删除文件',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This is a 删除文件'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: '更多功能',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This is a 更多功能'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  buildDefaultButtons() {
    return Container();
  }
}
