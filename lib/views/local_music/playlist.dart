// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:freader_music_player/models/list_long_press.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../../common/global/constants.dart';
import '../../models/audio_long_press.dart';
import '../../services/my_audio_query.dart';
import '../../services/service_locator.dart';
import 'nested_pages/audio_list_detail.dart';

class LocalMusicPlaylist extends StatefulWidget {
  const LocalMusicPlaylist({super.key, this.queryInputted});

  // 2023-04-14 如果是主页面“全部”tab的查询结果，可能把查询条件传过来。如果有，则用它；没有，才使用initFuture。
  final String? queryInputted;

  @override
  State<LocalMusicPlaylist> createState() => _LocalMusicPlaylistState();
}

class _LocalMusicPlaylistState extends State<LocalMusicPlaylist> {
  // 获取查询音乐组件实例
  final _audioQuery = getIt<MyAudioQuery>();

  // 根据不同播放列表类型，构建不同的查询处理
  late Future<List<dynamic>> futureHandler;

  // 被选中的item的索引列表
  List<PlaylistModel> selectedPlaylists = [];

  @override
  void initState() {
    super.initState();
    // initData();
  }

  /*
  【这个后续可以不要，因为llp中localMusicAppBarSearchInput==null时会执行查询所有歌单，
  而初始化或者关闭查询框时，该值都为null】
  */
  initData() async {
    print("在歌单列表的init中，传入的widget.queryInputted:${widget.queryInputted}|");

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
      "1",
      WithFiltersType.PLAYLISTS,
    );

    // 插件原始函数有bug
    // await _audioQuery.renamePlaylist(201060, "新名字");

