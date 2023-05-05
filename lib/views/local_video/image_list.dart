// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'image_viewer_screen.dart';
import 'video_player_screen.dart';
import 'widgets/image_item_widget.dart';

class ImageList extends StatefulWidget {
  const ImageList({Key? key, required this.list}) : super(key: key);

  final List<AssetEntity> list;

  @override
  State<ImageList> createState() => _ImageListState();
}

class _ImageListState extends State<ImageList> {
  @override
  void initState() {
    super.initState();
  }

  Future<List<File>> initFileList() async {
    List<File> tempList = [];
    for (var e in widget.list) {
      var temp = await e.file;
      tempList.add(temp!);
    }
    return tempList;
  }

  @override
  Widget build(BuildContext context) {
    var list = widget.list;

    return FutureBuilder<List<File>>(
      future: initFileList(),
      builder: (context, item) {
        print(
            "itemitemitemitemitemitemitemitemitemitemitem-${item.data}-$item");
        if (item.hasError) {
          return Text(item.error.toString());
        }
        // 因为默认就是空数组，所以等待加载过程中都转圈圈
        if (item.data == null || item.data!.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        List<File> fileList = item.data!;

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
                print(
                    "图片中点击了 ${entity.title} ${entity.type} ${entity.originFile}");

                if (entity.type == AssetType.video) {
                  File? tempFile = await entity.file;

                  if (tempFile != null) {
                    // ignore: use_build_context_synchronously
                    Navigator.of(ctx).push(
                      MaterialPageRoute(
                        builder: (BuildContext ctx) {
                          return VideoPlayerScreen(file: tempFile);
                        },
                      ),
                    );
                  }
                } else if (entity.type == AssetType.image) {
                  // 为了能够左右滑动加载上下一张图片，这里需要取得当前文件夹中所有的文件
                  // 因此，文件太多的话，这里会卡住一会儿。
                  // List<File> fileList = [];
                  // for (var e in list) {
                  //   if (entity.type == AssetType.image) {
                  //     var temp = await e.file;
                  //     fileList.add(temp!);
                  //   }
                  // }

                  print("初始化initFileList${fileList.length}");

                  // var initFile = await entity.file;
                  // ignore: use_build_context_synchronously
                  Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (context) => GalleryPhotoViewWrapper(
                        galleryItems: fileList,
                        // galleryItems: list,
                        backgroundDecoration: const BoxDecoration(
                          color: Colors.black,
                        ),
                        initialIndex: index,
                        // initialFile: initFile!,
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
      },
    );
  }
}
