// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';

import 'dart:io';

import '../local_media/screen/image_viewer_screen.dart';
import '../local_media/screen/video_player_screen.dart';
import '../local_media/widgets/image_item_widget.dart';

class SpecifiedImageFolderPage extends StatefulWidget {
  const SpecifiedImageFolderPage(
      {super.key, required this.path, required this.pathList});

  // 当前浏览的媒体文件属于哪一个文件夹
  final AssetPathEntity path;
  // 手机里一共找到哪些有媒体文件的文件夹（列表）
  final List<AssetPathEntity> pathList;

  @override
  State<SpecifiedImageFolderPage> createState() =>
      _SpecifiedImageFolderPageState();
}

class _SpecifiedImageFolderPageState extends State<SpecifiedImageFolderPage> {
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

    print("这只指定文件夹${widget.path.name}中的数量$count");
    // 查询所有媒体实体列表（起止参数表示可以过滤只显示排序后中某一部分实体）
    final list = await widget.path.getAssetListRange(start: 0, end: count);
    setState(() {
      if (mounted) _list = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    print("333 这里是指定文件夹${widget.path.name}下文件预览界面PathPage");

    return Scaffold(
      /// 构建标题工具栏(没有条目被长按选择则不显示功能按钮)
      appBar: AppBar(
        title: selectedCards.isNotEmpty
            ? Text("${selectedCards.length}/${_list.length}")
            : Text(widget.path.name),
        actions: <Widget>[
          selectedCards.isNotEmpty
              ? Row(
                  children: [
                    _buildDeleteButton(),
                    _buildCopyButton(),
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
      ),
      body: _buildAssetList(),
    );
  }

  _buildDeleteButton() {
    return IconButton(
      icon: const Icon(Icons.delete),
      tooltip: '删除',
      onPressed: () async {
        print("点击了删除");

        showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: const Text("确认删除选中的文件？"),
              actions: <Widget>[
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  child: const Text('取消'),
                  onPressed: () {
                    setState(() {
                      selectedCards.length = 0;
                    });
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  child: const Text('确认'),
                  onPressed: () async {
                    for (var e in selectedCards) {
                      var file = await _list[e].file;
                      if (file != null) {
                        file.deleteSync();
                      }
                    }

                    setState(() {
                      selectedCards.length = 0;
                      _refresh();
                    });

                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  _buildCopyButton() {
    return IconButton(
      icon: const Icon(Icons.copy),
      tooltip: '复制',
      onPressed: () {
        print("点击了复制，添加到其他文件夹");

        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                '复制到…',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: setupAlertDialogContainer(),
              actions: [
                TextButton(
                  child: const Text('取消'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget setupAlertDialogContainer() {
    // 从所有有图片的文件夹列表中，排除“最近”和当前文件夹，用于选中的图片文件复制到其他位置。
    List<AssetPathEntity> tempList = widget.pathList
        .where((e) =>
            e.name.toLowerCase() != "recent" && e.name != widget.path.name)
        .toList();

    print("${tempList.length}-----${widget.pathList.length}");

    return ListView.builder(
      shrinkWrap: true,
      itemCount: tempList.length,
      itemBuilder: (BuildContext context, int index) {
        return Card(
          // elevation: 5.sp,
          child: ListTile(
            title: Text(tempList[index].name),
            onTap: () async {
              // 点击了弹窗中的其他文件夹，就需要把选中的图片复制过去
              // 获取文件夹路径(因为没有直接路径，所以找到该文件夹下第一个文件，从文件属性中得到路径)
              var tempFile = await (await tempList[index]
                      .getAssetListRange(start: 0, end: 1))[0]
                  .file;

              if (tempFile == null) {
                setState(() {
                  selectedCards.length = 0;
                });
                print("没找到移动的目标路径");
                return;
              }

              var temp = tempFile.path
                  .split("/")
                  .where((e) => e != tempFile.path.split("/").last)
                  .toList();
              var pathUrl = temp.join("/");
              // 得到目标文件夹路径之后，把选中的文件一一复制过去
              // ??? 2023-05-19 实测是复制成功了的，在其他工具或者文件管理器中都能看到，
              // 但在这个photo_manager 中不行，重新加载后也不行，明明原文件都能显示的。
              for (var e in selectedCards) {
                var file = await _list[e].file;
                if (file != null) {
                  file.copySync("$pathUrl/${file.path.split("/").last}");
                }
              }
              setState(() {
                selectedCards.length = 0;
              });
              if (mounted) {
                Navigator.of(context).pop("复制完成");
              }
            },
          ),
        );
      },
    );
  }

  /// 构建媒体文件预览的grid列表
  _buildAssetList() {
    print(" _list.length${_list.length}");
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
                  if (!mounted) return;
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
