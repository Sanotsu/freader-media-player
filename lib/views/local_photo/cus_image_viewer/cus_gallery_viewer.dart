// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';

import '../../../common/utils/tools.dart';
import '../../local_music/widgets/common_small_widgets.dart';

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
      bottomNavigationBar:
          isShowHeadAndBottom ? _buildBottomNavigationBar() : null,
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
                    print("item  $currentIndex-在builder中$item");

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
            color: Theme.of(context).canvasColor,
          ),
        ),
        subtitle: SimpleMarqueeOrText(
          data: "$headerTitle",
          style: TextStyle(
            fontSize: 15.sp,
            // color: Theme.of(context).canvasColor,
          ),
          velocity: 20,
          showLines: 1,
          height: 16.sp,
          textAlignment: Alignment.centerLeft,
        ),
      ),
      // title: Row(
      //   children: [
      //     Expanded(
      //       flex: 1,
      //       child: Text(
      //         // "${currentIndex + 1}/${widget.galleryItems.length}",
      //         "1234/4444",
      //         style: TextStyle(fontSize: 16.sp),
      //       ),
      //     ),
      //     Expanded(
      //       flex: 3,
      //       child: ListTile(
      //         minLeadingWidth: 0.sp,
      //         title: SimpleMarqueeOrText(
      //           data: "$headerTitle",
      //           style: TextStyle(fontSize: sizeHeadline1),
      //           velocity: 50,
      //           showLines: 1,
      //           height: 24.sp,
      //           textAlignment: Alignment.centerLeft,
      //         ),
      //         subtitle: Text(
      //           "$headerSubtitle ",
      //         ),
      //       ),
      //     )
      //   ],
      // ),
    );
  }

  _buildBottomNavigationBar() {
    return BottomNavigationBar(
      onTap: (value) {
        print("BottomNavigationBar点击的数据$value");
        clickBottomNavigationBar(value);
      },
      // 删除、详情、重命名、复制、（分享、等等其他功能暂时不管）
      type: BottomNavigationBarType.fixed,
      // 默认激活的索引是第一个。为了让所有按钮显示一致，选中未选择颜色一样
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black,
      selectedFontSize: 10.sp,
      unselectedFontSize: 10.sp,
      iconSize: 20.sp,
      // 2023-05-19 暂时不异动原本文件，就查看信息好了。因为感觉对photo manager插件还是不熟不信任
      // 暂时浅蓝色的按钮表示可用
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
            label: "详情",
            icon: Icon(
              Icons.info_outline,
              color: Colors.lightBlue,
            )),
        BottomNavigationBarItem(label: "重命名", icon: Icon(Icons.edit)),
        BottomNavigationBarItem(label: "删除", icon: Icon(Icons.delete)),
        BottomNavigationBarItem(label: "复制", icon: Icon(Icons.copy)),
        BottomNavigationBarItem(label: "更多", icon: Icon(Icons.more)),
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

  clickBottomNavigationBar(int index) {
    // 能点击下方按钮，就假设当前文件一定存在
    if (currentFile == null) {
      return;
    }

    // 点击“详情”
    if (index == 0) {
      return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            insetPadding: EdgeInsets.only(left: 10, right: 10.sp),
            child: Container(
              color: Colors.white,
              height: 400,
              child: Column(
                children: [
                  SizedBox(
                    height: 50.sp,
                    child: Center(
                      child: Text("详情", style: TextStyle(fontSize: 20.sp)),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(0.0),
                      children: <Widget>[
                        ListTile(
                          title: const Text("文件名称:"),
                          subtitle: Text(
                            "${currentFile?.path.split("/").last}",
                          ),
                        ),
                        ListTile(
                          title: const Text("文件路径:"),
                          subtitle: Text(
                            "${currentFile?.path.replaceAll("/storage/emulated", "内部存储")}",
                          ),
                        ),
                        ListTile(
                          title: const Text("修改时间:"),
                          subtitle: Text("${currentFile?.lastModifiedSync()}"),
                        ),
                        ListTile(
                          title: const Text("文件大小:"),
                          subtitle: Text(
                            "${getFileSize(currentFile?.lengthSync() ?? 0, 1)}",
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 60.sp,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(right: 10.sp),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            textStyle: Theme.of(context).textTheme.labelLarge,
                          ),
                          child: const Text('确认'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      return;
    }
  }
}
