// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../common/utils/tool_widgets.dart';
import '../common_widget/image_item_widget.dart';
import '../common_widget/cus_gallery_viewer/index.dart';

class PathImagePage extends StatefulWidget {
  const PathImagePage({super.key, required this.path});

  // 当前浏览的媒体文件属于哪一个文件夹
  final AssetPathEntity path;

  @override
  State<PathImagePage> createState() => _PathImagePageState();
}

class _PathImagePageState extends State<PathImagePage> {
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
      body: Padding(
        padding: EdgeInsets.fromLTRB(5.sp, 10.sp, 5.sp, 10.sp),
        child: _buildAssetList(),
      ),
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

              if (entity.type == AssetType.image) {
                // 2023-05-05 目前暂时点击某一个图片，会滑动上/下一张，视频则显示视频预览图

                Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (context) => CusGalleryViewer(
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
                showSnackMessage(
                  context,
                  "点击的既不是图片也不是视频:${entity.title}-${entity.type}",
                );
                return;
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
