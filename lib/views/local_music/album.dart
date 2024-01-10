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
    return Consumer2<ListLongPress, AudioOptionSelected>(
      builder: (context, llp, aos, child) {
        /// 构建专辑列表，需要监测appbar中条件查询变化、排序选项变化，并及时更新显示符合条件的列表

        // 如果是专辑的条件查询
        if (llp.localMusicAppBarSearchInput != null) {
          futureHandler = _audioQuery.queryWithFilters(
            llp.localMusicAppBarSearchInput!,
            WithFiltersType.ALBUMS,
          );
        } else {
          // 如果等于null，说明是初始化，或者关闭了查询按钮，专辑要重新查询所有
          futureHandler = _audioQuery.queryAlbums(
            sortType: aos.albumSortType,
            orderType: aos.orderType,
          );
        }
        return _buildList(context, llp, aos);
      },
    );
  }

  _buildList(BuildContext context, ListLongPress llp, AudioOptionSelected aos) {
    return FutureBuilder<List<dynamic>>(
      future: futureHandler,
      builder: (context, item) {
        // Display error, if any.
        if (item.hasError) {
          return Text(item.error.toString());
        }
        // Waiting content.
        if (item.data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        // 'Library' is empty.
        if (item.data!.isEmpty) {
          return const Center(child: Text("暂无专辑"));
        }

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
              subtitle: Text(
                "${albums[index].numOfSongs} 首歌曲 - ${albums[index].artist}",
              ),
              minLeadingWidth: 100.sp, // 左侧缩略图标的最小宽度
              // 这个小部件将查询/加载图像。
              leading: QueryArtworkWidget(
                controller: _audioQuery.onAudioQueryController,
                // 显示根据专辑id查询的专辑图片
                id: albums[index].id,
                type: ArtworkType.ALBUM,
                artworkBorder: const BorderRadius.all(Radius.zero), // 缩略图不显示圆角
                artworkHeight: 100, // 高度设置无效，实测56，原因不明
                artworkWidth: 100,
                keepOldArtwork: true, // 在生命周期内使用旧的缩略图
                // nullArtworkWidget: const SizedBox.shrink(),
                // 没有缩略图时使用占位图
                nullArtworkWidget: SizedBox(
                  width: 100.sp,
                  child: Image.asset(placeholderImageUrl, fit: BoxFit.fitWidth),
                ),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    // 在选中指定歌单点击后，进入音频列表，同时监控是否有对音频长按
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
