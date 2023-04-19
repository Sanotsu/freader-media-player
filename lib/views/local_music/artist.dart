// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../../common/global/constants.dart';
import '../../models/audio_long_press.dart';
import '../../models/list_long_press.dart';
import '../../models/sort_option_selected.dart';
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

  // 根据不同歌手类型(查询所有歌手或者条件查询歌手)，构建不同的查询处理
  late Future<List<dynamic>> futureHandler;

  @override
  Widget build(BuildContext context) {
    return Consumer2<ListLongPress, AudioOptionSelected>(
      builder: (context, llp, aos, child) {
        print(
          "localmusic index 下artist中 ${llp.isPlaylistLongPress} ${llp.selectedPlaylistList.length} ${llp.localMusicAppBarSearchInput}",
        );

        /// 如果是在播放列表中对某音频进行了长按，则在此处显示一些功能按钮
        ///   暂时有：查看信息、从当前列表移除、三个点（添加到播放列表、添加到队列(这个暂不实现)、全选等）
        /// 如果是默认显示的，应该有：排序、搜索、三个点（展开其他功能）
        return _buildList(context, llp, aos);
      },
    );
  }

  _buildList(BuildContext context, ListLongPress llp, AudioOptionSelected aos) {
    // 如果是主页上歌单的条件查询
    if (llp.localMusicAppBarSearchInput != null) {
      print("【歌手】执行了条件查询的逻辑");
      futureHandler = _audioQuery.queryWithFilters(
        llp.localMusicAppBarSearchInput!,
        WithFiltersType.ARTISTS,
      );
    } else {
      // 如果等于null，说明是初始化，或者关闭了查询按钮，歌单要重新查询所有。
      // 此外，在排序时，也是直接获取到对应的排序类别和用于排序的关键字；如果是条件查询，则不对结果排序了(也不知道怎么排)
      print("执行了【歌单初始化】或者【关闭】条件查询的逻辑 ${aos.artistSortType}");
      futureHandler = _audioQuery.queryArtists(
        sortType: aos.artistSortType,
        orderType: aos.orderType,
      );
    }

    return FutureBuilder<List<dynamic>>(
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

        // 得到查询的歌手列表
        List<ArtistModel> artists = item.data! is List<ArtistModel>
            ? item.data! as List<ArtistModel>
            : item.data!.toArtistModel();

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
                    // 在选中指定歌手点击后，进入音频列表，同时监控是否有对音频长按
                    builder: (BuildContext ctx) => MultiProvider(
                      providers: [
                        ListenableProvider<AudioLongPress>(
                          create: (_) => AudioLongPress(),
                        ),
                        ListenableProvider<AudioOptionSelected>(
                          create: (_) => AudioOptionSelected(),
                        ),
                      ],
                      child: LocalMusicAudioListDetail(
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
