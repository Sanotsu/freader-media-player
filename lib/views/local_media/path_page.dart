// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'dart:io';

import 'screen/image_viewer_screen.dart';
import 'screen/video_player_screen.dart';
import 'widgets/image_item_widget.dart';

class PathPage extends StatefulWidget {
  const PathPage({Key? key, required this.path}) : super(key: key);
  final AssetPathEntity path;

  @override
  State<PathPage> createState() => _PathPageState();
}

class _PathPageState extends State<PathPage> {
  // 文件夹中的文件
  List<AssetEntity> _list = [];
  // 被选中的文件索引
  var selectedCards = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  // 获取指定文件夹中的媒体文件
  Future<void> _refresh() async {
    final count = await widget.path.assetCountAsync;
    if (count == 0) {
      return;
    }
    // 查询所有媒体实体列表（起止参数表示可以过滤只显示排序后中某一部分实体）
    final list = await widget.path.getAssetListRange(start: 0, end: count);
    setState(() {
      if (mounted) _list = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildAssetList(),
    );
  }

  /// 构建标题工具栏(复制在指定单个文件显示页面下再说)
  _buildAppBar() {
    return AppBar(
      title: selectedCards.isNotEmpty
          ? Text("${selectedCards.length}/${_list.length}")
          : Text(widget.path.name),
      actions: <Widget>[
        selectedCards.isNotEmpty
            ? Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: '删除',
                    onPressed: () {
                      print("点击了删除");
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.info),
                    tooltip: '详细信息',
                    onPressed: () {
                      print("点击了详细信息");
                    },
                  ),
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
      ],
    );
  }

  /// 构建媒体文件预览的grid列表
  _buildAssetList() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: _list.length,
      itemBuilder: (ctx, index) {
        final entity = _list[index];
        return GestureDetector(
          child: ImageItemWidget(
            entity: entity,
            option: ThumbnailOption.ios(
              size: const ThumbnailSize.square(500),
            ),
            isLongPress: selectedCards.contains(index) ? true : false,
          ),
          onTap: () async {
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

              // 2023-05-05 目前暂时点击某一个视频，只播放该视频，不循环列表
              if (entity.type == AssetType.video) {
                File? tempFile = await entity.file;

                if (tempFile != null) {
                  // ignore: use_build_context_synchronously
                  Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (BuildContext ctx) {
                        // 这里只有播放单个视频，就算列表中有多个，也不会自动播放下一个。
                        return VideoPlayerScreen(file: tempFile);
                      },
                    ),
                  );
                }
              } else if (entity.type == AssetType.image) {
                // 2023-05-05 目前暂时点击某一个图片，会滑动上/下一张，视频则显示视频预览图
                // ignore: use_build_context_synchronously
                Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (context) => GalleryPhotoViewWrapper(
                      galleryItems: _list,
                      backgroundDecoration: const BoxDecoration(
                        color: Colors.black,
                      ),
                      initialIndex: index,
                      scrollDirection: Axis.horizontal,
                    ),
                  ),
                );
              } else {
                print("点击的既不是图片也不是视频:${entity.title}-${entity.type}");
              }
            }
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
}
