// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';

import '../local_media/widgets/image_item_widget.dart';
import 'path_media_page.dart';

/// 页面层级关系: 主页面 > 含有图片/视频的文件夹路径 > 该指定文件夹中的图片/视频列表 > 点击查看图片/播放视频
///
/// 图片视频页面的层级应该是这样:
///   所有的图片/视频文件夹列表 (index)
///     - 切换仅图片/仅视频时，重新查询文件夹列表
///     - 点击某个文件夹项次时，进入文件夹中，显示文件夹中的媒体文件列表 (folderIndex/旧PathPage)
///         - 点击某个具体图片/视频，进入图片浏览/视频播放页面

class LocalAllMedia extends StatefulWidget {
  const LocalAllMedia({super.key});

  @override
  State<LocalAllMedia> createState() => _LocalAllMediaState();
}

class _LocalAllMediaState extends State<LocalAllMedia> {
  // 用户可以有很多筛选条件(但暂时未启用)
  late CustomFilter filter;

  // 是否点击了搜索图表
  bool _iSClickSearch = false;
  // 图片文件夹(aka相册)可以列表展示和网格展示，网格展示要有缩略图
  bool isGridMode = true;

  // 默认查询图片和视频，可切换其他类别
  RequestType selectedRequestType = RequestType.common;
  // 默认查询所有，可关键字筛选
  String queryKeywork = "";

  @override
  void initState() {
    super.initState();
    filter = createFilter();
  }

  // 2024-01-19使用这个查询条件，目前能运行，但是getAssetPathList()调用时指定的type无效
  // 比如我指定了 type: RequestType.image，结果还是有音频和视频
  CustomFilter createFilter() {
    final group = WhereConditionGroup().and(
      ColumnWhereCondition(
        column: CustomColumns.android.title,
        value: """'%${queryKeywork.trim()}%'""",
        operator: 'like',
      ),
    );

    // 这里安卓和ios在图片类型时mediaType都是 1，视频和音频时，略有不同(注意：mediaType的值是number)
    if (selectedRequestType == RequestType.image) {
      // group.andText('${CustomColumns.base.mediaType} = 1 ');
      group.andText(_genMediaTypeText('= 1'));
    } else if (selectedRequestType == RequestType.audio) {
      group.andText(_genMediaTypeText('= ${Platform.isAndroid ? 2 : 3}'));
    } else if (selectedRequestType == RequestType.video) {
      group.andText(_genMediaTypeText('= ${Platform.isAndroid ? 3 : 2}'));
    } else if (selectedRequestType == RequestType.common) {
      group.andText(_genMediaTypeText('IN (2,3)'));
    } else {
      // 这里虽然除了全部还有其他类别，但不再细分
      // group.andText('${CustomColumns.base.mediaType} IN (1,2,3)');
      group.andText(_genMediaTypeText('IN (1,2,3)'));
    }

    final filter = AdvancedCustomFilter()
        .addWhereCondition(group)
        .addOrderBy(column: CustomColumns.base.createDate, isAsc: false);
    return filter;
  }

