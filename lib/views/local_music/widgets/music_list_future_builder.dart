// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/tools.dart';
import '../../../models/audio_long_press.dart';
import '../../../services/my_audio_handler.dart';
import '../../../services/my_audio_query.dart';
import '../../../services/my_shared_preferences.dart';
import '../../../services/service_locator.dart';
import '../nested_pages/just_audio_music_player_detail.dart';

/// 这里是构建音频列表的显示页面
/// 需要传入播放列表类型（如果是歌单还要传入歌单编号，艺术家要传艺术家编号，专辑要传专辑编号……，好像就全部歌曲不用传）
/// 根据不同类型，调用不同查询方法

class MusicListFutureBuilder extends StatefulWidget {
  const MusicListFutureBuilder(
      {super.key,
      required this.audioListType,
      this.audioListId,
      required this.callback});

  final String audioListType;
  final int? audioListId;
  final Function callback;

  @override
  State<MusicListFutureBuilder> createState() => _MusicListFutureBuilderState();
}

class _MusicListFutureBuilderState extends State<MusicListFutureBuilder> {
  // 获取查询音乐组件实例
  final _audioQuery = getIt<MyAudioQuery>();
  // 音乐播放实例
  final _audioHandler = getIt<MyAudioHandler>();
  // 统一简单存储操作的工具类实例
  final _simpleShared = getIt<MySharedPreferences>();

  // 根据不同播放列表类型，构建不同的查询处理
  late Future<List<SongModel>> futureHandler;

  /// 音频多选的操作逻辑：
  /// 长按指定音频，启动播放列表功能模式
  ///     长按标志设为true，选中的音频加入指定列表，显示一些对选中音频的操作功能按钮
  ///     实现针对不同功能按钮
  /// 注意：播放列表为歌单，才有新增到其他歌单、从歌单移除等选择，其他列表因为是on audio query 直接获取到的，功能有些不一样
  ///     需要判断当前的音频列表处于哪一个tab（歌单、全部、艺术家、专辑）的详情
  ///
  /// 注意：因为长按对歌单中音频的操作功能要显示在app bar的位置，所以这个 future Builder和冰岛audio list detail 中去
  ///

  // 被选中的item的索引列表
  List<SongModel> selectedIndexs = [];

  @override
  void initState() {
    super.initState();
    _audioQuery.setLogConfig();
    initFuture();
    // 如果确定在 my audio handle中 _getInitPlaylistAndIndex 有效，这里就不再用了
    // checkPermission();

    print("zzzzzzzzzzzzz------");
  }

  // checkPermission() async {
  //   await _audioQuery.checkAndRequestPermissions(retry: false);
  //   _audioQuery.hasPermission ? setState(() {}) : null;
  // }

  initFuture() async {
    print("传入music list future builder的播放列表类型和编号------------");
    print("${widget.audioListType},,,${widget.audioListId}");

    switch (widget.audioListType) {
      case AudioListTypes.all:
        futureHandler = _audioQuery.querySongs();
        break;
      case AudioListTypes.playlist:
        futureHandler = _audioQuery.queryAudiosFrom(
            AudiosFromType.PLAYLIST, widget.audioListId!);
        break;
      case AudioListTypes.artist:
        futureHandler = _audioQuery.queryAudiosFrom(
            AudiosFromType.ARTIST_ID, widget.audioListId!);
        break;
      case AudioListTypes.album:
        futureHandler = _audioQuery.queryAudiosFrom(
            AudiosFromType.ALBUM_ID, widget.audioListId!);
        break;
      default:
        futureHandler = _audioQuery.querySongs();
    }
  }

