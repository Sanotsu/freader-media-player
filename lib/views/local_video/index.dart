import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'path_list.dart';

/// 显示手机存储中所有的视频数据
/// 组件层级关系: localvideo -> pathlist -> pathpage -> videolist -> imageitemwidget -> videoplayerscreen
/// 页面层级关系: 主页面 > 含有视频的文件夹路径 > 该指定文件夹中的视频列表 > 点击播放视频

class LocalVideo extends StatefulWidget {
  const LocalVideo({Key? key}) : super(key: key);

  @override
  State<LocalVideo> createState() => _LocalVideoState();
}

class _LocalVideoState extends State<LocalVideo> {
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
  RequestType selectedRequestType = RequestType.video;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            child: FilterPathList(
              filter: filter,
              requestType: selectedRequestType,
            ),
          ),
        ],
      ),
    );
  }
}
