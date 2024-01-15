// ignore_for_file: avoid_print

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';

import 'dart:io';

import '../../common/utils/tools.dart';
import '../local_media/screen/video_player_screen.dart';
import '../local_media/widgets/image_item_widget.dart';

///
/// 2024-01-15 从理论上来讲，异动(修改、删除、复制等)操作越来越严格。
/// 所以仅仅考虑只保留读取和观看的功能，其他都不要了
///
class SpecifiedVideoFolderPage extends StatefulWidget {
  const SpecifiedVideoFolderPage(
      {super.key, required this.path, required this.pathList});

  // 当前浏览的媒体文件属于哪一个文件夹
  final AssetPathEntity path;
  // 手机里一共找到哪些有媒体文件的文件夹（列表）
  final List<AssetPathEntity> pathList;

  @override
  State<SpecifiedVideoFolderPage> createState() =>
      _SpecifiedVideoFolderPageState();
}

class _SpecifiedVideoFolderPageState extends State<SpecifiedVideoFolderPage> {
  // 文件夹中的文件
  List<AssetEntity> _list = [];
  // 被选中的文件索引
  List<int> selectedCards = [];

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
                    _buildInfoButton(),
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined),
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
      // body: _buildAssetList(),
      body: _buildVideoList(),
    );
  }

  _buildDeleteButton() {
    return IconButton(
      icon: const Icon(Icons.delete_outline),
      tooltip: '删除',
      onPressed: () async {
        print("点击了删除");

        showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: const Text("确认删除选中的文件(不可恢复)？"),
              actions: <Widget>[
                TextButton(
                  child: const Text('取消'),
                  onPressed: () {
                    setState(() {
                      selectedCards.length = 0;
                    });
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('视频文件已删除!')),
                      );
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

  _buildInfoButton() {
    return IconButton(
      icon: const Icon(Icons.info_outline),
      tooltip: '信息',
      onPressed: () async {
        print("点击了信息");

        // 因为有些属性是asset本身，但还有一些需要对应的file文件，所以存两个列表
        List<AssetEntity?> assets = [];
        List<FileStat?> files = [];
        for (var e in selectedCards) {
          assets.add(_list[e]);
          files.add((await _list[e].file)?.statSync());
        }

        var sum = files.fold(
          0,
          (previousValue, element) =>
              previousValue + (element != null ? element.size : 0),
        );

        print('----------------$sum ${getFileSize(sum, 2)}');

        print("首个视频assets[0] ${(assets[0]?.createDateTime)}");
        // log("files[0] ${files[0]}");
        log("  _list[e].file ${(await _list[0].file)}");

        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(
                "选中视频信息",
                textAlign: TextAlign.start,
              ),
              content: assets.length > 1
                  ? SizedBox(
                      height: 150.sp,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 如果是多选了视频文件，则只显示文件数量和总大小
                          ListTile(
                            title: const Text("总数量"),
                            subtitle: Text("${selectedCards.length}"),
                          ),
                          ListTile(
                            title: const Text("总大小"),
                            subtitle: Text(
                              "${getFileSize(sum, 2)} ($sum Byte)",
                            ),
                          )
                        ],
                      ),
                    )
                  : _buildInfoTable(
                      assets[0],
                      files[0],
                      _buildInfoFileTableRow(assets[0], files[0]),
                    ),
              actions: <Widget>[
                TextButton(
                  child: const Text('确认'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        ).then((value) {
          // 关闭弹窗，取消选中
          setState(() {
            selectedCards.length = 0;
          });
        });
      },
    );
  }

  /// 参考MX Player，视频信息分为几个table显示
  _buildInfoTable(
    AssetEntity? asset,
    FileStat? state,
    List<TableRow> children,
  ) {
    return Table(
      // 设置表格边框
      // border: TableBorder.all(
      //   color: Theme.of(context).disabledColor,
      // ),
      // 设置每列的宽度占比
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(9),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: children,
    );
  }

  // 选择文件弹窗中，”文件“信息的栏位
  List<TableRow> _buildInfoFileTableRow(AssetEntity? asset, FileStat? state) {
    return [
      _buildTableRow(
        "文件",
        "",
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
      _buildTableRow("文件名", asset?.title),
      _buildTableRow("位置", asset?.relativePath),
      _buildTableRow(
        "大小",
        state != null
            ? "${getFileSize(state.size, 2)}(${state.size} Byte)"
            : '',
      ),
      _buildTableRow("日期", asset?.createDateTime.toString()),
      _buildTableRow(
        "媒体",
        "",
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
      _buildTableRow("格式", asset?.mimeType),
      _buildTableRow("分辨率", "${asset?.height} x ${asset?.width}"),
      _buildTableRow(
        "时长",
        asset?.videoDuration != null
            ? formatDurationToString(
                asset!.videoDuration,
              )
            : '0',
      ),
    ];
  }

  TableRow _buildTableRow(
    String? label,
    String? value, {
    TextStyle? labelStyle,
    TextStyle? valueStyle,
  }) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 2.sp),
          child: Text(
            label ?? "[Label]",
            style: labelStyle ??
                TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(context).disabledColor,
                ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 2.sp),
          child: Text(
            value ?? "",
            style: valueStyle ?? TextStyle(fontSize: 12.sp),
          ),
        ),
      ],
    );
  }

  _buildCopyButton() {
    return IconButton(
      icon: const Icon(Icons.copy_outlined),
      tooltip: '复制',
      onPressed: () {
        print("点击了复制，添加到其他文件夹");
        print("${0.3.sh} ${MediaQuery.of(context).size.height * 0.3}");

        showModalBottomSheet<void>(
          context: context,
          builder: (BuildContext context) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 1.sp),
              height: 0.3.sh,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(
                      height: 50.sp,
                      child: Text(
                        '复制到其他视频文件夹…',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Divider(height: 5.sp, thickness: 3.sp),
                    Expanded(
                      child: Scrollbar(
                        // 不设置这个，滚动条默认不显示，在滚动时才显示
                        thumbVisibility: true,
                        thickness: 5.sp,
                        child: buildCopyTargetFolderList(),
                      ),
                    ),
                    Divider(height: 5.sp, thickness: 3.sp),
                    SizedBox(
                      height: 50.sp,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            child: const Text('取消'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildCopyTargetFolderList() {
    // 从所有有图片的文件夹列表中，排除“最近”和当前文件夹，用于选中的图片文件复制到其他位置。
    List<AssetPathEntity> tempList = widget.pathList
        .where((e) =>
            e.name.toLowerCase() != "recent" && e.name != widget.path.name)
        .toList();

    print("${tempList.length}-----${widget.pathList.length}");

    return ListView.builder(
      itemCount: tempList.length,
      itemBuilder: (BuildContext context, int index) {
        return Column(
          children: [
            if (index != 0) Divider(height: 5.sp, thickness: 1.sp),
            ListTile(
              title: Text(tempList[index].name),
              onTap: () async {
                // 点击了弹窗中的其他文件夹，就需要把选中的图片复制过去
                // 获取文件夹路径(因为没有直接路径，所以找到该文件夹下第一个文件，从文件属性中得到路径)
                // 2024-01-13 注意：这里复制到其他文件夹，也只是原本就有视频文件的文件夹。
                // 否则取第一个文件就报错了
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
                // ??? 2024-01-13 现在能看到了，但获取视频时长就一直是0
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("复制完成!")),
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// 构建视频列表
  _buildVideoList() {
    return ListView.builder(
      itemCount: _list.length,
      itemBuilder: (BuildContext context, int index) {
        AssetEntity entity = _list[index];

        return ListTile(
          title: Text(entity.title ?? ""),
          subtitle: Text(formatDurationToString(entity.videoDuration)),
          leading: SizedBox(
            height: 56.sp,
            width: 84.sp,
            child: ImageItemWidget(
              entity: entity,
              option: ThumbnailOption.ios(
                size: const ThumbnailSize.square(500),
              ),
            ),
          ),
          trailing: const Icon(Icons.more_vert),
          selectedColor: Colors.blue,
          selected: selectedCards.contains(index) ? true : false,
          onTap: () async {
            // 如果已经处于长按状态，点击则为添加多选
            if (selectedCards.isNotEmpty) {
              setState(() {
                // 如果已经选中了，再点则为移除选中
                if (selectedCards.contains(index)) {
                  selectedCards.remove(index);
                } else {
                  selectedCards.add(index);
                }
              });
            } else {
              // 2023-05-05 目前暂时点击某一个视频，只播放该视频，不循环列表
              if (entity.type == AssetType.video) {
                File? tempFile = await entity.file;

                if (tempFile != null) {
                  if (!mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext ctx) {
                        // 这里只有播放单个视频，就算列表中有多个，也不会自动播放下一个。
                        return VideoPlayerScreen(file: tempFile);
                      },
                    ),
                  );
                }
              } else {
                print("点击的不是视频:${entity.title}-${entity.type}");
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
