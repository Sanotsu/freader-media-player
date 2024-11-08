import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../common/utils/tool_widgets.dart';
import '../../common/utils/tools.dart';
import '../../services/my_audio_handler.dart';
import '../../services/service_locator.dart';
import '../common_widget/cus_gallery_viewer/index.dart';
import '../common_widget/image_item_widget.dart';
import '../common_widget/show_media_info_dialog.dart';
import '../common_widget/cus_video_player/index.dart';
import '../local_music/nested_pages/just_audio_music_player_detail.dart';

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

  // 文件夹中的可以解析的文件
  List<AssetEntity> _supportedList = [];

  // 被选中的文件索引
  var selectedEntityIndexes = [];

  // 点击某个音频文件时，需要使用这个单例的音频控制器
  final _audioHandler = getIt<MyAudioHandler>();

  // 指定相册内部文件可以列表展示和网格展示，网格展示要有缩略图
  bool isGridMode = false;

  // 这里指定文件夹下的条目点击后会创建对应的播放列表，但构建过程可能需要耗时，避免重复点击，点过之后旧显示转圈
  bool isListLoading = false;
  OverlayEntry? overlayEntry;

  @override
  void initState() {
    super.initState();
    initPathAssets();
  }

  // 获取指定文件夹中的媒体文件
  Future<void> initPathAssets() async {
    final count = await widget.path.assetCountAsync;
    if (count == 0) return;

    // 查询所有媒体实体列表（起止参数表示可以过滤只显示排序后中某一部分实体）
    final list = await widget.path.getAssetListRange(start: 0, end: count);

    // 2024-10-30 先排序，可解析的排在前面；都可解析则按标题升序排
    list.sort((a, b) {
      if (a.type != AssetType.image && b.type != AssetType.image) {
        // 先判断 duration 是否大于 0
        if (a.duration > 0 && b.duration > 0) {
          // 如果都大于 0，则按 title 升序排序
          return (a.title ?? '').compareTo(b.title ?? '');
        } else if (a.duration > 0) {
          // 如果 a 的 duration 大于 0，则 a 在前
          return -1;
        } else if (b.duration > 0) {
          // 如果 b 的 duration 大于 0，则 b 在前
          return 1;
        } else {
          // 如果都等于 0，则按 title 升序排序
          return (a.title ?? '').compareTo(b.title ?? '');
        }
      } else {
        // 如果是图片，则标题升序
        return (a.title ?? '').compareTo(b.title ?? '');
      }
    });

    if (!mounted) return;
    setState(() {
      // 全部的文件
      _list = list;

      // 2024-10-29 可解析的文件
      // 直接过滤无法解析的视频音频(时长duration为0的)
      _supportedList = list
          .where((c) => !(c.type != AssetType.image && c.duration == 0))
          .toList();
    });
  }

  // 这里指定文件夹下的条目点击后会创建对应的播放列表，但构建过程可能需要耗时，避免重复点击，点过之后旧显示转圈
  // 传true就构建加载圈；传false就取消
  void toggleLoading(bool isLoading) {
    // 如果已经有加载圈了，则直接返回
    if (isLoading && isListLoading) {
      return;
    }

    setState(() {
      isListLoading = isLoading;
    });

    if (isLoading) {
      overlayEntry = OverlayEntry(
        builder: (context) => Stack(
          children: [
            const Positioned.fill(
              child: AbsorbPointer(
                absorbing: true, // 禁用底部内容的点击操作
                child: ModalBarrier(
                  color: Color.fromARGB(137, 175, 158, 158),
                  dismissible: false,
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height / 2 - 50.sp,
              left: MediaQuery.of(context).size.width / 2 - 50.sp,
              child: Container(
                width: 150.sp,
                height: 150.sp,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(137, 161, 153, 153),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 10.sp),
                    Text(
                      '当前路径资源较多',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.sp,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    Text(
                      '播放列表构建中...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.sp,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

      Overlay.of(context).insert(overlayEntry!);
    } else {
      overlayEntry?.remove();
      overlayEntry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 无法解析的媒体资源数量
    int unsupportedNum = _list.length - _supportedList.length;
    var exStr = "";
    if ((unsupportedNum > 0)) {
      exStr = "(其中 $unsupportedNum 个资源无法解析)";
    }

    return Scaffold(
      /// 构建标题工具栏(没有条目被长按选择则不显示功能按钮)
      appBar: AppBar(
        title: selectedEntityIndexes.isNotEmpty
            ? Text("${selectedEntityIndexes.length}/${_list.length}")
            : Text(widget.path.name),
        actions: <Widget>[
          if (selectedEntityIndexes.isNotEmpty)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  tooltip: '查看信息',
                  onPressed: () {
                    buildSelectedItemInfoDialog();
                  },
                )
              ],
            ),
          if (selectedEntityIndexes.isNotEmpty)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.cancel_outlined),
                  tooltip: '取消选中',
                  onPressed: () {
                    setState(() {
                      selectedEntityIndexes.length = 0;
                    });
                  },
                )
              ],
            ),
          // 列表或网格的切换
          IconButton(
            onPressed: () {
              setState(() {
                isGridMode = !isGridMode;
                // 显示切换时也取消选中
                selectedEntityIndexes.length = 0;
              });
            },
            icon: isGridMode
                ? const Icon(Icons.list)
                : const Icon(Icons.grid_3x3),
          ),
        ],
      ),
      body: Column(
        children: [
          Text("共${_list.length}个资源$exStr"),
          Divider(height: 1.sp),
          Expanded(
            child: isGridMode ? buildEntityGrid() : buildEntityList(),
          ),
        ],
      ),
    );
  }

  /// 构建媒体文件预览的grid列表
  buildEntityGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: _list.length,
      itemBuilder: (context, index) {
        final entity = _list[index];

        return Container(
          // 加一个边框避免音频没有缩略图不好看
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).disabledColor,
            ),
          ),
          child: GestureDetector(
            // 2024-01-23 这里的音频文件取不到封面之类的，就显示图标和标题
            onTap: (entity.type != AssetType.image && entity.duration == 0)
                ? null
                : () => buildItemOnTap(entity, index),
            onLongPress: () {
              setState(() {
                selectedEntityIndexes.add(index);
              });
            },
            // 2024-01-23 这里的音频文件取不到封面之类的，就显示图标和标题
            child: (entity.type == AssetType.audio)
                ? Column(
                    children: [
                      Expanded(
                        child: Icon(
                          Icons.audiotrack,
                          size: 18.sp,
                          color: entity.duration == 0 ? Colors.grey : null,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entity.title ?? "",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: entity.duration == 0 ? Colors.grey : null,
                          ),
                        ),
                      ),
                    ],
                  )
                : ImageItemWidget(
                    entity: entity,
                    option: ThumbnailOption.ios(
                      size: const ThumbnailSize.square(500),
                    ),
                    isLongPress:
                        selectedEntityIndexes.contains(index) ? true : false,
                  ),
          ),
        );
      },
    );
  }

  /// 构建媒体文件预览的list列表
  buildEntityList() {
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
            style: TextStyle(
              color: (entity.type != AssetType.image && entity.duration == 0)
                  ? Colors.grey
                  : null,
            ),
          ),
          subtitle: Text(
            entity.type.toString(),
            style: TextStyle(
              color: (entity.type != AssetType.image && entity.duration == 0)
                  ? Colors.grey
                  : null,
            ),
          ),
          leading: SizedBox(
            height: 36.sp,
            width: 48.sp,
            child: ImageItemWidget(
              entity: entity,
              option: ThumbnailOption.ios(
                size: const ThumbnailSize.square(500),
              ),
              isLongPress: selectedEntityIndexes.contains(index) ? true : false,
            ),
          ),
          trailing: SizedBox(
            width: 32.sp,
            child: IconButton(
              onPressed: () {
                showMediaInfoDialog(entity, context);
              },
              icon: Icon(
                Icons.info_outline,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          onTap: (entity.type != AssetType.image && entity.duration == 0)
              ? null
              : () {
                  buildItemOnTap(entity, index);
                },
          onLongPress: () {
            setState(() {
              selectedEntityIndexes.add(index);
            });
          },
          // 列表形态时，被长按选中的就改变被选中的颜色和状态
          selected: selectedEntityIndexes.contains(index),
          selectedColor: Theme.of(context).primaryColor,
        );
      },
    );
  }

  // 条目被点击的操作，要区分是否已经有长按了
  buildItemOnTap(AssetEntity entity, int index) async {
    // 如果已经处于长按状态，点击则为添加多选
    if (selectedEntityIndexes.isNotEmpty) {
      setState(() {
        // 如果已经选中了，再点则为移除选中
        if (selectedEntityIndexes.contains(index)) {
          selectedEntityIndexes.remove(index);
        } else {
          selectedEntityIndexes.add(index);
        }
      });
    } else {
      // 如果是音频或者视频，需要构建播放列表，需要耗费一些时间；
      // 避免重复点击浪费更多时间，所以要显示加载圈
      toggleLoading(true);

      // 2024-01-23 点击某一个视频，进入播放列表，轮播视频
      if (entity.type == AssetType.video) {
        // 如果视频文件存在才进行进入播放页面等其他操作
        if ((await entity.file) != null) {
          List<AssetEntity> videoEneities =
              _supportedList.where((e) => e.type == AssetType.video).toList();
          // 找到点击的视频在过滤后的视频列表中的索引
          var currentVideoIndex =
              videoEneities.indexWhere((f) => f.id == entity.id);

          if (!mounted) return;
          if (currentVideoIndex < 0) {
            showSnackMessage(context, "没找到对应点击的视频");
            toggleLoading(false);
            return;
          }

          // 2024-01-17 如果点击的视频获取不到长度，就不进入播放页面
          // 理论上没有，因为进入页面初始化时就过滤掉了不可播放的视频
          if (entity.videoDuration == Duration.zero) {
            commonExceptionDialog(
              context,
              "提示",
              """无法解析该视频\n
  【格式】${getSpecificExtension(entity.title ?? '')}
  【名称】${entity.title}""",
              msgFontSize: 15.sp,
            );
            toggleLoading(false);
            return;
          }

          toggleLoading(false);

          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext ctx) {
                // 这里轮播当前路径下的所有符合条件的视频文件。
                return CusVideoPlayer(
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
          toggleLoading(false);
          return;
        }
      } else if (entity.type == AssetType.image) {
        // 2024-01-23 目前暂时点击某一个图片，会滑动上/下一张，略过视频
        List<AssetEntity> imageEneities =
            _supportedList.where((e) => e.type == AssetType.image).toList();
        // 找到点击的视频在过滤后的视频列表中的索引
        var currentImageIndex =
            imageEneities.indexWhere((f) => f.id == entity.id);

        /// ??? 理论上也应该和视频一样进行一些判断，暂时略过
        toggleLoading(false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CusGalleryViewer(
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
        // 如果视频文件存在才进行进入播放页面等其他操作
        if ((await entity.file) != null) {
          List<AssetEntity> audioEneities =
              _supportedList.where((e) => e.type == AssetType.audio).toList();
          // 找到点击的视频在过滤后的视频列表中的索引
          var currentAudioIndex =
              audioEneities.indexWhere((f) => f.id == entity.id);

          if (!mounted) return;
          if (currentAudioIndex < 0) {
            showSnackMessage(context, "没找到对应点击的音频");
            toggleLoading(false);
            return;
          }

          // 2024-01-17 如果点击的视频获取不到长度，就不进入播放页面
          // 理论上没有，因为进入页面初始化时就过滤掉了不可播放的视频
          if (entity.duration <= 0) {
            // 2024-10-29 可能存在像酷狗音乐下载的加密后的音频，比如xxx.kgm.flac，
            // 咋看还以为是不支持audio/flac格式，实际是不支持.kgm.xxx
            commonExceptionDialog(
              context,
              "提示",
              """无法解析该音频
  【格式】${getSpecificExtension(entity.title ?? '')}
  【名称】${entity.title}""",
              msgFontSize: 15.sp,
            );
            toggleLoading(false);
            return;
          }

          /// 2024-01-23 还是使用全局的音频播放器来播放，歌单就是当前路径下的所有音频文件。
          await _audioHandler.buildPlaylistByAssetEntity(
            audioEneities,
            currentAudioIndex,
          );
          //
          /// 2024-01-23 实际测试，如果歌曲特别多，好像也很慢，暂时就只播放当前那首
          // await _audioHandler.buildPlaylistByAssetEntity([entity], 0);
          await _audioHandler.refreshCurrentPlaylist();

          toggleLoading(false);
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext ctx) {
                return const JustAudioMusicPlayer();
              },
            ),
          );
        } else {
          // 如果音频文件不存在，提示
          if (!mounted) return;
          commonExceptionDialog(
            context,
            "提示",
            "找不到音频文件: ${entity.title}",
          );
          toggleLoading(false);
          return;
        }
      } else {
        //  点击的既不是图片也不是音频、视频，不做任何操作;
        toggleLoading(false);

        showSnackMessage(
          context,
          "点击的不是图片、音频或视频:${entity.title}-${entity.type}",
        );
        return;
      }
    }
  }

  /// 长按可以多选，多选后可以查看选中的信息
  buildSelectedItemInfoDialog() async {
    // 单个文件就显示文件属性
    if (selectedEntityIndexes.length == 1) {
      showMediaInfoDialog(_list[selectedEntityIndexes[0]], context);

      setState(() {
        selectedEntityIndexes.length = 0;
      });
      return;
    }

    // 多个就只显示选中的数量和体积
    List<AssetEntity> selectedEntities =
        selectedEntityIndexes.map((index) => _list[index]).toList();

    // 计算被选中的媒体资源的总大小
    var totalSize = 0;
    for (var e in selectedEntities) {
      totalSize += (await e.file)?.statSync().size ?? 0;
    }

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("属性", textAlign: TextAlign.start),
          content: SizedBox(
            height: 150.sp,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 如果是多选了视频文件，则只显示文件数量和总大小
                ListTile(
                  title: const Text("总数量"),
                  subtitle: Text("${selectedEntityIndexes.length}"),
                ),
                ListTile(
                  title: const Text("总大小"),
                  subtitle: Text(
                    "${getFileSize(totalSize, 2)} ($totalSize Byte)",
                  ),
                )
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('确认'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).then((value) {
      // 关闭弹窗，取消选中
      setState(() {
        selectedEntityIndexes.length = 0;
      });
    });
  }
}