  @override
  Widget build(BuildContext context) {
    AudioLongPress alp = context.read<AudioLongPress>();

    // 这个alp.currentTabName可能不太对
    print(
        "1111111111111111111zzzzzzzzzzz ${alp.currentTabName} ${alp.isAddToList} ${widget.audioListType}");

    // 如果是点击了移除被选中的音频，从歌单中移除
    // (注意：暂时只有歌单才有移除，其他几个tab是没有的)
    if (alp.isRemoveFromList) {
      print("执行将选择的音频从歌单移除的逻辑");
      removeSelectedAudionFromPlaylist(alp);
    }
    if (alp.isAddToList) {
      print("执行将选择的音频 添加到歌单的逻辑");
      if (widget.audioListType != AudioListTypes.playlist) {
        addAudioToPlaylist(alp);
      } else {
        addAudioFromPlaylistToPlaylist(alp);
      }
    }
    // 如果是上层使用provide取消了长按标志，这里得清空被选中的数组
    if (!alp.isAudioLongPress) {
      print("执行取消选择的音频的逻辑");
      selectedIndexs.length = 0;
    }

    return Center(
      child: !_audioQuery.hasPermission
          ? noAccessToLibraryWidget()
          : FutureBuilder<List<SongModel>>(
              future: futureHandler,
              builder: (context, item) {
                // 如果查询出错，显示错误信息
                if (item.hasError) {
                  return Text(item.error.toString());
                }
                // 如果还在加载中，显示转圈圈.
                if (item.data == null) {
                  return const CircularProgressIndicator();
                }
                // 如果结果为空，显示无数据
                if (item.data!.isEmpty) return const Text("Nothing found!");

                // 最后就是得到了歌曲列表，统一处理
                List<SongModel> songs = item.data!;

                return ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    // 歌手分类子标题就是专辑名，专辑分类子标题就是歌手
                    var subtext = "";
                    switch (widget.audioListType) {
                      case AudioListTypes.artist:
                        subtext = "专辑: ${songs[index].album}";
                        break;
                      default:
                        subtext = songs[index].artist ?? '未知艺术家';
                    }

                    // 歌曲的时长，格式化为hh:mm:ss 格式
                    var songDurationStr = formatDurationToString(
                      Duration(milliseconds: songs[index].duration!),
                    );

                    return GestureDetector(
                      onLongPress: () {
                        setState(() {
                          // 音频item被长按了，设置标志为被长按，会显示一些操作按钮，且再单击音频是多选，而不是播放
                          alp.changeIsAudioLongPress(true);
                          // 长按的时候把该item索引加入被选中的索引变量中
                          selectedIndexs.add(songs[index]);
                        });
                        widget.callback('I am your sailing child');
                      },
                      child: ListTile(
                        selected: selectedIndexs.contains(songs[index]),
                        title: Text(songs[index].title),
                        subtitle: Text(subtext),
                        trailing: Text(songDurationStr),
                        // 不设置默认为40，需要几乎不占位的leading则需要减少该值
                        minLeadingWidth: 2.sp,
                        // 这个小部件将查询/加载图像。
                        // 因为相关组件的限制，歌单内的音频id不是原始id，无法显示指定的缩略图，所以不显示
                        leading: (widget.audioListType !=
                                AudioListTypes.playlist)
                            ? QueryArtworkWidget(
                                controller: _audioQuery.onAudioQueryController,
                                // ??好像只有querysongs获取到的 SongModel 的id才能找到图片
                                // 其他查询播放列表、艺术家的获取的音频id和querysongs的不一样，也拿不到图片
                                id: songs[index].id,
                                type: ArtworkType.AUDIO,
                              )
                            : SizedBox(
                                height: 2.sp,
                                width: 2.sp,
                              ),
                        onTap: () async {
                          if (alp.isAudioLongPress) {
                            setState(() {
                              // 如果已经加入被选中列表，再次点击则移除
                              if (selectedIndexs.contains(songs[index])) {
                                selectedIndexs.remove(songs[index]);
                              } else {
                                selectedIndexs.add(songs[index]);
                              }
                              // 如果被选中的列表清空，那就假装没有点击长按用于选择音频
                              if (selectedIndexs.isEmpty) {
                                alp.changeIsAudioLongPress(false);
                              }
                            });
                          } else {
                            print(
                                '点击了歌曲${songs[index].title} id是 ${songs[index].id}');
                            print(songs[index].runtimeType);

                            // 到这里就已经查询到当前“全部歌曲”页面中所有的歌曲了，可以构建播放列表和当前音频
                            await _audioHandler.buildPlaylist(
                                songs, songs[index]);
                            await _audioHandler.refreshCurrentPlaylist();

                            // 将播放列表信息、被点击的音频编号\播放列表编号(全部歌曲tab除外)存入持久化
                            await _simpleShared
                                .setCurrentAudioListType(widget.audioListType);
                            await _simpleShared
                                .setCurrentAudioIndex(index.toString());
                            if (widget.audioListType != AudioListTypes.all) {
                              await _simpleShared.setCurrentAudioListId(
                                  widget.audioListId.toString());
                            }

                            if (!mounted) return;
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (BuildContext ctx) {
                                  return const JustAudioMusicPlayer();
                                },
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  // 无访问权限时的占位部件
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

  // 从歌单中移除被选中的音频
  removeSelectedAudionFromPlaylist(AudioLongPress alp) {
    print("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx ${alp.currentTabName}");
    print(selectedIndexs);
    print("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx");
    for (var e in selectedIndexs) {
      _audioQuery.removeFromPlaylist(widget.audioListId!, e.id);
    }

    // 这里我以为是不能保证一定先完成了移除再获取新的歌单音频列表，但结果暂时是正确的
    futureHandler = _audioQuery.queryAudiosFrom(
        AudiosFromType.PLAYLIST, widget.audioListId!);

    // 移除完之后，重置从歌单移除的状态
    Provider.of<AudioLongPress>(context, listen: false)
        .changeIsRemoveFromList(false);
  }

  // 添加被选中的音频到指定歌单
  addAudioToPlaylist(AudioLongPress alp) {
    print(
      "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa ${alp.currentTabName} ${alp.selectedPlaylistId}",
    );
    print(selectedIndexs);
    print("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
    for (var e in selectedIndexs) {
      _audioQuery.addToPlaylist(alp.selectedPlaylistId, e.id);
    }

    // 添加完之后，重置状态
    alp.changeIsAddToList(false);
  }

  // 从歌单中添加到歌单，与其他tab添加到歌单逻辑不同，因为前者的音频id不是原始id，而是重新赋值的id
  addAudioFromPlaylistToPlaylist(AudioLongPress alp) {
    print(
      "aaaaaaaaaaaaaaaaaaddAudioFromPlaylistToPlaylist ${alp.currentTabName} ${alp.selectedPlaylistId}",
    );
    print(selectedIndexs);
    print("aaaaaaaaaaaaaaaaddAudioFromPlaylistToPlaylist");
    for (var e in selectedIndexs) {
      // 选择的音频，通过名称查询到原始音频信息列表
      _audioQuery
          .queryWithFilters(
        e.title,
        WithFiltersType.AUDIOS,
      )
          .then((songs) {
        // 假设同名的歌曲就一首，有多首也只取第一首放入指定歌单
        var song = SongModel(songs[0]);

        _audioQuery.addToPlaylist(alp.selectedPlaylistId, song.id);
      });
    }

    // 添加完之后，重置状态
    alp.changeIsAddToList(false);
  }
}
