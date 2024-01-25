import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/global_styles.dart';
import '../../../services/my_audio_handler.dart';
import '../../../services/my_audio_query.dart';
import '../../../services/service_locator.dart';
import '../nested_pages/just_audio_music_player_detail.dart';
import 'common_small_widgets.dart';

///  当前音乐播放条，只显示名称和暂停/开始按钮
class MusicPlayerMiniBar extends StatefulWidget {
  const MusicPlayerMiniBar({super.key});

  @override
  State<MusicPlayerMiniBar> createState() => _MusicPlayerMiniBarState();
}

class _MusicPlayerMiniBarState extends State<MusicPlayerMiniBar> {
  final _audioHandler = getIt<MyAudioHandler>();
  // 获取查询音乐组件实例
  final _audioQuery = getIt<MyAudioQuery>();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(flex: 3, child: _buildMusicInfoArea()),

          /// 每当播放器的状态发生变化时，这个StreamBuilder就会重建，这包括播放/暂停的状态，也包括加载/缓冲/准备的状态。
          /// 根据不同的状态，我们会显示相应的按钮或加载指示灯。
          Expanded(flex: 1, child: _buildPlayButtonArea()),
        ],
      ),
    );
  }

  /// 构建mini bar中当前播放音乐信息(音频缩略图和歌曲名称)
  _buildMusicInfoArea() {
    // 点击音频图标或文本会进入播放详情页；但点击播放/暂停等按钮就是对音频播放进行操作，不用进详情页
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext ctx) => const JustAudioMusicPlayer(),
          ),
        );
      },
      child: Center(
        child: StreamBuilder<SequenceState?>(
          stream: _audioHandler.getSequenceStateStream(),
          builder: (context, snapshot) {
            final state = snapshot.data;

            if (state?.sequence.isEmpty ?? true) {
              return const SizedBox(child: Text("<暂无播放>"));
            }

            final metadata = state!.currentSource!.tag as MediaItem;

            return Row(
              children: [
                // 图标占整个宽度的1/5 / (3/(3+1)) = 4/15,即 4/(4+9)
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(15, 2, 15, 2.sp),
                    child: QueryArtworkWidget(
                      controller: _audioQuery.onAudioQueryController,
                      // 显示根据歌手id查询的歌手图片
                      id: int.parse(metadata.id),
                      type: ArtworkType.AUDIO,
                      // 缩略图不显示圆角
                      artworkBorder: const BorderRadius.all(Radius.zero),
                      artworkHeight: 40.sp,
                      artworkWidth: 40.sp,
                      artworkFit: BoxFit.cover,
                      keepOldArtwork: true, // 在生命周期内使用旧的缩略图
                      // nullArtworkWidget: Icon(
                      //   Icons.image_not_supported,
                      //   size: 50.sp,
                      // ),
                      nullArtworkWidget: CircleAvatar(
                        // 设置圆形的半径
                        radius: 25.sp,
                        // 图像的路径
                        backgroundImage: const AssetImage(placeholderImageUrl),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 11,
                  child: SimpleMarqueeOrText(
                    data: '${metadata.artist ?? "未知歌手"} -- ${metadata.title}',
                    style: TextStyle(fontSize: sizeHeadline2),
                    velocity: 50,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 构建mini bar中对音频播放进行暂停、继续的点击按钮
  _buildPlayButtonArea() {
    return Center(
      child: StreamBuilder<PlayerState>(
        stream: _audioHandler.getPlayerStateStream(),
        builder: (context, snapshot) {
          final playerState = snapshot.data;

          // 根据音频播放进程和播放状态来确定分别显示什么图标
          final processingState = playerState?.processingState;
          final playing = playerState?.playing;

          final buttonSize = 36.sp;

          if (processingState == ProcessingState.loading ||
              processingState == ProcessingState.buffering) {
            return Container(
              margin: EdgeInsets.all(2.sp),
              width: buttonSize,
              height: buttonSize,
              child: const CircularProgressIndicator(),
            );
          } else if (playing != true) {
            return IconButton(
              icon: const Icon(Icons.play_arrow),
              iconSize: buttonSize,
              onPressed: () => _audioHandler.play(),
            );
          } else if (processingState != ProcessingState.completed) {
            return IconButton(
              icon: const Icon(Icons.pause),
              iconSize: buttonSize,
              onPressed: () => _audioHandler.pause(),
            );
          } else {
            return IconButton(
              icon: const Icon(Icons.replay),
              iconSize: buttonSize,
              onPressed: () => _audioHandler.seek(Duration.zero),
            );
          }
        },
      ),
    );
  }
}
