// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';

import 'path_page.dart';

/// 显示手机存储中所有的图片/视频数据（音频单独music模块，其他媒体文件暂不处理）
/// 组件层级关系: localmedia/index -> pathlist -> pathpage -> mediaassetlist -> imageitemwidget
///     -> screen/videoplayerscreen or screen/image_viewer_screen
/// 页面层级关系: 主页面 > 含有图片/视频的文件夹路径 > 该指定文件夹中的图片/视频列表 > 点击查看图片/播放视频
///
/// 图片视频页面的层级应该是这样:
///   所有的图片/视频文件夹列表 (index)
///     - 切换仅图片/仅视频时，重新查询文件夹列表
///     - 点击某个文件夹项次时，进入文件夹中，显示文件夹中的媒体文件列表 (folderIndex/旧PathPage)
///         - 点击某个具体图片/视频，进入图片浏览/视频播放页面

class LocalMedia extends StatefulWidget {
  const LocalMedia({super.key});

  @override
  State<LocalMedia> createState() => _LocalMediaState();
}

class _LocalMediaState extends State<LocalMedia> {
  /// 这些都是媒体文件筛选条件:
  // 文件夹列表暂时默认排序为创建时间
  final List<OrderByItem> _orderBy = [
    OrderByItem.named(column: CustomColumns.base.createDate, isAsc: false),
  ];
  // 暂时过滤条件为空
  final List<WhereConditionItem> _where = [];
  // 用户可以有很多筛选条件(但暂时未启用)
  late CustomFilter filter;
  // 默认查询图片和视频，可切换仅图片或仅视频
  RequestType selectedRequestType = RequestType.common;

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

  // 获取指定文件夹中的媒体文件
  Future<List<AssetPathEntity>> refresh() async {
    return PhotoManager.getAssetPathList(
      type: selectedRequestType, // 默认的common只有图片和视频
      filterOption: filter,
      hasAll: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    print("111 这是查询有媒体资源的主页面 index");
    return Scaffold(
      // drawer: buildDrawer(context),
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
            itemBuilder: (BuildContext context) => [
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
            child: _buildMediaFolderList(),
            // child: MediaPathList(
            //   filter: filter,
            //   requestType: selectedRequestType,
            // ),
          ),
        ],
      ),
    );
  }

  _buildMediaFolderList() {
    return FutureBuilder<List<AssetPathEntity>>(
      future: refresh(),
      builder: (
        BuildContext context,
        AsyncSnapshot<List<AssetPathEntity>> snapshot,
      ) {
        if (snapshot.hasData) {
          print("getAssetPathList查询的结果${snapshot.data!}");

          List<AssetPathEntity> list = snapshot.data!;

          return ListView.builder(
            itemBuilder: (BuildContext context, int index) {
              // 相册和文件夹的抽象化。它代表了Android上的 "MediaStore "中的一个桶，以及iOS/MacOS上的 "PHAssetCollection "对象。
              final AssetPathEntity path = list[index];

              if (path.name.toLowerCase() != "recent") {
                return ListTile(
                  title: Text(path.name),
                  // subtitle: Text(path.id),
                  leading: Icon(Icons.folder, size: 50.sp),
                  trailing: FutureBuilder<int>(
                    future: path.assetCountAsync,
                    builder:
                        (BuildContext context, AsyncSnapshot<int> snapshot) {
                      if (snapshot.hasData) {
                        // print("构建文件夹中数量:${path.name}-${snapshot.data}");
                        // ??? 2023-05-19 这个数值和实际的总是可能对不上，原因不明
                        return Text("${snapshot.data} 个媒体文件");
                      }
                      return const SizedBox();
                    },
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        // 进入指定文件夹
                        builder: (BuildContext ctx) =>
                            PathPage(path: path, pathList: list),
                      ),
                    ).then((value) {
                      print("这里是path page返回的数据 $value");
                      setState(() {
                        refresh();
                      });
                    });
                  },
                );
              } else {
                return Container();
              }
            },
            itemCount: list.length,
          );
        }
        return const Center(child: Text("暂无图片视频文件"));
      },
    );
  }
}
