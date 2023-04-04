// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../services/my_audio_handler.dart';
import '../../services/my_audio_query.dart';
import '../../services/service_locator.dart';
import 'widgets/just_audio_music_player.dart';


class LocalMusicAll extends StatefulWidget {
  const LocalMusicAll({super.key});

  @override
  State<LocalMusicAll> createState() => _LocalMusicAllState();
}

class _LocalMusicAllState extends State<LocalMusicAll> {
  // 获取查询音乐组件实例
  final _audioQuery = getIt<MyAudioQuery>();

  // 音乐播放实例
  final _audioHandler = getIt<MyAudioHandler>();

  @override
  void initState() {
    super.initState();

    _audioQuery.setLogConfig();
    checkPermission();
  }

  checkPermission() async {
    await _audioQuery.checkAndRequestPermissions(retry: false);
    _audioQuery.hasPermission ? setState(() {}) : null;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: !_audioQuery.hasPermission
          ? noAccessToLibraryWidget()
          : FutureBuilder<List<SongModel>>(
              // Default values:
              future: _audioQuery.querySongs(),
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

                // You can use [item.data!] direct or you can create a:
                List<SongModel> songs = item.data!;

                return ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(songs[index].title),
                      subtitle: Text(songs[index].artist ?? "No Artist"),
                      trailing: const Icon(Icons.arrow_forward_rounded),
                      // This Widget will query/load image.
                      // You can use/create your own widget/method using [queryArtwork].
                      leading: QueryArtworkWidget(
                        controller: _audioQuery.onAudioQueryController,
                        id: songs[index].id,
                        type: ArtworkType.AUDIO,
                      ),
                      onTap: () {
                        print('MyButton was tapped!');
                        print(songs[index].runtimeType);

                        // 到这里就已经查询到当前“全部歌曲”页面中所有的歌曲了，可以构建播放列表和当前音频
                        _audioHandler.buildPlaylist(songs, songs[index]);
                        _audioHandler.refreshCurrentPlaylist();

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
    );
  }

  Widget noAccessToLibraryWidget() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.redAccent.withOpacity(0.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Application doesn't have access to the library"),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () =>
                _audioQuery.checkAndRequestPermissions(retry: true),
            child: const Text("Allow"),
          ),
        ],
      ),
    );
  }
}