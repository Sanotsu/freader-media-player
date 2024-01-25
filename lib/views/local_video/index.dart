import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';

import 'path_video_page.dart';

/// 2024-01-13 重构
/// 针对图片和视频分开不同的模块，对于指定类型更加单纯地处理
/// 2024-01-25
/// 实际上本地图片和本地视频模块的功能，已经在“全部资源”模块中都有了，甚至更丰富
/// 所以这两个模块就简单展示全部数据，其他功能都不保留了，毕竟是重复的
///
class LocalVideo extends StatefulWidget {
  const LocalVideo({super.key});

  @override
  State<LocalVideo> createState() => _LocalVideoState();
}

class _LocalVideoState extends State<LocalVideo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('本地视频'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<AssetPathEntity>>(
              future: PhotoManager.getAssetPathList(
                type: RequestType.video,
                filterOption: AdvancedCustomFilter(
                  // 2023-01-25 文件夹列表暂时默认排序为创建时间(其他where条件和type不能共存生效，就不管了)
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
                    ? _buildMediaFolderList(snapshot.data!)
                    : const Center(child: Text("设备中暂无图片文件"));
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

        return FutureBuilder<int>(
          future: getPlayableVideoCount(path),
          builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
            // 2024-01-17 手动查询视频列表路径下可播放的视频数量，大于0的才展示
            return snapshot.hasData && snapshot.data! > 0
                ? ListTile(
                    leading: Icon(Icons.folder, size: 56.sp),
                    // 注意，有一个name是空字符串的，那是最外层的文件夹
                    title: Text(path.name != "" ? path.name : "设备根目录"),
                    subtitle: Text("${snapshot.data} 个视频"),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          // 进入指定文件夹
                          builder: (BuildContext ctx) =>
                              PathVideoPage(path: path),
                        ),
                      );
                    },
                  )
                : const SizedBox();
          },
        );
      },
    );
  }

  // 获取指定路径中可播放的设备数量
  Future<int> getPlayableVideoCount(AssetPathEntity path) async {
    final count = await path.assetCountAsync;
    if (count == 0) return 0;

    // 查询所有媒体实体列表（起止参数表示可以过滤只显示排序后中某一部分实体）
    final list = await path.getAssetListRange(start: 0, end: count);

    // 2024-01-17 过滤无法播放的视频
    list.removeWhere((element) => element.videoDuration == Duration.zero);

    return list.length;
  }
}
