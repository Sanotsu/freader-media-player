// ignore_for_file: avoid_print

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../../services/my_audio_handler.dart';
import '../../../services/service_locator.dart';
import 'common.dart';

/// 音乐播放器主界面
/// 本地音乐或者之后在线音乐，不管从哪里点击音乐，都进入到此音乐播放详情页面
/// 因此需要传入音乐信息用于播放

class JustAudioMusicPlayer extends StatefulWidget {
  const JustAudioMusicPlayer({Key? key}) : super(key: key);

  @override
  JustAudioMusicPlayerState createState() => JustAudioMusicPlayerState();
}

class JustAudioMusicPlayerState extends State<JustAudioMusicPlayer>
    with WidgetsBindingObserver {
  final _audioHandler = getIt<MyAudioHandler>();

  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();

    print("==============================");

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
  }

  // 如果这里处理掉player了，那么切换到其他页面后，自然就停止播放了。
  // 此外，也需要注意全局同一个player实例，否则背景播放可能会出问题
  // @override
  // void dispose() {
  //   _player.dispose();
  //   super.dispose();
  // }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // 在不使用时释放播放器的资源。使用 "stop"，则可以如果应用程序稍后恢复，它仍会记得从哪个位置恢复。
      _audioHandler.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // 如果指定了scaffoldMessengerKey ，则可以直接操作ScaffoldMessenger
      //    该类提供了API，用于在屏幕的底部和顶部分别显示点心条和材料横幅。
      scaffoldMessengerKey: _scaffoldMessengerKey,
      home: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// 正在播放的音频区域函数
              Expanded(
                flex: 4,
                child: StreamBuilder<SequenceState?>(
                  stream: _audioHandler.getSequenceStateStream(),
                  builder: (context, snapshot) {
                    final state = snapshot.data;

                    print("当前正在播放的音乐》");
                    print(state.toString());

                    if (state?.sequence.isEmpty ?? true) {
                      return const SizedBox();
                    }
                    final metadata = state!.currentSource!.tag as MediaItem;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: QueryArtworkWidget(
                              id: int.parse(metadata.id),
                              type: ArtworkType.AUDIO,
                              artworkWidth: 1.sw,
                              artworkHeight: 20.sp,
                              size: 100,
                            ),
                          ),
                        ),
                        Text(metadata.album ?? "未知专辑",
                            style: Theme.of(context).textTheme.titleLarge),
                        Text(metadata.title),
                      ],
                    );
                  },
                ),
              ),

              /// 分割占位
              Expanded(
                flex: 1,
                child: SizedBox(height: 8.sp),
              ),

              /// 音频控制按钮区域
              Expanded(
                flex: 1,
                child: ControlButtons(),
                // child: MiniMusicPlayerBar(),
              ),

              /// 音频拖动进度条
              Expanded(
                flex: 1,
                child: StreamBuilder<PositionData>(
                  // 当前播放位置音频数据
                  stream: _audioHandler.positionDataStream,
                  builder: (context, snapshot) {
                    final positionData = snapshot.data;
                    return SeekBar(
                      duration: positionData?.duration ?? Duration.zero,
                      position: positionData?.position ?? Duration.zero,
                      bufferedPosition:
                          positionData?.bufferedPosition ?? Duration.zero,
                      onChangeEnd: (newPosition) {
                        _audioHandler.seek(newPosition);
                      },
                    );
                  },
                ),
              ),

              /// 切换播放方式区域(单曲循环等、歌单名称、随机播放图标)
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    ///> 播放方式切换按钮（单曲循环、列表循环、不循环）
                    StreamBuilder<LoopMode>(
                      stream: _audioHandler.getLoopModeStream(),
                      builder: (context, snapshot) {
                        final loopMode = snapshot.data ?? LoopMode.off;
                        const icons = [
                          Icon(Icons.repeat, color: Colors.grey),
                          Icon(Icons.repeat, color: Colors.orange),
                          Icon(Icons.repeat_one, color: Colors.orange),
                        ];
                        const cycleModes = [
                          LoopMode.off,
                          LoopMode.all,
                          LoopMode.one,
                        ];
                        final index = cycleModes.indexOf(loopMode);
                        return IconButton(
                          icon: icons[index],
                          onPressed: () {
                            _audioHandler.setRepeatMode(cycleModes[
                                (cycleModes.indexOf(loopMode) + 1) %
                                    cycleModes.length]);
                          },
                        );
                      },
                    ),
                    Expanded(
                      child: Text(
                        "Playlist",
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),

                    ///> 随机播放的图标按钮
                    StreamBuilder<bool>(
                      stream: _audioHandler.getShuffleModeEnabledStream(),
                      builder: (context, snapshot) {
                        final shuffleModeEnabled = snapshot.data ?? false;
                        return IconButton(
                          icon: shuffleModeEnabled
                              ? const Icon(Icons.shuffle, color: Colors.orange)
                              : const Icon(Icons.shuffle, color: Colors.grey),
                          onPressed: () async {
                            final enable = !shuffleModeEnabled;
                            if (enable) {
                              await _audioHandler.shuffle();
                            }
                            await _audioHandler.setShuffleModeEnabled(enable);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              /// 下一曲概述（占位）
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 8.sp,
                  child: const Text("下一曲概述"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

/// 当前歌曲控制按钮具体实现
/// 音量、上一曲、暂停/播放、下一曲、倍速
class ControlButtons extends StatelessWidget {
  ControlButtons({Key? key}) : super(key: key);

  final _audioHandler = getIt<MyAudioHandler>();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.volume_up),
          onPressed: () {
            showSliderDialog(
              context: context,
              title: "Adjust volume",
              divisions: 10,
              min: 0.0,
              max: 1.0,
              value: _audioHandler.volume,
              stream: _audioHandler.volumeStream,
              onChanged: _audioHandler.setVolume,
            );
          },
        ),
        StreamBuilder<SequenceState?>(
          stream: _audioHandler.getSequenceStateStream(),
          builder: (context, snapshot) => IconButton(
            icon: const Icon(Icons.skip_previous),
            onPressed: _audioHandler.hasPrevious()
                ? () => _audioHandler.seekToPrevious()
                : null,
          ),
        ),
        StreamBuilder<PlayerState>(
          stream: _audioHandler.getPlayerStateStream(),
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;
            if (processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering) {
              return Container(
                margin: const EdgeInsets.all(8.0),
                width: 64.0,
                height: 64.0,
                child: const CircularProgressIndicator(),
              );
            } else if (playing != true) {
              return IconButton(
                icon: const Icon(Icons.play_arrow),
                iconSize: 64.0,
                onPressed: () => _audioHandler.play(),
              );
            } else if (processingState != ProcessingState.completed) {
              return IconButton(
                icon: const Icon(Icons.pause),
                iconSize: 64.0,
                onPressed: () => _audioHandler.pause(),
              );
            } else {
              return IconButton(
                icon: const Icon(Icons.replay),
                iconSize: 64.0,
                onPressed: () => _audioHandler.seek(Duration.zero,
                    index: _audioHandler.getEffectiveIndices()!.first),
              );
            }
          },
        ),
        StreamBuilder<SequenceState?>(
          stream: _audioHandler.getSequenceStateStream(),
          builder: (context, snapshot) => IconButton(
            icon: const Icon(Icons.skip_next),
            onPressed: _audioHandler.hasNext()
                ? () => _audioHandler.seekToNext()
                : null,
          ),
        ),
        StreamBuilder<double>(
          stream: _audioHandler.getSpeedStream(),
          builder: (context, snapshot) => IconButton(
            icon: Text("${snapshot.data?.toStringAsFixed(1)}x",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              showSliderDialog(
                context: context,
                title: "Adjust speed",
                divisions: 10,
                min: 0.5,
                max: 1.5,
                value: _audioHandler.speed,
                stream: _audioHandler.getSpeedStream(),
                onChanged: _audioHandler.setSpeed(),
              );
            },
          ),
        ),
      ],
    );
  }
}
