// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../../models/sort_option_selected.dart';
import 'common_small_widgets.dart';

// 展示排序的弹窗内容（不同tab弹窗可选择的栏位不一样）
enum MySortType {
  SONG,
  PLAYLIST,
  ARTIST,
  ALBUM,
}

// 升序还是降序
enum MyOrderType {
  ASC_OR_SMALLER, // 升序(从小到大)
  DESC_OR_GREATER, // 降序(从大到小)
}

// 音频可以排序的栏位（用于构建单选框时显示的标签和选取的值）
List songSortTypeList = [
  ["标题", SongSortType.TITLE],
  ["歌手", SongSortType.ARTIST],
  ["时长", SongSortType.DURATION],
  ["大小", SongSortType.SIZE],
  ["专辑", SongSortType.ALBUM],
  ["添加时间", SongSortType.DATE_ADDED],
  ["显示名称", SongSortType.DISPLAY_NAME],
];

// 歌单可以排序的栏位（用于构建单选框时显示的标签和选取的值）
List playlistSortTypeList = [
  ["歌单名称", PlaylistSortType.PLAYLIST],
  ["添加时间", PlaylistSortType.DATE_ADDED],
];

List artistSortTypeList = [
  ["歌手名称", ArtistSortType.ARTIST],
  ["歌手专辑量", ArtistSortType.NUM_OF_ALBUMS],
  ["歌手歌曲量", ArtistSortType.NUM_OF_TRACKS],
];

List albumSortTypeList = [
  ["专辑名称", AlbumSortType.ALBUM],
  ["专辑所属歌手", AlbumSortType.ARTIST],
  ["专辑歌曲数量", AlbumSortType.NUM_OF_SONGS],
];

// 显示排序选项的弹窗
buildSortOptionsDialog(
  BuildContext context,
  AudioOptionSelected aos,
  int currentTabIndex, // 当前tab索引，0-3对应歌单、全部音频、歌手、专辑
) {
  // 当前是哪一个tab(歌单、音频、歌手、专辑)需要排序，构建不同的弹窗内容
  List tempList;

  // 被选择的排序属性(model中有预设，选择之后也有更新，属于保留上一次的。但没有持久化)
  dynamic selectedSortType;

  switch (currentTabIndex) {
    case 1:
      tempList = songSortTypeList;
      selectedSortType = aos.songSortType;
      break;
    case 2:
      tempList = artistSortTypeList;
      selectedSortType = aos.artistSortType;
      break;
    case 3:
      tempList = albumSortTypeList;
      selectedSortType = aos.albumSortType;
      break;
    default:
      tempList = playlistSortTypeList;
      selectedSortType = aos.playlistSortType;
  }

  // 存储是升序还是降序(默认)
  OrderType orderType = aos.orderType;

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('排序'),
        // 排序选项内容和弹窗的标题与按钮上下间隔小一点
        contentPadding: EdgeInsets.symmetric(
          vertical: 0.sp,
          horizontal: 20.sp,
        ),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 0.3.sh,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: tempList.length,
                    itemBuilder: (BuildContext context, int index) {
                      return RadioListTile<dynamic>(
                        title: Text(
                          tempList[index][0],
                          style: TextStyle(fontSize: 13.sp),
                        ),
                        value: tempList[index][1],
                        groupValue: selectedSortType,
                        // dense: true,
                        // contentPadding: EdgeInsets.all(1.sp),
                        onChanged: (dynamic value) {
                          setState(() => selectedSortType = value);
                        },
                      );
                    },
                  ),
                ),
                Divider(
                  height: 10,
                  thickness: 2.sp,
                  indent: 2,
                  endIndent: 0,
                  color: Colors.grey,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // 大概48sp
                    LabeledRadio(
                      label: '升序',
                      padding: EdgeInsets.symmetric(horizontal: 1.sp),
                      value: OrderType.ASC_OR_SMALLER,
                      groupValue: orderType,
                      onChanged: (dynamic newValue) {
                        setState(() {
                          orderType = newValue;
                        });
                      },
                    ),
                    LabeledRadio(
                      label: '降序',
                      padding: EdgeInsets.symmetric(horizontal: 1.sp),
                      value: OrderType.DESC_OR_GREATER,
                      groupValue: orderType,
                      onChanged: (dynamic newValue) {
                        setState(() {
                          orderType = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: <Widget>[
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return TextButton(
                child: const Text('确认'),
                onPressed: () {
                  setState(() {
                    // ??? 2023-04-25左右 目前实测，歌单排序原插件接口无效
                    // 2024-01-10 还是v2.9.0版本，也不能用
                    if (currentTabIndex == 0) {
                      aos.changePlaylistSortType(selectedSortType);
                    }
                    if (currentTabIndex == 1) {
                      aos.changeSongSortType(selectedSortType);
                    }
                    if (currentTabIndex == 2) {
                      aos.changeArtistSortType(selectedSortType);
                    }
                    if (currentTabIndex == 3) {
                      aos.changeAlbumSortType(selectedSortType);
                    }
                    aos.changeOrderType(orderType);
                    Navigator.pop(context);
                  });
                },
              );
            },
          ),
        ],
      );
    },
  );
}
