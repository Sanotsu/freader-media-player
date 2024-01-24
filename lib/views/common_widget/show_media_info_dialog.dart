import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../common/utils/tools.dart';

showMediaInfoDialog(AssetEntity entity, BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        insetPadding: EdgeInsets.only(left: 10, right: 10.sp),
        child: Container(
          color: Colors.white,
          height: 400,
          child: Column(
            children: [
              SizedBox(
                height: 50.sp,
                child: Center(
                  child: Text("详情", style: TextStyle(fontSize: 20.sp)),
                ),
              ),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(horizontal: 5.sp),
                  itemExtent: 50.sp,
                  children: <Widget>[
                    ListTile(
                      title: const Text("文件名称"),
                      subtitle: Text(
                        "${entity.title}",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      dense: true,
                    ),
                    ListTile(
                      title: const Text("文件类型"),
                      subtitle: Text("${entity.mimeType}"),
                      dense: true,
                    ),
                    ListTile(
                      title: const Text("文件路径"),
                      subtitle: Text(
                        "${entity.relativePath}\n${entity.relativePath}",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      dense: true,
                    ),
                    ListTile(
                      title: const Text("修改时间"),
                      subtitle: Text("${entity.modifiedDateTime}"),
                      dense: true,
                    ),
                    if (entity.type == AssetType.video)
                      ListTile(
                        title: const Text("视频时长"),
                        subtitle: Text("${entity.videoDuration}"),
                        dense: true,
                      ),
                    if (entity.type == AssetType.audio)
                      ListTile(
                        title: const Text("音频时长"),
                        subtitle: Text("${Duration(seconds: entity.duration)}"),
                        dense: true,
                      ),
                    if (entity.type == AssetType.video ||
                        entity.type == AssetType.image)
                      ListTile(
                        title: const Text("文件尺寸"),
                        subtitle: Text("${entity.size}"),
                        dense: true,
                      ),
                    ListTile(
                      title: const Text("文件大小"),
                      subtitle: FutureBuilder<File?>(
                        future: entity.file,
                        builder: (BuildContext context,
                            AsyncSnapshot<File?> snapshot) {
                          // 其实分为hasData、hasError、加载中几个情况。
                          return (snapshot.hasData)
                              ? Text(
                                  "${getFileSize(snapshot.data?.statSync().size ?? 0, 2)} (${snapshot.data?.statSync().size} Byte)",
                                )
                              : const SizedBox();
                        },
                      ),
                      dense: true,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 60.sp,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 10.sp),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        textStyle: Theme.of(context).textTheme.labelLarge,
                      ),
                      child: const Text('确认'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
