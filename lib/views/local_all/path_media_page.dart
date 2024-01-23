// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';

import 'dart:io';

import '../../common/utils/tool_widgets.dart';
import '../../services/my_audio_handler.dart';
import '../../services/service_locator.dart';
import '../local_media/widgets/image_item_widget.dart';

import '../local_music/nested_pages/just_audio_music_player_detail.dart';
import 'cus_image_viewer/cus_viewer.dart';
import 'cus_video_player/cus_player.dart';

class PathMediaPage extends StatefulWidget {
  const PathMediaPage({super.key, required this.path, required this.pathList});

  // 当前浏览的媒体文件属于哪一个文件夹
  final AssetPathEntity path;
  // 手机里一共找到哪些有媒体文件的文件夹（列表）
  final List<AssetPathEntity> pathList;

  @override
  State<PathMediaPage> createState() => _PathMediaPageState();
}

class _PathMediaPageState extends State<PathMediaPage> {
  // 文件夹中的文件
  List<AssetEntity> _list = [];
  // 被选中的文件索引
  var selectedCards = [];

  final _audioHandler = getIt<MyAudioHandler>();

  // 指定相册内部文件可以列表展示和网格展示，网格展示要有缩略图
  bool isGridMode = true;

  @override
  void initState() {
    super.initState();
    initPathAssets();
  }

