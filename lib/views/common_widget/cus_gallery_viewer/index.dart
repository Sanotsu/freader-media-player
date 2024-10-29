import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';

import '../../local_music/widgets/common_small_widgets.dart';
import '../show_media_info_dialog.dart';

class CusGalleryViewer extends StatefulWidget {
  CusGalleryViewer({
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
    return _CusGalleryViewerState();
  }
}

class _CusGalleryViewerState extends State<CusGalleryViewer> {
  // 当前显示的图片索引
  late int currentIndex = widget.initialIndex;
  // 是否显示app和bottom的bar
  late bool isShowHeadAndBottom = true;
  late File? currentFile;
  // appbar显示图片的文字
  late dynamic headerTitle = "";
  late dynamic headerSubtitle = "";

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    // app初次启动时要获取相关授权，取得之后就不需要重复请求了
    initImageFromAssetEntity();
  }

  // 初始化图片
  Future<void> initImageFromAssetEntity() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });

    AssetEntity e = widget.galleryItems[currentIndex];
    var temp = await e.file;

    setState(() {
      currentFile = temp;
      headerTitle = e.title;
      headerSubtitle = DateFormat.yMMMMd().add_Hms().format(e.modifiedDateTime);
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 这两个属性是让appbar和bottombar在body上方显示，而不是同一层显示
      // （即隐藏展开时body不会挤压或舒展）
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: isShowHeadAndBottom ? _buildAppBar() : null,

      body: SafeArea(
        child: Container(
          decoration: widget.backgroundDecoration,
          constraints: BoxConstraints.expand(
            height: MediaQuery.of(context).size.height,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                flex: 9,
                child: FutureBuilder<File?>(
                  future: widget.galleryItems[currentIndex].file,
                  builder: (context, item) {
                    // 从官网上看 https://api.flutter.dev/flutter/widgets/FutureBuilder-class.html
                    // 区分为hasError、hasData、和其他
                    // 有错显示错误
                    if (item.hasError) {
                      return Center(child: Text(item.error.toString()));
                    } else if (item.hasData) {
                      return _buildPageView(item.data!);
                    } else {
                      // 无数据转圈等到加载完成
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 2024-01-18 因为考虑不再提供图片的异动功能，所以暂时顶部显示当前索引，底部显示文件名和详情按钮
  /// 其他的先不支持。
  _buildAppBar() {
    return AppBar(
      title: ListTile(
        minLeadingWidth: 0.sp,
        title: Text(
          "${currentIndex + 1}/${widget.galleryItems.length}",
          style: TextStyle(
            fontSize: 18.sp,
            // color: Theme.of(context).canvasColor,
          ),
        ),
        subtitle: SimpleMarqueeOrText(
          data: "$headerTitle",
          style: TextStyle(
            fontSize: 12.sp,
            // color: Theme.of(context).canvasColor,
          ),
          velocity: 20,
          showLines: 1,
          height: 20.sp,
          textAlignment: Alignment.centerLeft,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: '图片信息',
          onPressed: () {
            showMediaInfoDialog(widget.galleryItems[currentIndex], context);
          },
        )
      ],
    );
  }

  _buildPageView(File file) {
    return PageView.builder(
      controller: PageController(initialPage: currentIndex),
      scrollDirection: Axis.horizontal,
      // 因为这里传入的是entity列表，所以切换是要获取文件，所以看起来有点卡顿
      // ？？？如果传入就是文件列表，可能会好点
      onPageChanged: (int index) async {
        setState(() {
          // 更新当前相册索引
          currentIndex = index;
          // 构建图片名称和上次修改时间
          headerTitle = widget.galleryItems[index].title;
          headerSubtitle = DateFormat.yMMMMd().add_Hms().format(
                widget.galleryItems[index].modifiedDateTime,
              );
        });

        // 如果不是图片类型，就不用展示，而是跳到下一个资源区
        if (widget.galleryItems[index].type != AssetType.image) {
          setState(() {
            index++;
          });
          return;
        }

        // 更新当前展示图片文件
        var tempFile = await widget.galleryItems[index].file;
        setState(() {
          currentFile = tempFile;
        });
      },
      itemCount: widget.galleryItems.length,
      itemBuilder: (BuildContext context, int index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              isShowHeadAndBottom = !isShowHeadAndBottom;
            });
          },
          child: PhotoView(
            imageProvider: FileImage(file),
            enableRotation: true,
            // backgroundDecoration: BoxDecoration(
            //   color: Theme.of(context).canvasColor,
            //   // color: Colors.black,
            // ),
          ),
        );
      },
    );
  }
}
