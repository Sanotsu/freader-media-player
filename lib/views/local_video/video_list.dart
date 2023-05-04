import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../common/utils/tools.dart';
import 'widgets/image_item_widget.dart';
import 'video_player_screen.dart';

class VideoList extends StatelessWidget {
  const VideoList({Key? key, required this.list}) : super(key: key);

  final List<AssetEntity> list;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: list.length,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final AssetEntity entity = list[index];

        return ListTile(
          title: Text("${entity.title}"),
          subtitle: Text(
            "${formatDurationToString(entity.videoDuration)}",
          ),
          leading: Padding(
            padding: EdgeInsets.all(5.sp),
            child: SizedBox(
              height: 100.sp, // 为什么没有效果呢？
              width: 80.sp,
              child: ImageItemWidget(
                entity: entity,
                option: ThumbnailOption.ios(
                  size: const ThumbnailSize.square(500),
                ),
              ),
            ),
          ),
          onTap: () async {
            File? tempFile = await entity.file;

            if (tempFile != null) {
              // ignore: use_build_context_synchronously
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext ctx) {
                    return VideoPlayerScreen(file: tempFile);
                  },
                ),
              );
            }
          },
        );
      },
    );
  }
}
