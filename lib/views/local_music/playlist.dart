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

  @override
  void initState() {
    super.initState();
    initData();
  }

  initData() async {
    var plist = await _audioQuery.queryPlaylists();

    print("000000000000000000000000000000");
    print(plist);
    print("000000000000000000000000000000");

    // await _audioQuery.createPlaylist("示例歌单1");
    // await _audioQuery.createPlaylist("测试歌单2");
    // await _audioQuery.createPlaylist("随便歌单3");
    // 上面创建的歌单，有id为 201059 201060 201061

    var plist2 = await _audioQuery.queryPlaylists();

    // await _audioQuery.removeFromPlaylist(201060, 1);
    // await _audioQuery.addToPlaylist(201060, 192715);

    print(plist2);
    print(plist2.length);
  }

  @override
  Widget build(BuildContext context) {
    return _buildList(context);
  }

  _buildList(context) {
    return FutureBuilder<List<PlaylistModel>>(
      future: _audioQuery.queryPlaylists(),
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
                Navigator.of(ctx).push(
                  MaterialPageRoute(
                    // 在选中指定歌单点击后，进入音频列表，同时监控是否有对音频长按
                    builder: (BuildContext ctx) => ListenableProvider(
                      create: (ctx) => AudioInList(),
                      builder: (context, child) => LocalMusicAudioListDetail(
                        audioListType: AudioListTypes.playlist,
                        audioListId: playlists[index].id,
                        audioListTitle: playlists[index].playlist,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
