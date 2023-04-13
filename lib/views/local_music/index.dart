// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:freader_music_player/common/global/constants.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../../common/utils/global_styles.dart';
import '../../common/utils/tools.dart';
import '../../models/audio_long_press.dart';

import '../../models/list_long_press.dart';
import '../../services/my_audio_query.dart';
import '../../services/service_locator.dart';
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
  bool isShowDefaultButton = true;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioLongPress()),
        ChangeNotifierProvider(create: (_) => ListLongPress()),
      ],
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: _buildBody(context),
      ),
    );
  }

  /// 构建标题工具栏
  _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text("本地音乐"),
      actions: <Widget>[
        /// 在“全部”tab长按，是根据音频来显示按钮。其他3个，则是类型子列表来显示
        /// 如果没有长按音频也没有长按列表，则显示默认工具按钮
        _buildDefaultButtons(),
        _buildLongPressButtons(),
      ],
    );
  }

  /// 构建主体内容（是个 TabBarView）
  _buildBody(context) {
    return DefaultTabController(
      length: 4,
      child: Builder(builder: (BuildContext context) {
        final TabController tabController = DefaultTabController.of(context);
        AudioLongPress alp = context.read<AudioLongPress>();
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

  // 显示修改歌单名称弹窗
  _buildRenamePlaylistDialog(BuildContext context, ListLongPress llp) async {
    // 获取查询音乐组件实例
    final audioQuery = getIt<MyAudioQuery>();

    print("点击了修改歌单名称");
    var playInput = llp.selectedPlaylistList[0].playlist;
    return await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('创建新歌单'),
            content: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
              // return TextField(
              //   onChanged: (value) {
              //     setState(() {
              //       playInput = value;
              //     });
              //   },
              //   controller: TextEditingController(text: playInput),
              //   decoration: const InputDecoration(hintText: "输入新歌单名"),
              // );
              return TextFormField(
                autofocus: false,
                initialValue: playInput,
                decoration: const InputDecoration(hintText: '输入新歌单名'),
                onChanged: (value) {
                  setState(() {
                    playInput = value;
                  });
                },
              );
            }),
            actions: <Widget>[
              StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                return MaterialButton(
                  color: Colors.red,
                  textColor: Colors.white,
                  child: const Text('取消'),
                  onPressed: () {
                    setState(() {
                      // 单击了取消功能按钮之后，立马切回长按状态为否，也取消弹窗
                      llp.changeIsPlaylistLongPress(false);
                      // 清空被选中的歌单列表
                      llp.changeSelectedPlaylists([]);
                      Navigator.pop(context);
                    });
                  },
                );
              }),
              StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                return MaterialButton(
                  color: Colors.green,
                  textColor: Colors.white,
                  child: const Text('确认'),
                  onPressed: () async {
                    // 新建歌单的逻辑，同时加入歌单的逻辑。

                    print(
                      """
                      rename 输入新建的歌单名称 ${llp.selectedPlaylistList[0].id}, $playInput
                      ${await audioQuery.queryDeviceInfo()}
                      """,
                    );

                    ///??? 这里插件自身函数就有bug，需要等待其修复，所以修改歌单暂时无效
                    // await audioQuery.renamePlaylist(
                    //   llp.selectedPlaylistList[0].id,
                    //   playInput,
                    // );

                    setState(() {
                      llp.changeIsPlaylistLongPress(false);
                      Navigator.pop(context);
                    });
                  },
                );
              }),
            ],
          );
        });
  }

  // 显示删除歌单的确认弹窗
  _buildRemovePlaylistDialog(BuildContext context, ListLongPress llp) {
    // 获取查询音乐组件实例
    final audioQuery = getIt<MyAudioQuery>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('移除歌单'),
          content: const Text('这仅会移除被选中的歌单，而不是删除音频文件'),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('取消'),
              onPressed: () {
                setState(() {
                  // 单击了取消功能按钮之后，立马切回长按状态为否，也取消弹窗
                  llp.changeIsPlaylistLongPress(false);
                  // 清空被选中的歌单列表
                  llp.changeSelectedPlaylists([]);
                  Navigator.pop(context);
                });
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('确认'),
              onPressed: () {
                for (var playlist in llp.selectedPlaylistList) {
                  audioQuery.removePlaylist(playlist.id);
                }

                setState(() {
                  llp.changeIsPlaylistLongPress(false);
                  llp.changeSelectedPlaylists([]);
                  Navigator.pop(context);
                });
              },
            ),
          ],
        );
      },
    );
  }

  // 显示歌单信息的弹窗
  _buildPlaylistInfoDialog(BuildContext context, ListLongPress llp) {
    PlaylistModel list = llp.selectedPlaylistList[0];

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        print(list.dateModified);
        return AlertDialog(
          title: const Text('歌单属性'),
          content: SizedBox(
            height: 250.sp,
            width: double.maxFinite,
            child: ListView(children: <Widget>[
              _buildRowText("歌单名称", list.playlist),
              _buildRowText("歌曲数量", list.numOfSongs.toString()),
              _buildRowText("歌单编号", list.id.toString()),
              _buildRowText(
                  "创建时间",
                  list.dateAdded != null
                      ? formatTimestampToString(list.dateAdded!)
                      : ""),
              _buildRowText(
                  "修改时间",
                  list.dateAdded != null
                      ? formatTimestampToString(list.dateModified!)
                      : ""),
              _buildRowText("歌单位置", list.data.toString()),
            ]),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('确认'),
              onPressed: () {
                setState(() {
                  // 单击了取消功能按钮之后，立马切回长按状态为否，也取消弹窗
                  llp.changeIsPlaylistLongPress(false);
                  // 清空被选中的歌单列表
                  llp.changeSelectedPlaylists([]);
                  Navigator.pop(context);
                });
              },
            ),
          ],
        );
      },
    );
  }

  // 构建一行依次为标签+属性的row widget
  _buildRowText(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 1,
          child: Text(
            label, // 文字内容
            overflow: TextOverflow.ellipsis, // 过长显示省略号
            style: const TextStyle(fontWeight: FontWeight.bold), // 文字样式
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            value, // 文字内容
            // overflow: TextOverflow.ellipsis, // 过长显示省略号
            overflow: TextOverflow.visible, // 过长显示省略号
            style: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14.sp,
              color: const Color.fromARGB(255, 75, 72, 72),
            ), // 文字样式
          ),
        )
      ],
    );
  }

  // 长按歌单后的工具按钮（修改名称、详情、删除）
  _buildLongPressButtons() {
    return Row(
      children: [
        // 因为使用了consumer，在其他组件中改变了其中类的属性，这里也会识别到
        // 如果是“全部”tab中音频被长按选中
        Consumer<AudioLongPress>(
          builder: (context, alp, child) {
            print(
              "xxxxxxxxxxxxxxxxxxxxxxxxxxx ${alp.isAudioLongPress} ${alp.isAddToList} ${alp.isRemoveFromList}",
            );
            return alp.isAudioLongPress &&
                    alp.currentTabName == AudioListTypes.all
                ? IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: '加入歌单',
                    onPressed: () => buildAddToPlaylistDialog(context, alp),
                  )
                : Container();
          },
        ),
        // 如果是“歌单”tab中指定单个歌单被长按选中，可显示修改
        Consumer<ListLongPress>(
          builder: (context, llp, child) =>
              llp.isPlaylistLongPress && llp.selectedPlaylistList.length == 1
                  ? IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: '修改歌单名称',
                      onPressed: () => _buildRenamePlaylistDialog(context, llp),
                    )
                  : Container(),
        ),
        // 如果是“歌单”tab中指定单个歌单被长按选中，可显示查看信息
        Consumer<ListLongPress>(
          builder: (context, llp, child) =>
              llp.isPlaylistLongPress && llp.selectedPlaylistList.length == 1
                  ? IconButton(
                      icon: const Icon(Icons.info),
                      tooltip: '查看信息(暂不做)',
                      onPressed: () => _buildPlaylistInfoDialog(context, llp),
                    )
                  : Container(),
        ),
        // 如果是“歌单”tab中指定多个歌单被长按选中，可显示删除
        Consumer<ListLongPress>(
          builder: (context, llp, child) => llp.isPlaylistLongPress
              ? IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: '删除选中的歌单',
                  onPressed: () => _buildRemovePlaylistDialog(context, llp),
                )
              : Container(),
        ),
      ],
    );
  }

  // 默认的工具按钮（查询和排序）
  _buildDefaultButtons() {
    return Consumer2<AudioLongPress, ListLongPress>(
      builder: (context, alp, llp, child) {
        return !alp.isAudioLongPress && !llp.isPlaylistLongPress
            ? SizedBox(
                height: 20.sp,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.search),
                      tooltip: '音频查询',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('最外层的音频查询'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.sort),
                      tooltip: '排序',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('最外层的排序'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              )
            : Container();
      },
    );
  }
}
