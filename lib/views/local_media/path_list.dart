// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';

import 'path_page.dart';

/// 展示有媒体资源的路径（文件夹）列表
class MediaPathList extends StatefulWidget {
  const MediaPathList(
      {super.key, required this.filter, required this.requestType});

  final CustomFilter filter;
  final RequestType requestType;

  @override
  State<MediaPathList> createState() => _MediaPathListState();
}

class _MediaPathListState extends State<MediaPathList> {
  // 获取指定文件夹中的媒体文件
  Future<List<AssetPathEntity>> refresh() async {
    return PhotoManager.getAssetPathList(
      type: widget.requestType, // 默认的common只有图片和视频
      filterOption: widget.filter,
      hasAll: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    print("222 这是查询到的媒体资源结果列表 FilterPathList");

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
                  subtitle: Text(path.id),
                  leading: Icon(Icons.folder, size: 50.sp),
                  // trailing: Text("${path.isAll}"),
                  trailing: FutureBuilder<int>(
                    future: path.assetCountAsync,
                    builder:
                        (BuildContext context, AsyncSnapshot<int> snapshot) {
                      if (snapshot.hasData) {
                        print("构建文件夹中数量:${path.name}-${snapshot.data}");
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
        return const SizedBox();
      },
    );
  }
}
