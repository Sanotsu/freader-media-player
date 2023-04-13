// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:freader_music_player/models/list_long_press.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../../common/global/constants.dart';
import '../../models/audio_long_press.dart';
import '../../services/my_audio_query.dart';
import '../../services/service_locator.dart';
import 'nested_pages/audio_list_detail.dart';

class LocalMusicPlaylist extends StatefulWidget {
  const LocalMusicPlaylist({super.key});

  @override
  State<LocalMusicPlaylist> createState() => _LocalMusicPlaylistState();
}

class _LocalMusicPlaylistState extends State<LocalMusicPlaylist> {
  // 获取查询音乐组件实例
  final _audioQuery = getIt<MyAudioQuery>();

  // 根据不同播放列表类型，构建不同的查询处理
  late Future<List<PlaylistModel>> futureHandler;

  // 被选中的item的索引列表
  List<PlaylistModel> selectedPlaylists = [];

  @override
  void initState() {
    super.initState();
    initData();
  }

  initData() async {
    setState(() {
      futureHandler = _audioQuery.queryPlaylists();
    });

    var plist2 = await _audioQuery.queryPlaylists();
    var songs = await _audioQuery.queryAudiosFrom(
      AudiosFromType.PLAYLIST,
      201076,
    );

    // 返回是动态类型，使用的是转为指定类型
    List<dynamic> songs2 = await _audioQuery.queryWithFilters(
      "有一种爱叫做放手",
      WithFiltersType.AUDIOS,
      args: AudiosArgs.TITLE,
    );

    // 插件原始函数有bug
    // await _audioQuery.renamePlaylist(201060, "新名字");

    print("000000000000000000000000000000");
    print(plist2);
    print(songs);
    print(songs2);
    print("000000000000000000000000000000");
    //
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ListLongPress>(
      builder: (context, alp, child) {
        print(
            "localmusic index 下playlist中 ${alp.isPlaylistLongPress} ${alp.selectedPlaylistList.length} ");

        /// 如果是在播放列表中对某音频进行了长按，则在此处显示一些功能按钮
        ///   暂时有：查看信息、从当前列表移除、三个点（添加到播放列表、添加到队列(这个暂不实现)、全选等）
        /// 如果是默认显示的，应该有：排序、搜索、三个点（展开其他功能）
        return _buildList(context);
      },
    );
    // return _buildList(context);
  }

  _buildList(BuildContext context) {
    ListLongPress llp = context.read<ListLongPress>();

    if (llp.isRenamePlaylist) {
      print("执行将选择的音频从歌单移除的逻辑");
      renameSelectedPlaylist(llp);
    }

    // 如果是上层使用provide取消了长按标志，这里得清空被选中的数组
    if (!llp.isPlaylistLongPress) {
      print("执行取消选择的歌单的逻辑");
      selectedPlaylists.length = 0;
      // 取消歌单长按，有可能是删除了歌单，那么需要刷新一下歌单数据
      futureHandler = _audioQuery.queryPlaylists();
    }

    return FutureBuilder<List<PlaylistModel>>(
      future: futureHandler,
      builder: (context, item) {
        // Display error, if any.
        if (item.hasError) {
          return Text(item.error.toString());
        }
        // Waiting content.
        if (item.data == null) {
          return const CircularProgressIndicator();
        }
        // 'Library' is empty.
        if (item.data!.isEmpty) return const Text("Nothing found!");

        // 得到查询的歌单列表
        List<PlaylistModel> playlists = item.data!;

        return ListView.builder(
          itemCount: playlists.length,
          itemBuilder: (ctx, index) {
            return ListTile(
              selected: selectedPlaylists.contains(playlists[index]),
              title: Text(playlists[index].playlist),
              subtitle: Text(playlists[index].numOfSongs.toString()),
              trailing: const Icon(Icons.arrow_forward_rounded),
              // 这个小部件将查询/加载图像。可以使用/创建你自己的Widget/方法，使用[queryArtwork]。
              leading: QueryArtworkWidget(
                controller: _audioQuery.onAudioQueryController,
                // 显示根据歌手id查询的歌手图片
                id: playlists[index].id,
                type: ArtworkType.PLAYLIST,
              ),
              onLongPress: () {
                setState(() {
                  // 修改歌单长按标志为true
                  llp.changeIsPlaylistLongPress(true);
                  selectedPlaylists.add(playlists[index]);
                  llp.changeSelectedPlaylists(selectedPlaylists);
                });
              },
              onTap: () {
                if (llp.isPlaylistLongPress) {
                  setState(() {
                    // 如果已经加入被选中列表，再次点击则移除
                    if (selectedPlaylists.contains(playlists[index])) {
                      selectedPlaylists.remove(playlists[index]);
                    } else {
                      selectedPlaylists.add(playlists[index]);
                    }
                    // 如果被选中的列表清空，那就假装没有点击长按用于选择音频
                    if (selectedPlaylists.isEmpty) {
                      llp.changeIsPlaylistLongPress(false);
                    }

                    // 不管如何，点击了，就要更新被选中的歌单列表
                    llp.changeSelectedPlaylists(selectedPlaylists);
                  });
                } else {
                  print(
                    '指定歌单 ${playlists[index].playlist}  was tapped! id Is ${playlists[index].id}',
                  );

                  // final AudioInList yourModel =
                  //     Provider.of<AudioInList>(context, listen: false);

                  Navigator.of(ctx)
                      .push(
                        MaterialPageRoute(
                          // 在选中指定歌单点击后，进入音频列表，同时监控是否有对音频长按
                          builder: (BuildContext ctx) => ListenableProvider(
                            create: (ctx) => AudioLongPress(),
                            builder: (context, child) =>
                                LocalMusicAudioListDetail(
                              audioListType: AudioListTypes.playlist,
                              audioListId: playlists[index].id,
                              audioListTitle: playlists[index].playlist,
                            ),
                          ),
                        ),
                      )
                      .then((value) => initData());
                  //     .then(
                  //   (value) {
                  //     print("这是跳转路由后返回的数据： $value");
                  //     // 在pdf viewer页面返回后，重新获取pdf list，更新阅读进度
                  //     if (value != null && value["isReload"]) {
                  //       print("这里执行了歌单列表重新加载的逻辑");
                  //       initData();
                  //     }
                  //   },
                  // );
                }
              },
            );
          },
        );
      },
    );
  }

  renameSelectedPlaylist(ListLongPress llp) {
    _audioQuery.renamePlaylist(selectedPlaylists[0].id, llp.newPlaylistName);
    llp.changeIsPlaylistLongPress(false);
  }
}
