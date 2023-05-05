// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

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

  // 为了能够在图片展示页面左右滑动加载上下一张图片，这里需要取得当前文件夹中所有的文件。
  // 因此，文件太多的话，这里会卡住一会儿。
  Future<List<List<File>>> initFileList() async {
    List<File> tempImageList = [];
    List<File> tempVideoList = [];
    for (AssetEntity e in widget.list) {
      if (e.type == AssetType.video) {
        var temp = await e.file;
        tempVideoList.add(temp!);

        // 如果是视频，就替换为视频缩略图
        final uint8list = await VideoThumbnail.thumbnailData(
          video: temp.path,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 360,
          quality: 50,
        );

        Uint8List imageInUnit8List = uint8list!;
        final tempDir = await getTemporaryDirectory();
        File file =
            await File('${tempDir.path}/${temp.path.split('/').last}.jpg')
                .create();
        file.writeAsBytesSync(imageInUnit8List);

        tempImageList.add(file);
      } else if (e.type == AssetType.image) {
        var temp = await e.file;
        tempImageList.add(temp!);
      }
    }
    return [tempImageList, tempVideoList];
  }

  @override
  Widget build(BuildContext context) {
    var list = widget.list;

    return FutureBuilder<List<List<File>>>(
      future: initFileList(),
      builder: (context, item) {
        if (item.hasError) {
          return Text(item.error.toString());
        }
        // 因为默认就是空数组，所以等待加载过程中都转圈圈(视频可能为空，但图片不会，因为就算是全是视频，也有视频缩略图)
        if (item.data == null || item.data!.isEmpty || item.data![0].isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        List<File> imageFileList = item.data![0];
        // List<File> videoFileList = item.data![1];

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
                  // 2023-05-05 目前暂时点击某一个图片，会列表循环上/下一张，但会跳过视频，不会显示视频预览图
                  print("初始化initFileList${imageFileList.length}");

                  // ignore: use_build_context_synchronously
                  Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (context) => GalleryPhotoViewWrapper(
                        galleryItems: imageFileList,
                        // galleryItems: list,
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
      },
    );
  }
}