  // 获取指定文件夹中的媒体文件
  Future<void> initPathAssets() async {
    final count = await widget.path.assetCountAsync;
    if (count == 0) {
      return;
    }

    print("这只指定文件夹${widget.path.name}中的数量$count");
    // 查询所有媒体实体列表（起止参数表示可以过滤只显示排序后中某一部分实体）
    final list = await widget.path.getAssetListRange(start: 0, end: count);
    setState(() {
      if (mounted) _list = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// 构建标题工具栏(没有条目被长按选择则不显示功能按钮)
      appBar: AppBar(
        title: selectedCards.isNotEmpty
            ? Text("${selectedCards.length}/${_list.length}")
            : Text(widget.path.name),
        actions: <Widget>[
          selectedCards.isNotEmpty
              ? Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.cancel),
                      tooltip: '取消选中',
                      onPressed: () {
                        setState(() {
                          selectedCards.length = 0;
                        });
                      },
                    )
                  ],
                )
              : Container(),
          // 列表或网格的切换
          IconButton(
            onPressed: () {
              setState(() {
                isGridMode = !isGridMode;
              });
            },
            icon: isGridMode
                ? const Icon(Icons.list)
                : const Icon(Icons.grid_3x3),
          ),
        ],
      ),
      body: isGridMode ? _buildGridItem() : _buildList(),
    );
  }

  /// 构建媒体文件预览的grid列表
  _buildGridItem() {
    GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: _list.length,
      itemBuilder: (ctx, index) {
        final entity = _list[index];
        return GestureDetector(
          // 2024-01-23 这里的音频文件取不到封面之类的，就显示图标和标题
          child: (entity.type == AssetType.audio)
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.audiotrack, size: 18.sp),
                    Text(
                      entity.title ?? "",
                      style: TextStyle(fontSize: 10.sp),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                )
              : ImageItemWidget(
                  entity: entity,
                  option: ThumbnailOption.ios(
                    size: const ThumbnailSize.square(500),
                  ),
                  isLongPress: selectedCards.contains(index) ? true : false,
                ),
          onTap: () {
            itemOnTap(entity, index);
          },
          onLongPress: () {
            print("使用了长按");
            setState(() {
              selectedCards.add(index);
            });
          },
        );
      },
    );
  }

  _buildList() {
    return ListView.builder(
      itemCount: _list.length,
      itemBuilder: (BuildContext context, int index) {
        // 相册和文件夹的抽象化。
        // 它代表了Android上的 "MediaStore"中的一个buket，
        // 以及iOS/MacOS上的 "PHAssetCollection"对象。
        final AssetEntity entity = _list[index];

        return ListTile(
          title: Text(
            entity.title ?? "",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(entity.type.toString()),
          leading: ImageItemWidget(
            entity: entity,
            option: ThumbnailOption.ios(
              size: const ThumbnailSize.square(500),
            ),
            isLongPress: selectedCards.contains(index) ? true : false,
          ),
          onTap: () {
            itemOnTap(entity, index);
          },
          onLongPress: () {
            print("使用了长按");
            setState(() {
              selectedCards.add(index);
            });
          },
        );
      },
    );
  }

  itemOnTap(AssetEntity entity, int index) async {
    // 如果已经处于长按状态，点击则为添加多选
    if (selectedCards.isNotEmpty) {
      print(
        "图片中点击了 $index $selectedCards ${entity.title} 要添加或者移除",
      );
      setState(() {
        // 如果已经选中了，再点则为移除选中
        if (selectedCards.contains(index)) {
          selectedCards.remove(index);
        } else {
          selectedCards.add(index);
        }
      });
    } else {
      print(
        "图片中点击了 ${entity.title} ${entity.type} ${entity.originFile} 要播放或者显示",
      );

      // 2024-01-23 点击某一个视频，进入播放列表，轮播视频
      if (entity.type == AssetType.video) {
        File? tempFile = await entity.file;

        // 如果视频文件存在才进行进入播放页面等其他操作
        if (tempFile != null) {
          List<AssetEntity> videoEneities =
              _list.where((e) => e.type == AssetType.video).toList();
          // 找到点击的视频在过滤后的视频列表中的索引
          var currentVideoIndex =
              videoEneities.indexWhere((f) => f.id == entity.id);

          if (!mounted) return;
          if (currentVideoIndex < 0) {
            showSnackMessage(context, "没找到对应点击的视频");
            return;
          }

          // 2024-01-17 如果点击的视频获取不到长度，就不进入播放页面
          // 理论上没有，因为进入页面初始化时就过滤掉了不可播放的视频
          if (entity.videoDuration == Duration.zero) {
            commonExceptionDialog(
              context,
              "提示",
              "不支持的视频格式: ${entity.mimeType}",
            );
            return;
          }

          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext ctx) {
                // 这里轮播当前路径下的所有符合条件的视频文件。
                return CusPlayer(
                  entities: videoEneities,
                  index: currentVideoIndex,
                );
              },
            ),
          );
        } else {
          // 如果视频文件不存在，提示
          if (!mounted) return;
          commonExceptionDialog(
            context,
            "提示",
            "找不到视频文件: ${entity.title}",
          );
          return;
        }
      } else if (entity.type == AssetType.image) {
        // 2024-01-23 目前暂时点击某一个图片，会滑动上/下一张，略过视频
        List<AssetEntity> imageEneities =
            _list.where((e) => e.type == AssetType.image).toList();
        // 找到点击的视频在过滤后的视频列表中的索引
        var currentImageIndex =
            imageEneities.indexWhere((f) => f.id == entity.id);

        /// ??? 理论上也应该和视频一样进行一些判断，暂时略过
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CusViewer(
              galleryItems: imageEneities,
              backgroundDecoration: const BoxDecoration(
                color: Colors.black,
              ),
              initialIndex: currentImageIndex,
              scrollDirection: Axis.horizontal,
            ),
          ),
        );
      } else if (entity.type == AssetType.audio) {
        // ??? 理论上应该video player可以播放的，实际好像有点问题
        // 这个是单个音频播放试一下

        File? tempFile = await entity.file;

        // 如果视频文件存在才进行进入播放页面等其他操作
        if (tempFile != null) {
          List<AssetEntity> audioEneities =
              _list.where((e) => e.type == AssetType.audio).toList();
          // 找到点击的视频在过滤后的视频列表中的索引
          var currentAudioIndex =
              audioEneities.indexWhere((f) => f.id == entity.id);

          if (!mounted) return;
          if (currentAudioIndex < 0) {
            showSnackMessage(context, "没找到对应点击的音频");
            return;
          }

          // 2024-01-17 如果点击的视频获取不到长度，就不进入播放页面
          // 理论上没有，因为进入页面初始化时就过滤掉了不可播放的视频
          if (entity.duration <= 0) {
            commonExceptionDialog(
              context,
              "提示",
              "不支持的音频格式: ${entity.mimeType}",
            );
            return;
          }

          /// 2024-01-23 还是使用全局的音频播放器来播放，歌单就是当前路径下的所有音频文件。
          // await _audioHandler.buildPlaylistByAssetEntity(
          //   audioEneities,
          //   currentAudioIndex,
          // );
          //
          /// 2024-01-23 实际测试，如果歌曲特别多，好像也很慢，暂时就只播放当前那首
          await _audioHandler.buildPlaylistByAssetEntity([entity], 0);
          await _audioHandler.refreshCurrentPlaylist();

          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext ctx) {
                return const JustAudioMusicPlayer();
              },
            ),
          );

          /// 2024-01-23 本来这个视频播放器应该可以播放音频的，但没有成功
          // Navigator.of(ctx).push(
          //   MaterialPageRoute(
          //     builder: (BuildContext ctx) {
          //       // 这里轮播当前路径下的所有符合条件的视频文件。
          //       return CusPlayer(
          //         entities: audioEneities,
          //         index: currentAudioIndex,
          //       );
          //     },
          //   ),
          // );

          /// 2024-01-23 本来想写一个简单的音频播放页面，只播放选择的音频，播完就返回，退出播放页面就停止的，但有点问题
          // if (!mounted) return;
          // Navigator.of(context).push(
          //   MaterialPageRoute(
          //     builder: (BuildContext ctx) {
          //       return CusAudioPlayer(audio: entity);
          //     },
          //   ),
          // );
        } else {
          // 如果音频文件不存在，提示
          if (!mounted) return;
          commonExceptionDialog(
            context,
            "提示",
            "找不到音频文件: ${entity.title}",
          );
          return;
        }
      } else {
        print("点击的既不是图片也不是音频、视频:${entity.title}-${entity.type}");
      }
    }
  }
}
