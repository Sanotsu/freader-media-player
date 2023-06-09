// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';

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
    print("----------------------------------");
    print(_audioHandler);

    return Card(
      elevation: 5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () {
                print("tapped on 当前正在播放的音乐》StreamBuilder");
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext ctx) {
                      return const JustAudioMusicPlayer();
                    },
                  ),
                );
              },
              child: Center(
                child: StreamBuilder<SequenceState?>(
                  stream: _audioHandler.getSequenceStateStream(),
                  builder: (context, snapshot) {
                    final state = snapshot.data;

                    if (state?.sequence.isEmpty ?? true) {
                      print("mini bar 当前正在音频流为空----------");

                      return const SizedBox();
                    }

                    final metadata = state!.currentSource!.tag as MediaItem;

                    print("mini bar 当前正在播放的音乐》");
                    print(state.toString());
                    print(state.currentIndex);
                    print(metadata.id);

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
                              artworkBorder:
                                  const BorderRadius.all(Radius.zero),
                              artworkHeight: 40.sp,
                              artworkWidth: 40.sp,
                              artworkFit: BoxFit.cover,
                              keepOldArtwork: true, // 在生命周期内使用旧的缩略图
                              nullArtworkWidget:
                                  Icon(Icons.image_not_supported, size: 50.sp),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 11,
                          child: SimpleMarqueeOrText(
                            data:
                                '${metadata.artist ?? "未知歌手"} -- ${metadata.title}',
                            style: TextStyle(fontSize: sizeHeadline2),
                            velocity: 50,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),

          /// 每当播放器的状态发生变化时，这个StreamBuilder就会重建，这包括播放/暂停的状态，也包括加载/缓冲/准备的状态。
          /// 根据不同的状态，我们会显示相应的按钮或加载指示灯。
          Expanded(
            flex: 1,
            child: Center(
              child: StreamBuilder<PlayerState>(
                stream: _audioHandler.getPlayerStateStream(),
                builder: (context, snapshot) {
                  final playerState = snapshot.data;

                  final processingState = playerState?.processingState;
                  final playing = playerState?.playing;

                  print(
                      "mini bar 中 按钮状态的来源 playing $playing,processingState $processingState");

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
            ),
          ),
        ],
      ),
    );
  }
}
