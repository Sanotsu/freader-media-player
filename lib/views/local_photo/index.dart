import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';

import 'path_image_page.dart';

/// 2024-01-13 重构
/// 针对图片和视频分开不同的模块，对于指定类型更加单纯地处理
/// 2024-01-25
/// 实际上本地图片和本地视频模块的功能，已经在“全部资源”模块中都有了，甚至更丰富
/// 所以这两个模块就简单展示全部数据，其他功能都不保留了，毕竟是重复的

class LocalPhoto extends StatefulWidget {
  const LocalPhoto({super.key});

  @override
  State<LocalPhoto> createState() => _LocalPhotoState();
}

class _LocalPhotoState extends State<LocalPhoto> {
  // 图片文件夹(aka相册)可以列表展示和网格展示，网格展示要有缩略图
  bool isGridMode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('本地图片'),
        actions: [
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
          // 2024-01-25 注意事项和本地视频模块一致
          future: PhotoManager.getAssetPathList(
            type: RequestType.image,
            filterOption: AdvancedCustomFilter(
              orderBy: [
                OrderByItem.named(
                  column: CustomColumns.base.createDate,
                  isAsc: false,
                ),
              ],
            ),
            hasAll: false,
          ),
          builder: (
            BuildContext context,
            AsyncSnapshot<List<AssetPathEntity>> snapshot,
          ) {
            return (snapshot.hasData)
                ? isGridMode
                    ? _buildFolderGrid(snapshot.data!)
                    : _buildFolderList(snapshot.data!)
                : const Center(child: Text("设备中暂无图片文件"));
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
              return (snapshot.hasData)
                  ? Text("${snapshot.data} 张图片")
                  : Container();
            },
          ),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                // 进入指定文件夹
                builder: (BuildContext ctx) => PathImagePage(path: path),
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
                builder: (BuildContext ctx) => PathImagePage(path: path),
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
                              /// 这个可以1：1宽高显示
                              return (ss.hasData)
                                  ? Container(
                                      decoration: BoxDecoration(
                                        // 圆角的半径
                                        borderRadius: BorderRadius.circular(10),
                                        image: DecorationImage(
                                          image: FileImage(ss.data!),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  : const SizedBox();
                            },
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: ListTile(
                            // 注意，有一个name是空字符串的，那是最外层的文件夹
                            title: Text(
                              path.name != "" ? path.name : "设备根目录",
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
