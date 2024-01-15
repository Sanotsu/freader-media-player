// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../common/utils/global_styles.dart';
import '../../../common/utils/tools.dart';
import '../../local_music/widgets/common_small_widgets.dart';

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
  // 当前显示的图片索引
  late int currentIndex = widget.initialIndex;
  // 是否显示app和bottom的bar
  late bool isShowHeadAndBottom = false;
  late File? currentFile;
  // appbar显示图片的文字
  late dynamic headerTitle = "";
  late dynamic headerSubtitle = "";

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
      // 这两个属性是让appbar和bottombar在body上方显示，而不是同一层显示
      // （即隐藏展开时body不会挤压或舒展）
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: isShowHeadAndBottom
          ? AppBar(
              title: ListTile(
                minLeadingWidth: 0.sp,
                title: SimpleMarqueeOrText(
                  data: "$headerTitle",
                  style: TextStyle(fontSize: sizeHeadline1),
                  velocity: 50,
                  showLines: 1,
                  height: 24.sp,
                  textAlignment: Alignment.centerLeft,
                ),
                subtitle: Text("$headerSubtitle"),
              ),
            )
          : null,
      bottomNavigationBar: isShowHeadAndBottom
          ? BottomNavigationBar(
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
            )
          : null,
      body: Container(
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

                    // 构建图片名称和上次修改时间
                    headerTitle = item.data!.path.split('/').last;
                    headerSubtitle = DateFormat.yMMMMd('zh_CN')
                        .add_Hms()
                        .format(item.data!.lastModifiedSync());

                    return PageView.builder(
                      controller: PageController(initialPage: currentIndex),
                      scrollDirection: Axis.horizontal,
                      onPageChanged: onPageViewPageChanged,
                      // itemCount: listWidget.length,
                      itemCount: widget.galleryItems.length,
                      itemBuilder: (BuildContext context, int index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              isShowHeadAndBottom = !isShowHeadAndBottom;
                              currentFile = item.data!;
                            });
                          },
                          child: PhotoView(
                            imageProvider: FileImage(item.data!),
                            backgroundDecoration: BoxDecoration(
                              color: Theme.of(context).canvasColor,
                              // color: Colors.black,
                            ),
                          ),
                        );
                      },
                    );
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

/*
    print("currentFile---44444");

    // ??? 2023-05-19 虽然重命名功能可以实现，但因为这里是上层传入的数据，这里修改了，重新获取比较麻烦，目前会直接报错。
    // 暂时就不处理了，这个photo manager库用着也挺难受。先保留，暂时不用
    return showDialog(
      context: context,
      builder: (context) {
        var currentFileName = currentFile!.path.split("/").last;

        return AlertDialog(
          title: const Text('修改歌单名(暂无效)'),
          content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return TextFormField(
              autofocus: false,
              initialValue: currentFileName,
              decoration: const InputDecoration(hintText: '输入新歌单名'),
              onChanged: (value) {
                setState(() {
                  currentFileName = value;
                });
              },
            );
          }),
          actions: <Widget>[
            MaterialButton(
              color: Colors.red,
              textColor: Colors.white,
              child: const Text('取消'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
              return MaterialButton(
                color: Colors.green,
                textColor: Colors.white,
                child: const Text('确认'),
                onPressed: () async {
                  var pathPrefix = currentFile!.path
                      .split("/")
                      .where((e) => e != currentFile!.path.split("/").last)
                      .toList()
                      .join("/");

                  currentFile!.renameSync("$pathPrefix/$currentFileName");
                  Navigator.pop(context);
                },
              );
            }),
          ],
        );
      },
    );

    */
  }
}