  _genMediaTypeText(String padding) {
    return '${CustomColumns.base.mediaType} $padding';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: (!_iSClickSearch)
            ? const Text('本地相册')
            : TextField(
                onChanged: (String inputStr) {
                  setState(() {
                    queryKeywork = inputStr;
                    filter = createFilter();
                  });
                },
                autofocus: true,
                cursorColor: Colors.white,
                style: const TextStyle(color: Colors.white),
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  // 搜索框不显示下划线
                  border: InputBorder.none,
                  hintText: '输入标题关键字',
                ),
              ),
        actions: [
          _iSClickSearch
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _iSClickSearch = false;
                      // 重置查询关键字为空，查询所有
                      queryKeywork = "";
                      filter = createFilter();
                    });
                  })
              : IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _iSClickSearch = true;
                    });
                  },
                ),
          // Row(
          //   crossAxisAlignment: CrossAxisAlignment.center,
          //   mainAxisAlignment: MainAxisAlignment.end,
          //   children: [
          //     // 下拉按钮，切换报告的时间范围
          //     buildDropdownButton(),
          //   ],
          // ),
          // 选择媒体资源类型
          // 查询时指定的type没有用，就在sql中拼接
          PopupMenuButton<RequestType>(
            // icon: const Icon(Icons.filter_list),
            icon: Icon(
              selectedRequestType == RequestType.common
                  ? Icons.perm_media
                  : selectedRequestType == RequestType.image
                      ? Icons.image
                      : selectedRequestType == RequestType.audio
                          ? Icons.audiotrack
                          : selectedRequestType == RequestType.video
                              ? Icons.video_file
                              : Icons.filter_list,
            ),
            initialValue: selectedRequestType,
            onSelected: (RequestType item) {
              setState(() {
                // 只改变了类型，关键字还保留旧的
                selectedRequestType = item;
                filter = createFilter();
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<RequestType>(
                value: RequestType.all,
                child: Text('全部'),
              ),
              const PopupMenuItem<RequestType>(
                value: RequestType.common,
                child: Text('图片和视频'),
              ),
              const PopupMenuItem<RequestType>(
                value: RequestType.image,
                child: Text('仅图片'),
              ),
              const PopupMenuItem<RequestType>(
                value: RequestType.audio,
                child: Text('仅音频'),
              ),
              const PopupMenuItem<RequestType>(
                value: RequestType.video,
                child: Text('仅视频'),
              ),
            ],
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
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 10.sp),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(5.sp),
              child: _buildMediaFolderList(filter, isGridMode),
            ),
          ),
        ],
      ),
    );
  }

  buildDropdownButton() {
    return DropdownButton(
      borderRadius: BorderRadius.all(Radius.circular(10.sp)),
      // 默认背景是白色，但我需要字体默认是白色，和appbar中其他保持一致，那么背景色改为灰色
      dropdownColor: const Color.fromARGB(255, 124, 96, 96),
      isDense: true,
      items: [
        RequestType.all,
        RequestType.common,
        RequestType.image,
        RequestType.audio,
        RequestType.video,
      ]
          .map<DropdownMenuItem<RequestType>>(
            (RequestType value) => DropdownMenuItem<RequestType>(
              value: value,
              child: Text(
                (value.toString()),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          )
          .toList(),
      value: selectedRequestType,
      onChanged: (RequestType? newValue) {
        setState(() {
          // 只改变了类型，关键字还保留旧的
          // 修改下拉按钮的显示值,
          selectedRequestType = newValue!;
          filter = createFilter();
        });
      },
      isExpanded: false,
      // 将下划线设置为空的Container
      underline: Container(),
    );
  }
}

_buildMediaFolderList(filter, isGridMode) {
  return FutureBuilder<List<AssetPathEntity>>(
    future: PhotoManager.getAssetPathList(
      type: RequestType.all,
      filterOption: filter,
      hasAll: false,
    ),
    builder: (
      BuildContext context,
      AsyncSnapshot<List<AssetPathEntity>> snapshot,
    ) {
      if (snapshot.hasData) {
        print("getAssetPathList查询的结果${snapshot.data!}");

        List<AssetPathEntity> list = snapshot.data!;
        return isGridMode ? _buildGrid(list) : _buildList(list);
      }
      return const Center(child: Text("暂无媒体资源文件"));
    },
  );
}

_buildList(List<AssetPathEntity> list) {
  return ListView.builder(
    itemCount: list.length,
    itemBuilder: (BuildContext context, int index) {
      // 相册和文件夹的抽象化。
      // 它代表了Android上的 "MediaStore"中的一个buket，
      // 以及iOS/MacOS上的 "PHAssetCollection"对象。
      final AssetPathEntity path = list[index];

      return ListTile(
        title: Text(
          path.name.toLowerCase() == "recent"
              ? "全部"
              : path.name != ""
                  ? path.name
                  : "手机根目录",
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: FutureBuilder<int>(
          future: path.assetCountAsync,
          builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
            // 其实分为hasData、hasError、加载中几个情况。
            return (snapshot.hasData)
                ? Text("${snapshot.data} 个资源")
                : const SizedBox();
          },
        ),
        leading: Icon(Icons.folder, size: 56.sp),
        // trailing: FutureBuilder<int>(
        //   future: path.assetCountAsync,
        //   builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        //     // 其实分为hasData、hasError、加载中几个情况。
        //     return (snapshot.hasData)
        //         ? Text("${snapshot.data} 个资源")
        //         : const SizedBox();
        //   },
        // ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              // 进入指定文件夹
              builder: (BuildContext ctx) =>
                  PathMediaPage(path: path, pathList: list),
            ),
          ).then((value) {
            // 返回时收起键盘
            FocusScope.of(context).requestFocus(FocusNode());
          });
        },
      );
    },
  );
}

_buildGrid(List<AssetPathEntity> list) {
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              // 进入指定文件夹
              builder: (BuildContext ctx) =>
                  PathMediaPage(path: path, pathList: list),
            ),
          ).then((value) {
            FocusScope.of(context).requestFocus(FocusNode());
          });
        },
        child: Column(
          children: [
            Expanded(
              flex: 2,
              // 有图片的才会显示，在路径处显示第一张图片为预览图
              child: FutureBuilder<List<AssetEntity>>(
                future: path.getAssetListRange(start: 0, end: 1),
                builder: (BuildContext context,
                    AsyncSnapshot<List<AssetEntity>> snapshot) {
                  // 其实分为hasData、hasError、加载中几个情况。
                  return (snapshot.hasData)
                      ? ImageItemWidget(
                          entity: snapshot.data![0],
                          option: ThumbnailOption.ios(
                            size: const ThumbnailSize.square(500),
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
                  path.name != "" ? path.name : "手机根目录",
                  softWrap: true,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.sp),
                ),
                subtitle: FutureBuilder<int>(
                  future: path.assetCountAsync,
                  builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                    // 其实分为hasData、hasError、加载中几个情况。
                    return (snapshot.hasData)
                        ? Text(
                            "${snapshot.data} 个资源",
                            style: TextStyle(fontSize: 10.sp),
                          )
                        : const SizedBox();
                  },
                ),
              ),
            )
          ],
        ),
      );
    },
  );
}
