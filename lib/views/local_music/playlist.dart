// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

import '../../services/my_audio_query.dart';
import '../../services/service_locator.dart';

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

    await _audioQuery.createPlaylist("随便歌单${DateTime.now()}");

    var plist2 = await _audioQuery.queryPlaylists();
    print(plist2);
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
