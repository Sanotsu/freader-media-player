// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../services/my_audio_query.dart';
import '../../services/service_locator.dart';
import 'nested_pages/playlist_detail.dart';

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
    // await _audioQuery.addToPlaylist(201060, 192793);

    print(plist2);
    print(plist2.length);
  }

  @override
  Widget build(BuildContext context) {
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

        List<PlaylistModel> playlists = item.data!;

        return ListView.builder(
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(playlists[index].playlist),
              subtitle: Text(playlists[index].numOfSongs.toString()),
              trailing: const Icon(Icons.arrow_forward_rounded),
              onTap: () {
                print(
                    '指定歌单 ${playlists[index].playlist}  was tapped! id Is ${playlists[index].id}');

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext ctx) {
                      return LocalMusicPlaylistDetail(
                        playlistInfo: playlists[index],
                      );
                    },
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
