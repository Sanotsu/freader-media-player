// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';

import 'specified_image_folder_page.dart';

/// 2024-01-13 重构
/// 针对图片和视频分开不同的模块，对于指定类型更加单纯地处理

class LocalPhoto extends StatefulWidget {
  const LocalPhoto({super.key});

  @override
  State<LocalPhoto> createState() => _LocalPhotoState();
}

class _LocalPhotoState extends State<LocalPhoto> {
  /// 这些都是媒体文件筛选条件:
  // 文件夹列表暂时默认排序为创建时间
  final List<OrderByItem> _orderBy = [
    OrderByItem.named(column: CustomColumns.base.createDate, isAsc: false),
  ];
  // 暂时过滤条件为空
  final List<WhereConditionItem> _where = [];
  // 用户可以有很多筛选条件(但暂时未启用)
  late CustomFilter filter;

  // 图片文件夹(aka相册)可以列表展示和网格展示，网格展示要有缩略图
  bool isGridMode = true;

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
      type: RequestType.image,
      filterOption: filter,
      hasAll: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    print("111 这是查询有媒体资源的主页面 index");
    return Scaffold(
      appBar: AppBar(
        title: const Text('本地图片'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.filter_list_sharp, color: Colors.black),
          ),
          // 列表或网格的切换
          IconButton(
            onPressed: () {
              setState(() {
                isGridMode = !isGridMode;
              });
            },
            icon: isGridMode
                ? const Icon(Icons.list)
                : const Icon(Icons.grid_3x3),
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(5.sp, 10.sp, 5, 10.sp),
        child: FutureBuilder<List<AssetPathEntity>>(
          future: refresh(),
          builder: (
            BuildContext context,
            AsyncSnapshot<List<AssetPathEntity>> snapshot,
          ) {
            if (snapshot.hasData) {
              List<AssetPathEntity> list = snapshot.data!;

              return isGridMode
                  ? _buildFolderGrid(list)
                  : _buildFolderList(list);
            }
            return const Center(child: Text("设备中暂无图片文件"));
          },
        ),
      ),
    );
  }

  _buildFolderList(List<AssetPathEntity> list) {
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (BuildContext context, int index) {
        final AssetPathEntity path = list[index];

        return ListTile(
          leading: Icon(Icons.folder, size: 56.sp),
          title: Text(path.name),
          subtitle: FutureBuilder<int>(
            future: path.assetCountAsync,
            builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
              if (snapshot.hasData) {
                return Text("${snapshot.data} 张图片");
              }
              return Container();
            },
          ),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                // 进入指定文件夹
                builder: (BuildContext ctx) =>
                    SpecifiedImageFolderPage(path: path),
              ),
            );
          },
        );
      },
    );
  }

  _buildFolderGrid(List<AssetPathEntity> list) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        // 一行3个格子
        crossAxisCount: 3,
        mainAxisSpacing: 10.0,
        crossAxisSpacing: 10.0,
        childAspectRatio: 2 / 3,
      ),
      itemCount: list.length,
      itemBuilder: (BuildContext context, int index) {
        final AssetPathEntity path = list[index];

        return GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                // 进入指定文件夹
                builder: (BuildContext ctx) =>
                    SpecifiedImageFolderPage(path: path),
              ),
            );
          },
          child: FutureBuilder<List<AssetEntity>>(
            future: getImageListOfPath(path),
            builder: (
              BuildContext context,
              AsyncSnapshot<List<AssetEntity>> snapshot,
            ) {
              // 2024-01-17 手动查询图片列表路径下数量，大于0的才展示
              return snapshot.hasData && snapshot.data!.isNotEmpty
                  ? Column(
                      children: [
                        Expanded(
                          flex: 2,
                          child: FutureBuilder<File?>(
                            future: snapshot.data![0].file,
                            builder: (
                              BuildContext context,
                              AsyncSnapshot<File?> ss,
                            ) {
                              if (ss.hasData) {
                                // return ClipRRect(
                                //   // 圆角的半径
                                //   borderRadius: BorderRadius.circular(10),
                                //   child: buildFileImage(
                                //     ss.data!,
                                //     fit: BoxFit.fill,
                                //   ),
                                // );
                                // return AspectRatio(
                                //   aspectRatio: 1,
                                //   child: buildFileImage(
                                //     ss.data!,
                                //     fit: BoxFit.cover,
                                //   ),
                                // );
                                /// 上面两个没法1：1宽高显示，这个可以
                                return Container(
                                  // width: 100,
                                  // height: 100,
                                  decoration: BoxDecoration(
                                    // 圆角的半径
                                    borderRadius: BorderRadius.circular(10),
                                    image: DecorationImage(
                                      image: FileImage(ss.data!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: ListTile(
                            // 注意，有一个name是空字符串的，那是最外层的文件夹
                            title: Text(
                              path.name != "" ? path.name : "手机根目录",
                              softWrap: true,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text("${snapshot.data!.length} 张图片"),
                          ),
                        )
                      ],
                    )
                  : const SizedBox();
            },
          ),
        );
      },
    );
  }

  // 获取指定路径中可播放的设备数量
  Future<List<AssetEntity>> getImageListOfPath(AssetPathEntity path) async {
    // 查询所有媒体实体列表（起止参数表示可以过滤只显示排序后中某一部分实体）
    return (await path.getAssetListRange(
      start: 0,
      end: (await path.assetCountAsync),
    ));
  }
}
