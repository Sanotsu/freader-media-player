// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';

import '../specified_image_folder_page.dart';
import 'path_grid.dart';

class FilterPathList extends StatelessWidget {
  final CustomFilter filter;

  const FilterPathList({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    print("============进入列表页面的查询条件filter $filter");

    return FutureBuilder<List<AssetPathEntity>>(
      future: PhotoManager.getAssetPathList(
        hasAll: false,
        // 2024-01-19 为什么这个类型没生效？
        type: RequestType.image,
        filterOption: filter,
      ),
      builder: (
        BuildContext context,
        AsyncSnapshot<List<AssetPathEntity>> snapshot,
      ) {
        if (snapshot.hasData) {
          print("列表中的数量-------${snapshot.data?.length}");

          return PathTileList(list: snapshot.data!);
        }
        return const SizedBox();
      },
    );
  }
}

class PathTileList extends StatelessWidget {
  const PathTileList({super.key, required this.list});

  final List<AssetPathEntity> list;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
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
              // 2024-01-17 手动查询图片列表路径下数量，大于0的才展示
              return snapshot.hasData && snapshot.data!.isNotEmpty
                  ? ListTile(
                      leading: Icon(Icons.folder, size: 56.sp),
                      title: Text(path.name),
                      subtitle: Text(path.id),
                      trailing: Text("${snapshot.data!.length} 张图片"),
                    )
                  : const SizedBox();
            },
          ),
        );
      },
      itemCount: list.length,
    );
  }
}
