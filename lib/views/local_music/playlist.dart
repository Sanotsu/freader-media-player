// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../../common/global/constants.dart';
import '../../models/is_long_press.dart';
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

    print("000000000000000000000000000000");
    print(plist2);
    print(songs);
    print(songs2);
    print("000000000000000000000000000000");
    //
  }

  @override
  Widget build(BuildContext context) {
    return _buildList(context);
  }

  _buildList(context) {
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
              onTap: () {
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
                          create: (ctx) => AudioInList(),
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
              },
            );
          },
        );
      },
    );
  }
}
