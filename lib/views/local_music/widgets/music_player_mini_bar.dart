// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../../common/utils/global_styles.dart';
import '../../../services/my_audio_handler.dart';
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

  @override
  Widget build(BuildContext context) {
    print("----------------------------------");
    print(_audioHandler);

    return Card(
      elevation: 5,
      // color: Theme.of(context).primaryColor,
      color: dartThemeMaterialColor2,
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

                    return SimpleMarqueeOrText(
                      data: '${metadata.artist ?? "未知歌手"} -- ${metadata.title}',
                      style: TextStyle(fontSize: sizeHeadline2),
                      velocity: 50,
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
