import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';

import 'path_page.dart';

class FilterPathList extends StatelessWidget {
  final CustomFilter filter;

  const FilterPathList({Key? key, required this.filter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AssetPathEntity>>(
      future: PhotoManager.getAssetPathList(
        // type: RequestType.video, // 默认的common只有图片和视频
        filterOption: filter,
      ),
      builder: (
        BuildContext context,
        AsyncSnapshot<List<AssetPathEntity>> snapshot,
      ) {
        if (snapshot.hasData) {
          return PathList(list: snapshot.data!);
        }
        return const SizedBox();
      },
    );
  }
}

class PathList extends StatelessWidget {
  const PathList({
    Key? key,
    required this.list,
  }) : super(key: key);

  final List<AssetPathEntity> list;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (BuildContext context, int index) {
        // 相册和文件夹的抽象化。它代表了Android上的 "MediaStore "中的一个桶，以及iOS/MacOS上的 "PHAssetCollection "对象。
        final AssetPathEntity path = list[index];

        if (path.name.toLowerCase() != "recent") {
          return ListTile(
            title: Text(path.name),
            subtitle: Text(path.id),
            leading: Icon(Icons.folder, size: 50.sp),
            trailing: FutureBuilder<int>(
              future: path.assetCountAsync,
              builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                if (snapshot.hasData) {
                  return Text("${snapshot.data} 个媒体文件");
                }
                return const SizedBox();
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PathPage(path: path),
                ),
              );
            },
          );
        } else {
          return Container();
        }
      },
      itemCount: list.length,
    );
  }
}