    print("000000000000000000000000000000");
    print(plist2);
    print(songs);
    print(songs2);
    print("000000000000000000000000000000 ${SongModel(songs2[0])}");
    //
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ListLongPress>(
      builder: (context, llp, child) {
        print(
          "localmusic index 下playlist中 ${llp.isPlaylistLongPress} ${llp.selectedPlaylistList.length} ${llp.localMusicAppBarSearchInput}",
        );

        /// 如果是在播放列表中对某音频进行了长按，则在此处显示一些功能按钮
        ///   暂时有：查看信息、从当前列表移除、三个点（添加到播放列表、添加到队列(这个暂不实现)、全选等）
        /// 如果是默认显示的，应该有：排序、搜索、三个点（展开其他功能）
        return _buildList(context, llp);
      },
    );
    // return _buildList(context);
  }

  _buildList(BuildContext context, ListLongPress llp) {
    // 如果是上层使用provide取消了长按标志，这里得清空被选中的数组
    // 但是默认就是false，是不是初始化的时候也会进来？
    if (llp.isPlaylistLongPress == LongPressStats.NO) {
      print("执行取消选择的歌单的逻辑");
      selectedPlaylists.length = 0;
      // 取消歌单长按，有可能是删除了歌单，那么需要刷新一下歌单数据
      futureHandler = _audioQuery.queryPlaylists();
      // 取消完之后重新查询了歌单，则修改状态为初始化
      llp.changeIsPlaylistLongPress(LongPressStats.INIT);
    }

    // 如果是主页上歌单的条件查询
    if (llp.localMusicAppBarSearchInput != null) {
      print("执行了条件查询的逻辑");
      futureHandler = _audioQuery.queryWithFilters(
        llp.localMusicAppBarSearchInput!,
        WithFiltersType.PLAYLISTS,
      );
    } else {
      // 如果等于null，说明是初始化，或者关闭了查询按钮，歌单要重新查询所有
      print("执行了【歌单初始化】或者【关闭】条件查询的逻辑");
      futureHandler = _audioQuery.queryPlaylists();
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

        // 得到查询的歌单列表
        List<dynamic> playlists = item.data!;

        print(
          "在playlist.dart页面中得到的List<PlaylistModel> playlists ${llp.localMusicAppBarSearchInput} ${item.data!.runtimeType} ${item.data!}",
        );

        return ListView.builder(
          itemCount: playlists.length,
          itemBuilder: (ctx, index) {
            // PlaylistModel playlist = playlists[index];

            // 因为 queryWithFilters 查询 playlist的时候有bug，没有 numOfSongs 属性。所以转为PlaylistModel会报错
            // 所以关于playlist的取值，都转为map，然后用中括号获取id属性。
            // 然后使用 queryAudiosFrom() 方法，获取到缺少的 numOfSongs，补充到该map中。
            // 最后使用 PlaylistModel的构造函数，把map还原为PlaylistModel类型。
            var playlistMap = (playlists[index] is PlaylistModel)
                ? (playlists[index]).getMap
                : (playlists[index]);

            var playlistId = playlistMap["_id"];

            /*
              因为 queryWithFilters 查询 playlist的时候有bug，没有 numOfSongs 属性。所以条件查询时没法显示。
              正常查询的:
              {_data: /storage/emulated/0/Playlists/示例歌单1}, 
              date_added: 1680760896, date_modified: 1680760896, num_of_songs: 5, name: 示例歌单1}, _id: 201059}
              queryWithFilter的：
              {_data: /storage/emulated/0/Playlists/示例歌单1}, 
              date_added: 1680760896, date_modified: 1680760896, name: 示例歌单1}, _id: 201059}

              为了显示，这里再查询该指定歌单中音频的数据来获取该值进行渲染。
              但不能在listview的builder中使用async或者then，所以再嵌套一层FutureBuilder，且统一该值从查询的结果取而不是playlist的属性
            */
            return FutureBuilder<List<SongModel>>(
                future: _audioQuery.queryAudiosFrom(
                    AudiosFromType.PLAYLIST, playlistId),
                builder: (ctx, i) {
                  if (i.hasError) return Text(i.error.toString());
                  if (i.data == null) return const CircularProgressIndicator();
                  if (i.data!.isEmpty) return const Text("歌曲 Nothing found!");
                  // 查询到的指定歌单的音频数据，用于获取缺少的num_of_songs属性
                  var tempSongs = i.data!;

                  PlaylistModel playlist;

                  // 因为 queryWithFilters 查询 playlist的时候有bug，没有 numOfSongs 属性。所以转为PlaylistModel会报错
                  // 所以关于playlist的取值，如果不是PlaylistModel类型，则转为map，补上缺少的属性，再手动转回该类型。
                  if (playlists[index] is! PlaylistModel) {
                    var tempMap = Map<dynamic, dynamic>.from(playlists[index]);
                    tempMap.putIfAbsent("num_of_songs", () => tempSongs.length);
                    playlist = PlaylistModel(tempMap);
                  } else {
                    playlist = playlists[index];
                  }

                  print(
                    '转为map之后再取值${playlist.runtimeType} $playlist-${playlist.playlist}',
                  );

                  return ListTile(
                    selected: selectedPlaylists
                        .where((e) => e.id == playlist.id)
                        .isNotEmpty,
                    title: Text(playlist.playlist),
                    subtitle: Text("${playlist.numOfSongs} 首歌曲"),
                    // 歌单可以不要缩略图，反2.7.0的相关组件依赖也查不到原始音频id
                    // leading: QueryArtworkWidget(
                    //   controller: _audioQuery.onAudioQueryController,
                    //   // 显示根据歌手id查询的歌手图片
                    //   id: playlistId,
                    //   type: ArtworkType.PLAYLIST,
                    //   artworkBorder: const BorderRadius.all(Radius.zero), // 缩略图不显示圆角
                    // ),
                    leading: SizedBox(height: 50.sp, width: 50.sp),
                    onLongPress: () {
                      setState(() {
                        // 修改歌单长按标志为true
                        llp.changeIsPlaylistLongPress(LongPressStats.YES);
                        selectedPlaylists.add(playlist);
                        llp.changeSelectedPlaylists(selectedPlaylists);
                      });
                    },
                    onTap: () {
                      if (llp.isPlaylistLongPress == LongPressStats.YES) {
                        setState(() {
                          // 如果已经加入被选中列表，再次点击则移除
                          // 2023-04-17 之前不管是上面判断selected状态还是这里判断要移除或者添加，都是contains方法，现在不生效了
                          if (selectedPlaylists
                              .where((e) => e.id == playlist.id)
                              .isNotEmpty) {
                            // 这里移除直接remove也不生效了
                            // selectedPlaylists.remove(playlist);
                            selectedPlaylists
                                .removeWhere((e) => e.id == playlist.id);
                          } else {
                            selectedPlaylists.add(playlist);
                            print(
                              "selectedPlaylists===============$selectedPlaylists",
                            );
                          }
                          // 如果被选中的列表清空，那就假装没有点击长按用于选择音频
                          if (selectedPlaylists.isEmpty) {
                            print("8888888加载页面置为空？");
                            llp.changeIsPlaylistLongPress(LongPressStats.INIT);
                          }

                          // 不管如何，点击了，就要更新被选中的歌单列表
                          llp.changeSelectedPlaylists(selectedPlaylists);
                        });
                      } else {
                        print(
                          '指定歌单 ${playlist.playlist}  was tapped! id Is ${playlist.id}',
                        );

                        // final AudioInList yourModel =
                        //     Provider.of<AudioInList>(context, listen: false);

                        Navigator.of(ctx)
                            .push(
                              MaterialPageRoute(
                                // 在选中指定歌单点击后，进入音频列表，同时监控是否有对音频长按
                                builder: (BuildContext ctx) =>
                                    ListenableProvider(
                                  create: (ctx) => AudioLongPress(),
                                  builder: (context, child) =>
                                      LocalMusicAudioListDetail(
                                    audioListType: AudioListTypes.playlist,
                                    audioListId: playlist.id,
                                    audioListTitle: playlist.playlist,
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
                      }
                    },
                  );
                });
          },
        );
      },
    );
  }
}
