// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import '../../models/change_display_mode.dart';
import 'path_list.dart';

/// 显示手机存储中所有的图片/视频数据（音频单独music模块，其他媒体文件暂不处理）
/// 组件层级关系: localmedia/index -> pathlist -> pathpage -> mediaassetlist -> imageitemwidget
///     -> screen/videoplayerscreen or screen/image_viewer_screen
/// 页面层级关系: 主页面 > 含有图片/视频的文件夹路径 > 该指定文件夹中的图片/视频列表 > 点击查看图片/播放视频

class LocalMedia extends StatefulWidget {
  const LocalMedia({Key? key}) : super(key: key);

  @override
  State<LocalMedia> createState() => _LocalMediaState();
}

class _LocalMediaState extends State<LocalMedia> {
  // 暂时默认排序为创建时间
  final List<OrderByItem> _orderBy = [
    OrderByItem.named(
      column: CustomColumns.base.createDate,
      isAsc: false,
    ),
  ];

  // 暂时过滤条件为空
  final List<WhereConditionItem> _where = [];

  late CustomFilter filter;

  @override
  void initState() {
    super.initState();
    filter = _createFilter();
  }

  // 查询本地媒体的过滤条件（比如大小、时长、修改时间等等）
  // 不过是之前在appbar右上角的按钮点击可修改值，目前暂时不执行手动筛选，就默认查询所有
  AdvancedCustomFilter _createFilter() {
    final filter = AdvancedCustomFilter(
      orderBy: _orderBy,
      where: _where,
    );
    return filter;
  }

  // 默认查询图片和视频，可切换仅图片或仅视频
  RequestType selectedRequestType = RequestType.common;

  @override
  Widget build(BuildContext context) {
    ChangeDisplayMode cdm = context.watch<ChangeDisplayMode>();
    bool isDarkMode = cdm.currentDisplayMode == DisplayMode.DARK;
    print("111 这是查询有媒体资源的主页面 index");
    return MaterialApp(
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('本地相册'),
          actions: [
            PopupMenuButton<RequestType>(
              icon: const Icon(Icons.filter_outlined),
              initialValue: selectedRequestType,
              onSelected: (RequestType item) {
                setState(() {
                  selectedRequestType = item;
                });
              },
              itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<RequestType>>[
                const PopupMenuItem<RequestType>(
                  value: RequestType.common,
                  child: Text('图片和视频'),
                ),
                const PopupMenuItem<RequestType>(
                  value: RequestType.image,
                  child: Text('仅图片'),
                ),
                const PopupMenuItem<RequestType>(
                  value: RequestType.video,
                  child: Text('仅视频'),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: MediaPathList(
                filter: filter,
                requestType: selectedRequestType,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
