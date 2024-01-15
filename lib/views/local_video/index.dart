// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'specified_video_folder_page.dart';

/// 2024-01-13 重构
/// 针对图片和视频分开不同的模块，对于指定类型更加单纯地处理
///
///

class LocalVideo extends StatefulWidget {
  const LocalVideo({super.key});

  @override
  State<LocalVideo> createState() => _LocalVideoState();
}

class _LocalVideoState extends State<LocalVideo> {
  /// 这些都是媒体文件筛选条件:
  // 文件夹列表暂时默认排序为创建时间
  final List<OrderByItem> _orderBy = [
    OrderByItem.named(column: CustomColumns.base.createDate, isAsc: false),
  ];
  // 暂时过滤条件为空
  final List<WhereConditionItem> _where = [];
  // 用户可以有很多筛选条件(但暂时未启用)
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

  // 获取指定文件夹中的媒体文件
  Future<List<AssetPathEntity>> refresh() async {
    return PhotoManager.getAssetPathList(
      type: RequestType.video,
      filterOption: filter,
      hasAll: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    print("111 这是查询有媒体资源的主页面 index");
    return Scaffold(
      appBar: AppBar(
        title: const Text('本地视频'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.filter_list_sharp),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<AssetPathEntity>>(
              future: refresh(),
              builder: (
                BuildContext context,
                AsyncSnapshot<List<AssetPathEntity>> snapshot,
              ) {
                if (snapshot.hasData) {
                  print("getAssetPathList查询的结果${snapshot.data!}");

                  List<AssetPathEntity> list = snapshot.data!;

                  return _buildMediaFolderList(list);
                }
                return const Center(child: Text("设备中暂无图片文件"));
              },
            ),
          ),
        ],
      ),
    );
  }

  _buildMediaFolderList(List<AssetPathEntity> list) {
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (BuildContext context, int index) {
        final AssetPathEntity path = list[index];

        if (path.name.toLowerCase() != "recent") {
          return ListTile(
            title: Text(path.name),
            subtitle: FutureBuilder<int>(
              future: path.assetCountAsync,
              builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                if (snapshot.hasData) {
                  // print("构建文件夹中数量:${path.name}-${snapshot.data}");
                  // ??? 2023-05-19 这个数值和实际的总是可能对不上，原因不明
                  return Text("${snapshot.data} 个视频");
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
                      SpecifiedVideoFolderPage(path: path, pathList: list),
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
    );
  }
}
