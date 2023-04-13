// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../../common/global/constants.dart';
import '../../models/audio_long_press.dart';
import '../../services/my_audio_query.dart';
import '../../services/service_locator.dart';
import 'nested_pages/audio_list_detail.dart';

class LocalMusicArtist extends StatefulWidget {
  const LocalMusicArtist({super.key});

  @override
  State<LocalMusicArtist> createState() => _LocalMusicArtistState();
}

class _LocalMusicArtistState extends State<LocalMusicArtist> {
  // 获取查询音乐组件实例
  final _audioQuery = getIt<MyAudioQuery>();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ArtistModel>>(
      future: _audioQuery.queryArtists(),
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

        // 得到查询的歌手列表
        List<ArtistModel> artists = item.data!;

        return ListView.builder(
          itemCount: artists.length,
          itemExtent: 80.sp, // 每个item内部组件的高度
          itemBuilder: (context, index) {
            return ListTile(
              minLeadingWidth: 100.sp, // 左侧缩略图标的最小宽度
              title: Text(artists[index].artist),
              subtitle: Text(
                "${artists[index].numberOfTracks.toString()} 张专辑 ${artists[index].numberOfTracks.toString()} 首歌曲",
              ),
              // 这个小部件将查询/加载图像。可以使用/创建你自己的Widget/方法，使用[queryArtwork]。
              leading: QueryArtworkWidget(
                controller: _audioQuery.onAudioQueryController,
                // 显示根据歌手id查询的歌手图片
                id: artists[index].id,
                type: ArtworkType.ARTIST,
                artworkBorder: const BorderRadius.all(Radius.zero), // 缩略图不显示圆角
                // artworkWidth: 100.sp, // 默认是50*50的大小
                // artworkHeight: 100.sp, // 这个高度显示不太对
              ),
              onTap: () {
                print(
                  '指定歌手 ${artists[index].artist}  was tapped! id Is ${artists[index].id}',
                );

                Navigator.of(context).push(
                  MaterialPageRoute(
                    // 在选中指定歌单点击后，进入音频列表，同时监控是否有对音频长按
                    builder: (BuildContext ctx) => ListenableProvider(
                      create: (ctx) => AudioLongPress(),
                      builder: (context, child) => LocalMusicAudioListDetail(
                        audioListType: AudioListTypes.artist,
                        audioListId: artists[index].id,
                        audioListTitle: artists[index].artist,
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
