import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';

import 'dart:io';

import '../../common/global/constants.dart';
import '../../common/utils/tool_widgets.dart';
import '../../common/utils/tools.dart';
import '../common_widget/cus_video_player/index.dart';
import '../common_widget/image_item_widget.dart';
import '../common_widget/show_media_info_dialog.dart';

///
/// 2024-01-15 从理论上来讲，异动(修改、删除、复制等)操作越来越严格。
/// 所以仅仅考虑只保留读取和观看的功能，其他都不要了
///
class PathVideoPage extends StatefulWidget {
  const PathVideoPage({super.key, required this.path});

  // 当前浏览的媒体文件属于哪一个文件夹
  final AssetPathEntity path;

  @override
  State<PathVideoPage> createState() => _PathVideoPageState();
}

class _PathVideoPageState extends State<PathVideoPage> {
  // 文件夹中的文件实体
  List<AssetEntity> _list = [];
  // 文件夹中的视频文件
  List<File> _files = [];
  // 被选中的文件索引
  List<int> selectedItems = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  // 获取指定文件夹中的媒体文件
  Future<void> _refresh() async {
    final count = await widget.path.assetCountAsync;
    if (count == 0) return;

    // 查询所有媒体实体列表（起止参数表示可以过滤只显示排序后中某一部分实体）
    final list = await widget.path.getAssetListRange(start: 0, end: count);

    // 2024-01-17 过滤无法播放的适配
    list.removeWhere((element) => element.videoDuration == Duration.zero);

    // 2024-01-15 需要获取所有的文件，存入文件列表
    List<File> files = [];

    for (AssetEntity element in list) {
      var temp = await element.file;
      if (temp != null) {
        files.add(temp);
      }
    }

    setState(() {
      _list = list;
      _files = files;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// 构建标题工具栏(没有条目被长按选择则不显示功能按钮)
      appBar: AppBar(
        title: selectedItems.isNotEmpty
            ? Text("${selectedItems.length}/${_list.length}")
            : Text(widget.path.name),
        actions: <Widget>[
          selectedItems.isNotEmpty
              ? Row(
                  children: [
                    _buildInfoButton(),
                    IconButton(
                      icon: const Icon(Icons.cancel),
                      tooltip: '取消选中',
                      onPressed: () {
                        setState(() {
                          selectedItems.length = 0;
                        });
                      },
                    )
                  ],
                )
              : Container(),
        ],
      ),
      body: _buildVideoList(),
    );
  }

  _buildInfoButton() {
    return IconButton(
      icon: const Icon(Icons.info_outline),
      tooltip: '属性',
      onPressed: () async {
        // 因为有些属性是asset本身，但还有一些需要对应的file文件，所以存两个列表
        List<AssetEntity?> assets = [];
        List<FileStat?> files = [];
        for (var e in selectedItems) {
          assets.add(_list[e]);
          files.add((await _list[e].file)?.statSync());
        }

        // 计算被选中视频的总大小
        var sumSize = files.fold(
          0,
          (previousValue, element) =>
              previousValue + (element != null ? element.size : 0),
        );

        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("属性", textAlign: TextAlign.start),
              content: assets.length > 1
                  ? SizedBox(
                      height: 150.sp,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 如果是多选了视频文件，则只显示文件数量和总大小
                          ListTile(
                            title: const Text("总数量"),
                            subtitle: Text("${selectedItems.length}"),
                          ),
                          ListTile(
                            title: const Text("总大小"),
                            subtitle: Text(
                              "${getFileSize(sumSize, 2)} ($sumSize Byte)",
                            ),
                          )
                        ],
                      ),
                    )
                  : _buildInfoTable(assets[0], files[0]),
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
            selectedItems.length = 0;
          });
        });
      },
    );
  }

  /// 参考MX Player，视频信息分为几个table显示
  _buildInfoTable(AssetEntity? asset, FileStat? state) {
    return Table(
      // 设置表格边框
      // border: TableBorder.all(
      //   color: Theme.of(context).disabledColor,
      // ),
      // 设置每列的宽度占比
      columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(9)},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
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
              ? formatDurationToString(asset!.videoDuration)
              : '0',
        ),
      ],
    );
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
            // 构建视频缩略图时，如果视频格式不支持，构建时会报大量错误。
            child: entity.videoDuration != Duration.zero
                ? ImageItemWidget(
                    entity: entity,
                    option: ThumbnailOption.ios(
                      size: const ThumbnailSize.square(500),
                    ),
                  )
                : Image.asset(placeholderImageUrl, fit: BoxFit.scaleDown),
          ),

          trailing: SizedBox(
            width: 32.sp,
            child: IconButton(
              onPressed: () {
                showMediaInfoDialog(entity, context);
              },
              icon: Icon(
                Icons.info_outline,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          selectedColor: Colors.blue,
          selected: selectedItems.contains(index) ? true : false,
          onTap: () async {
            // 如果已经处于长按状态，点击则为添加多选
            if (selectedItems.isNotEmpty) {
              setState(() {
                // 如果已经选中了，再点则为移除选中
                if (selectedItems.contains(index)) {
                  selectedItems.remove(index);
                } else {
                  selectedItems.add(index);
                }
              });
            } else {
              // 2024-01-16 理论上，视频列表中点击的视频，应该不为空，也应该能够播放
              if (entity.type == AssetType.video) {
                File? tempFile = await entity.file;

                if (tempFile != null) {
                  // 找到点击的视频在列表中的索引
                  var index = _files.indexWhere((f) => f.path == tempFile.path);

                  if (!context.mounted) return;
                  if (index < 0) {
                    showSnackMessage(context, "没找到对应点击的视频");
                    return;
                  }

                  // 2024-01-17 如果点击的视频获取不到长度，就不进入播放页面
                  // 理论上没有，因为进入页面初始化时就过滤掉了不可播放的视频
                  if (entity.videoDuration == Duration.zero) {
                    commonExceptionDialog(
                      context,
                      "提示",
                      "不支持的视频格式: ${entity.mimeType}",
                    );
                    return;
                  }

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext ctx) {
                        // 这里只传入文件列表和点击文件的索引。
                        return CusVideoPlayer(entities: _list, index: index);
                      },
                    ),
                  );
                }
              } else {
                showSnackMessage(
                  context,
                  "点击的不是视频:${entity.title}-${entity.type}",
                );
                return;
              }
            }
          },
          // 点击了长按，把该条目加入选中列表去
          onLongPress: () {
            setState(() {
              selectedItems.add(index);
            });
          },
        );
      },
    );
  }
}
