// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'screen/image_viewer_screen.dart';
import 'screen/video_player_screen.dart';
import 'widgets/image_item_widget.dart';

class MediaAssetList extends StatefulWidget {
  const MediaAssetList({Key? key, required this.list}) : super(key: key);

  final List<AssetEntity> list;

  @override
  State<MediaAssetList> createState() => _MediaAssetListState();
}

class _MediaAssetListState extends State<MediaAssetList> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var list = widget.list;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: list.length,
      itemBuilder: (ctx, index) {
        final entity = list[index];
        return GestureDetector(
          child: ImageItemWidget(
            entity: entity,
            option: ThumbnailOption.ios(
              size: const ThumbnailSize.square(500),
            ),
          ),
          onTap: () async {
            print("图片中点击了 ${entity.title} ${entity.type} ${entity.originFile}");

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
                    galleryItems: list,
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
          },
        );
      },
    );
  }
}
