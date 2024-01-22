// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../specified_image_folder_page.dart';

class FilterPathGrid extends StatelessWidget {
  final List<AssetPathEntity>? pathList;
  final CustomFilter filter;

  const FilterPathGrid({
    super.key,
    this.pathList,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    // return PathGridList(list: pathList);

    print("============进入 grid 页面的查询条件filter ${filter.makeWhere()}");

    if (pathList != null && pathList!.isNotEmpty) {
      return PathGridList(list: pathList!);
    }

    // 先按关键字查询所有路径列表
    return FutureBuilder<List<AssetPathEntity>>(
      future: PhotoManager.getAssetPathList(
        // hasAll: false,
        type: RequestType.image,
        filterOption: filter,
      ),
      builder: (
        BuildContext context,
        AsyncSnapshot<List<AssetPathEntity>> snapshot,
      ) {
        print("grid 中条件查询结果------snapshot.data: ${snapshot.data?.length} ");
        print("${snapshot.data}");

        if (snapshot.hasData) {
          // 因为路径列表中可能存在不是指定image类型的路径，所以还要进行过滤
          return FutureBuilder(
            future: filterPathListWithType(snapshot.data!),
            builder: (
              BuildContext context,
              AsyncSnapshot<List<AssetPathEntity>> ss,
            ) {
              print("grid 中条件查询结果------snapshot.data: ${ss.data?.length} ");
              print("${ss.data}");

              if (ss.hasData) {
                return PathGridList(list: ss.data!);
              }
              return const SizedBox();
            },
          );
        }
        // 还有一个是hasError和加载中，理论上不会有错了，就统一展示加载中
        // return const SizedBox();

        return buildErrorOrLoadingForFuture(snapshot);
      },
    );
  }
}

buildErrorOrLoadingForFuture(AsyncSnapshot<dynamic> snapshot) {
  var children = snapshot.hasError
      ? [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text('Error: ${snapshot.error}'),
          ),
        ]
      : [
          Container(
            color: Colors.amber,
            width: 60,
            height: 60,
            child: const CircularProgressIndicator(),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('Awaiting result...'),
          ),
        ];

  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    ),
  );
}

class PathGridList extends StatelessWidget {
  const PathGridList({super.key, required this.list});

  final List<AssetPathEntity> list;

  @override
  Widget build(BuildContext context) {
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
            future: getValidAssetFromPath(path),
            builder: (
              BuildContext context,
              AsyncSnapshot<List<AssetEntity>> snapshot,
            ) {
              print("指定路径知道类型后的数量-------------${snapshot.data?.length}");

              // 2024-01-17 手动查询图片列表路径下数量，大于0的才展示
              return snapshot.hasData && snapshot.data!.isNotEmpty
                  ? Column(
                      children: [
                        Expanded(
                          flex: 2,
                          // 有图片的才会显示，在路劲处显示第一张图片为预览图
                          child: FutureBuilder<File?>(
                            future: snapshot.data![0].file,
                            builder: (
                              BuildContext context,
                              AsyncSnapshot<File?> ss,
                            ) {
                              if (ss.hasData) {
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
                  : Container();
            },
          ),
        );
      },
    );
  }
}

// 获取指定路径下指定类型的资源列表
Future<List<AssetEntity>> getValidAssetFromPath(
  AssetPathEntity path, {
  AssetType type = AssetType.image,
}) async {
  final count = await path.assetCountAsync;

  // 查询所有媒体实体列表（起止参数表示可以过滤只显示排序后中某一部分实体）
  final list = await path.getAssetListRange(start: 0, end: count);

  // 2024-01-17 过滤无法播放的适配
  list.removeWhere((element) => element.type != type);

  return list;
}

// 过滤指定类型的path列表(不过滤的话像grid建立时有空白占位)
Future<List<AssetPathEntity>> filterPathListWithType(
  List<AssetPathEntity> list, {
  AssetType type = AssetType.image,
}) async {
  // 处理后新的资源路径实例列表
  List<AssetPathEntity> newList = [];

  // 遍历旧的path实例，清除里面不属于指定类型的资源
  for (var path in list) {
    var assetList = await getValidAssetFromPath(path, type: type);

    // 如果过滤后的路径下还有资源，则把该路径实例，放入新列表中
    if (assetList.isNotEmpty) {
      newList.add(path);
    }
  }

  return newList;
}
