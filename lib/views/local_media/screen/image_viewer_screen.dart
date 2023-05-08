// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class GalleryPhotoViewWrapper extends StatefulWidget {
  GalleryPhotoViewWrapper({
    super.key,
    this.loadingBuilder,
    this.backgroundDecoration,
    this.minScale,
    this.maxScale,
    this.initialIndex = 0,
    required this.galleryItems,
    this.scrollDirection = Axis.horizontal,
  }) : pageController = PageController(initialPage: initialIndex);

  final LoadingBuilder? loadingBuilder;
  final BoxDecoration? backgroundDecoration;
  final dynamic minScale;
  final dynamic maxScale;
  final int initialIndex;
  final PageController pageController;
  final List<AssetEntity> galleryItems;
  final Axis scrollDirection;

  @override
  State<StatefulWidget> createState() {
    return _GalleryPhotoViewWrapperState();
  }
}

class _GalleryPhotoViewWrapperState extends State<GalleryPhotoViewWrapper> {
  late int currentIndex = widget.initialIndex;

  // // 新加一个和文件数量等长的list,可为null
  // late List<Widget> listWidget = List.generate(
  //   widget.galleryItems.length,
  //   (index) => Container(),
  // );

  // 当相册切换时，更新当前的所有和当前需要展示的图片
  // 这是一个妥协，要么是点击某种图片时加载整个相册的图片，这样点击时会花费很长时间，但页面切换时很快
  // 要么点击时直接传AssetEntity的list，在这里每次切换页面时加载当前页的图片，则每次切换都一卡一卡的
  void onPageViewPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  // 如果切换后的文件的本身就是图片文件，则显示文件；如果是视频，则显示缩略图。
  Future<File> initImageFromAssetEntity() async {
    AssetEntity e = widget.galleryItems[currentIndex];

    if (e.type == AssetType.video) {
      var temp = await e.file;

      // 如果是视频，就替换为视频缩略图
      final uint8list = await VideoThumbnail.thumbnailData(
        video: temp!.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 360,
        quality: 50,
      );

      Uint8List imageInUnit8List = uint8list!;
      final tempDir = await getTemporaryDirectory();
      File file = await File('${tempDir.path}/${temp.path.split('/').last}.jpg')
          .create();
      file.writeAsBytesSync(imageInUnit8List);

      return file;

      /// 本来类型不止视频和图片，但这里假设一定只是视频或图片
      // } else if (e.type == AssetType.image) {
    } else {
      var temp = await e.file;
      return temp!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: widget.backgroundDecoration,
        constraints: BoxConstraints.expand(
          height: MediaQuery.of(context).size.height,
        ),
        child: FutureBuilder<File?>(
            future: initImageFromAssetEntity(),
            builder: (context, item) {
              print("item  $currentIndex-在builder中$item");

              // 从官网上看 https://api.flutter.dev/flutter/widgets/FutureBuilder-class.html
              // 区分为hasError、hasData、和其他
              // 有错显示错误
              if (item.hasError) {
                return Center(child: Text(item.error.toString()));
              } else if (item.hasData) {
                // 为什么这里更新了，pageview的内容不会变？为什么这个builder会执行两次，两次的内容不一致？
                // listWidget[currentIndex] =
                //     PhotoView(imageProvider: FileImage(item.data!));

                return PageView.builder(
                  controller: PageController(initialPage: currentIndex),
                  scrollDirection: Axis.horizontal,
                  onPageChanged: onPageViewPageChanged,
                  // itemCount: listWidget.length,
                  itemCount: widget.galleryItems.length,
                  itemBuilder: (BuildContext context, int index) {
                    return PhotoView(imageProvider: FileImage(item.data!));
                  },
                );
              } else {
                // 无数据转圈等到加载完成
                return const Center(child: CircularProgressIndicator());
              }
            }),
      ),
    );
  }
}
