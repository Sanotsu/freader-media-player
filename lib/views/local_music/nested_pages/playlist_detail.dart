// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../../services/my_audio_handler.dart';
import '../../../services/my_audio_query.dart';
import '../../../services/my_shared_preferences.dart';
import '../../../services/service_locator.dart';
import 'just_audio_music_player_detail.dart';
import '../widgets/music_player_mini_bar.dart';

/// 显示歌单内部的歌曲，则需要传入歌单编号
///
class LocalMusicPlaylistDetail extends StatefulWidget {
  const LocalMusicPlaylistDetail({super.key, required this.playlistInfo});

  final PlaylistModel playlistInfo;

  @override
  State<LocalMusicPlaylistDetail> createState() => _PlayerlistDetailState();
}

class _PlayerlistDetailState extends State<LocalMusicPlaylistDetail> {
  // 音乐播放实例
  final _audioHandler = getIt<MyAudioHandler>();
  // 获取查询音乐组件实例
  final _audioQuery = getIt<MyAudioQuery>();
  // 统一简单存储操作的工具类实例
  final _simpleShared = getIt<MySharedPreferences>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlistInfo.playlist),
      ),
      body: Column(children: [
        Expanded(
          child: FutureBuilder<List<SongModel>>(
            future: _audioQuery.queryAudiosFrom(
                AudiosFromType.PLAYLIST, widget.playlistInfo.id),
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

              List<SongModel> songs = item.data!;

              return ListView.builder(
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(songs[index].title),
                    subtitle: Text(songs[index].artist ?? "未知歌手"),
                    trailing: const Icon(Icons.arrow_forward_rounded),
                    onTap: () async {
                      print(
                          '歌曲 ${songs[index].artist}  was tapped! id Is ${songs[index].id}');
                      print("widget.playlistInfo.id ${widget.playlistInfo.id}");
                      print("songs[index].id ${songs[index].id}");

                      // 到这里就已经查询到当前“歌单”页面中所有的歌曲了，可以构建播放列表和当前音频
                      await _audioHandler.buildPlaylist(songs, songs[index]);
                      await _audioHandler.refreshCurrentPlaylist();

                      // 将歌单信息、被点击的音频编号存入持久化
                      await _simpleShared.setCurrentAudioListType('playlist');
                      await _simpleShared.setCurrentPlaylistId(
                          widget.playlistInfo.id.toString());
                      await _simpleShared
                          .setCurrentAudioIndex(index.toString());

                      if (!mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext ctx) {
                            return const JustAudioMusicPlayer();
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        SizedBox(
          height: 60.sp,
          width: 1.sw,
          child: const MusicPlayerMiniBar(),
        ),
      ]),
    );
  }
}
