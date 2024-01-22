// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'with_filter/path_grid.dart';
import 'with_filter/path_list.dart';

class CustomFilterPhoto extends StatefulWidget {
  const CustomFilterPhoto({super.key});

  @override
  State<CustomFilterPhoto> createState() => _CustomFilterPhotoState();
}

class _CustomFilterPhotoState extends State<CustomFilterPhoto> {
  late CustomFilter filter;

  // 图片文件夹(aka相册)可以列表展示和网格展示，网格展示要有缩略图
  bool isGridMode = true;

  // 是否点击了搜索图表
  bool _iSClickSearch = false;

  bool isLoading = false;

  late List<AssetPathEntity> pathList;

  @override
  void initState() {
    super.initState();

    // 2024-01-22 本来想这里查询到list处理之后给子页面显示，但是太慢了
    // 还是因为条件查询时asset类型和关键字不能同时生效，还没人提issue
    setState(() {
      queryPathList();
    });

    filter = createFilter();
  }

  // 2024-01-19使用这个查询条件，目前能运行，但是getAssetPathList()调用时指定的type无效
  // 比如我指定了 type: RequestType.image，结果还是有音频和视频
  CustomFilter createFilter({String? keyword}) {
    final group = WhereConditionGroup().and(
      ColumnWhereCondition(
        column: CustomColumns.android.title,
        value: """'%${keyword ?? ''}%'""",
        operator: 'like',
      ),
    );
    // .or(
    //   ColumnWhereCondition(
    //     column: CustomColumns.base.height,
    //     value: '200',
    //     operator: '>',
    //   ),
    // );
    final filter = AdvancedCustomFilter()
        .addWhereCondition(group)
        .addOrderBy(column: CustomColumns.base.createDate, isAsc: false);
    return filter;
  }

  // ----------非常耗时-------------
  // 2024-01-22 非常耗时，可能因为有3处await，还有for循环的await
  queryPathList({String? keyword}) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    print("77777777777777777开始加载 ${DateTime.now().microsecondsSinceEpoch}");

    // 2024-01-19使用这个查询条件，目前能运行，但是getAssetPathList()调用时指定的type无效
    // 比如我指定了 type: RequestType.image，结果还是有音频和视频
    final group = WhereConditionGroup().and(
      ColumnWhereCondition(
        column: CustomColumns.android.title,
        value: """'%${keyword ?? ''}%'""",
        operator: 'like',
      ),
    );
    final cusFilter = AdvancedCustomFilter()
        .addWhereCondition(group)
        .addOrderBy(column: CustomColumns.base.createDate, isAsc: false);

    List<AssetPathEntity> list = await PhotoManager.getAssetPathList(
      hasAll: false,
      type: RequestType.image,
      filterOption: cusFilter,
    );

    var tempList = await filterPathListWithType(list, type: AssetType.image);

    setState(() {
      pathList = tempList;
      // filter = cusFilter;
      isLoading = false;
      print("8888888888888结束加载 ${DateTime.now().microsecondsSinceEpoch}");
    });
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
                    // queryPathList(keyword: inputStr);
                    filter = createFilter(keyword: inputStr);
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
                      // queryPathList();
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: isGridMode
                      ? FilterPathGrid(pathList: pathList, filter: filter)
                      // ? FilterPathGrid(filter: filter)
                      : FilterPathList(filter: filter),
                ),
              ],
            ),
    );
  }
}
