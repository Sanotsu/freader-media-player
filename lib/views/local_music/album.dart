// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../../common/global/constants.dart';
import '../../models/audio_long_press.dart';
import '../../models/list_long_press.dart';
import '../../services/my_audio_query.dart';
import '../../services/service_locator.dart';
import 'nested_pages/audio_list_detail.dart';

class LocalMusicAlbum extends StatefulWidget {
  const LocalMusicAlbum({super.key});

  @override
  State<LocalMusicAlbum> createState() => _LocalMusicAlbumState();
}

class _LocalMusicAlbumState extends State<LocalMusicAlbum> {
  // 获取查询音乐组件实例
  final _audioQuery = getIt<MyAudioQuery>();

  // 根据不同专辑类型(默认的查询所有专辑或者条件查询专辑)，构建不同的查询处理
  late Future<List<dynamic>> futureHandler;

  @override
  Widget build(BuildContext context) {
    return Consumer<ListLongPress>(
      builder: (context, llp, child) {
        print(
          "localmusic index 下album中 ${llp.isPlaylistLongPress} ${llp.selectedPlaylistList.length} ${llp.localMusicAppBarSearchInput}",
        );

        /// 如果是在播放列表中对某音频进行了长按，则在此处显示一些功能按钮
        ///   暂时有：查看信息、从当前列表移除、三个点（添加到播放列表、添加到队列(这个暂不实现)、全选等）
        /// 如果是默认显示的，应该有：排序、搜索、三个点（展开其他功能）
        return _buildList(context, llp);
      },
    );
  }

  _buildList(BuildContext context, ListLongPress llp) {
    // 如果是主页上歌单的条件查询
    if (llp.localMusicAppBarSearchInput != null) {
      print("执行了条件查询的逻辑");
      futureHandler = _audioQuery.queryWithFilters(
        llp.localMusicAppBarSearchInput!,
        WithFiltersType.ALBUMS,
      );
    } else {
      // 如果等于null，说明是初始化，或者关闭了查询按钮，歌单要重新查询所有
      print("执行了【歌单初始化】或者【关闭】条件查询的逻辑");
      futureHandler = _audioQuery.queryAlbums();
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

        // 得到查询的专辑列表
        List<AlbumModel> albums = item.data! is List<AlbumModel>
            ? item.data! as List<AlbumModel>
            : item.data!.toAlbumModel();

        return ListView.builder(
          itemCount: albums.length,
          itemExtent: 80.sp, // 每个item内部组件的高度
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(albums[index].album),
              subtitle: Text("${albums[index].numOfSongs.toString()} 首歌曲"),
              minLeadingWidth: 100.sp, // 左侧缩略图标的最小宽度
              // 这个小部件将查询/加载图像。
              leading: QueryArtworkWidget(
                controller: _audioQuery.onAudioQueryController,
                // 显示根据专辑id查询的专辑图片
                id: albums[index].id,
                type: ArtworkType.ALBUM,
                artworkBorder: const BorderRadius.all(Radius.zero), // 缩略图不显示圆角
              ),
              onTap: () {
                print(
                  '指定专辑 ${albums[index].artist}  was tapped! id Is ${albums[index].id}',
                );

                Navigator.of(context).push(
                  MaterialPageRoute(
                    // 在选中指定歌单点击后，进入音频列表，同时监控是否有对音频长按
                    builder: (BuildContext ctx) => ListenableProvider(
                      create: (ctx) => AudioLongPress(),
                      builder: (context, child) => LocalMusicAudioListDetail(
                        audioListType: AudioListTypes.album,
                        audioListId: albums[index].id,
                        audioListTitle: albums[index].album,
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
