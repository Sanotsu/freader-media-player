// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';
// import 'package:photo_view/photo_view_gallery.dart';

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
  // final List<String> galleryItems;
  final Axis scrollDirection;

  @override
  State<StatefulWidget> createState() {
    return _GalleryPhotoViewWrapperState();
  }
}

class _GalleryPhotoViewWrapperState extends State<GalleryPhotoViewWrapper> {
  late int currentIndex = widget.initialIndex;
  late File currentFile;
  late Future<File?> currentFileFuture = widget.galleryItems[currentIndex].file;

  var sensitivity = 20;

  // 当相册切换时，更新当前的所有和当前需要展示的图片
  // 这是一个妥协，要么是点击某种图片时加载整个相册的图片，这样点击时会花费很长时间，但页面切换时很快
  // 要么点击时直接传AssetEntity的list，在这里每次切换页面时加载当前页的图片，则每次切换都一卡一卡的
  void onPageChanged(int index) async {
    var temp = (await widget.galleryItems[currentIndex].file)!;

    setState(() {
      currentIndex = index;
      currentFile = temp;
    });
  }

  void onPageChanged2(int index) async {
    setState(() {
      currentFileFuture = widget.galleryItems[index].file;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final PageController controller = PageController();

    return Scaffold(
      body: Container(
        decoration: widget.backgroundDecoration,
        constraints: BoxConstraints.expand(
          height: MediaQuery.of(context).size.height,
        ),
        child: FutureBuilder<File?>(
            future: currentFileFuture,
            builder: (context, item) {
              // 有错显示错误
              if (item.hasError) {
                return Center(child: Text(item.error.toString()));
              }
              // 无数据转圈等到加载完成
              if (item.data == null) {
                return const Center(child: CircularProgressIndicator());
              }

              print("执行了FutureBuilder的结果${item.data!}");
              currentFile = item.data!;

              return PageView.builder(
                // 设置滑动模式
                physics: const AlwaysScrollableScrollPhysics(),
                scrollDirection: Axis.horizontal, // 滑动方向为垂直方向
                // 添加控制器
                controller: controller,
                // 条目个数
                itemCount: widget.galleryItems.length,
                // 构建每一屏的视图 UI
                itemBuilder: (BuildContext context, int index) {
                  return PhotoView(imageProvider: FileImage(currentFile));
                },
                onPageChanged: onPageChanged2,
                pageSnapping: false,
              );

              // return GestureDetector(
              //   child: PhotoView(imageProvider: FileImage(currentFile)),
              //   onPanUpdate: (details) {
              //     // Swiping in right direction.
              //     if (details.delta.dx > sensitivity) {
              //       print("t图片右滑 $currentIndex");
              //       setState(() {
              //         if (currentIndex > 0) {
              //           currentIndex = currentIndex - 1;

              //           print("t图片右滑22 $currentIndex");

              //           currentFileFuture =
              //               widget.galleryItems[currentIndex].file;
              //         }
              //       });
              //     }

              //     // Swiping in left direction.
              //     if (details.delta.dx < -sensitivity) {
              //       print("t图片左----滑");

              //       setState(() {
              //         if (currentIndex < widget.galleryItems.length - 1) {
              //           print("t图片向左滑22 $currentIndex");
              //           currentIndex = currentIndex + 1;
              //           currentFileFuture =
              //               widget.galleryItems[currentIndex].file;
              //         }
              //       });
              //     }
              //   },
              // );

              // return Stack(
              //   alignment: Alignment.bottomRight,
              //   children: <Widget>[
              //     // PhotoViewGallery.builder(
              //     //   scrollPhysics: const BouncingScrollPhysics(),
              //     //   builder: _buildItem,
              //     //   itemCount: widget.galleryItems.length,
              //     //   loadingBuilder: widget.loadingBuilder,
              //     //   backgroundDecoration: widget.backgroundDecoration,
              //     //   pageController: widget.pageController,
              //     //   onPageChanged: onPageChanged,
              //     //   // 切换图片的方向(垂直方向或水平方向)
              //     //   scrollDirection: widget.scrollDirection,
              //     //   // enableRotation: true, // 图片可旋转任意角度
              //     //   wantKeepAlive: true,
              //     // ),
              //     PhotoView(imageProvider: FileImage(currentFile)),
              //     Container(
              //       padding: const EdgeInsets.all(20.0),
              //       child: Text(
              //         // "filename:${widget.galleryItems[currentIndex].path.split('/').last}",
              //         // "filename:${widget.galleryItems[currentIndex].split('/').last}",
              //         "filename:${currentFile.path.split('/').last}",
              //         style: const TextStyle(
              //           color: Colors.white,
              //           fontSize: 17.0,
              //           decoration: null,
              //         ),
              //       ),
              //     )
              //   ],
              // );
            }),
      ),
    );
  }

  // PhotoViewGalleryPageOptions _buildItem(BuildContext context, int index) {
  //   // final String item = widget.galleryItems[index];

  //   return PhotoViewGalleryPageOptions(
  //     imageProvider: FileImage(currentFile),
  //     // 初始就适应屏幕的等宽或等高（看图片比例哪个长）
  //     initialScale: PhotoViewComputedScale.contained,
  //     // 缩放范围（一半到4倍）
  //     minScale: PhotoViewComputedScale.contained * 0.5,
  //     maxScale: PhotoViewComputedScale.covered * 4.0,
  //     heroAttributes: PhotoViewHeroAttributes(tag: currentFile),
  //   );
  // }
}
