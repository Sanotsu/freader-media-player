// ignore_for_file: avoid_print

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'package:on_audio_query/on_audio_query.dart';

import '../../../common/utils/global_styles.dart';
import '../../../services/my_audio_handler.dart';
import '../../../services/my_shared_preferences.dart';
import '../../../services/service_locator.dart';
import '../widgets/common.dart';
import '../widgets/common_small_widgets.dart';

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

  late int nextAudionIndex = 0;

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

    _audioHandler.play();
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
    print("++++++++++++++但钱app的生命周期状态$state");

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

                    if (state?.sequence.isEmpty ?? true) {
                      return const SizedBox();
                    }

                    final metadata = state!.currentSource!.tag as MediaItem;

                    print(
                      " player detail 当前正在播放的音乐： 索引 ${state.currentIndex} 专辑 ${metadata.album} 歌名 ${metadata.title}",
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: QueryArtworkWidget(
                              id: int.parse(metadata.id),
                              type: ArtworkType.AUDIO,
                              artworkWidth: 1.sw,
                              artworkHeight: 20.sp,
                              artworkBorder: BorderRadius.zero, // 图标边角无圆弧
                              size: 100,
                              keepOldArtwork: true, // 在生命周期内使用旧的缩略图
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(children: [
                            // 歌名
                            SimpleMarqueeOrText(
                              data: '${metadata.title}=${state.currentIndex}',
                              style: TextStyle(fontSize: sizeHeadline0),
                            ),
                            // 分割占位
                            SizedBox(height: 10.sp),
                            // 歌手+专辑名
                            SimpleMarqueeOrText(
                              data:
                                  '${metadata.artist ?? "未知歌手"} -- ${metadata.album ?? "未知专辑"}',
                              style: TextStyle(fontSize: sizeHeadline2),
                            ),
                          ]),
                        )
                      ],
                    );
                  },
                ),
              ),

              // divider看位置的，最后不用
              // Divider(height: 2, thickness: 1.sp, color: Colors.grey),

              /// 音频控制按钮区域
              Expanded(
                  flex: 1,
                  child: ControlButtons(
                    callback: (value) {
                      print("xxxxxxxxxxxxxxxxxxxxx$value");
                      setState(() {
                        nextAudionIndex = value;
                      });
                    },
                  )),

              // Divider(height: 2, thickness: 1.sp, color: Colors.grey),

              /// 音频拖动进度条
              Expanded(
                flex: 1,
                child: StreamBuilder<PositionData>(
                  // 当前播放位置音频数据
                  stream: _audioHandler.positionDataStream,
                  builder: (context, snapshot) {
                    final positionData = snapshot.data;
                    // 进度条右边是剩余时间
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
              /// 这个要改变形象了，暂时放这里，后面要放到seekbar中
              // Expanded(
              //   flex: 1,
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     children: [
              //       /// 音量调节按钮

              //       IconButton(
              //         icon: const Icon(Icons.volume_up),
              //         iconSize: 32.sp,
              //         onPressed: () {
              //           showSliderDialog(
              //             context: context,
              //             title: "音量调节",
              //             divisions: 10,
              //             min: 0.0,
              //             max: 1.0,
              //             value: _audioHandler.volume,
              //             stream: _audioHandler.volumeStream,
              //             onChanged: _audioHandler.setVolume,
              //           );
              //         },
              //       ),

              //       /// 播放速度条件按钮
              //       StreamBuilder<double>(
              //         stream: _audioHandler.getSpeedStream(),
              //         builder: (context, snapshot) => IconButton(
              //           icon: Text("${snapshot.data?.toStringAsFixed(1)}x",
              //               style: TextStyle(
              //                   fontWeight: FontWeight.bold, fontSize: 24.sp)),
              //           iconSize: 48.sp,
              //           onPressed: () {
              //             showSliderDialog(
              //               context: context,
              //               title: "调整速度",
              //               divisions: 10,
              //               min: 0.5,
              //               max: 1.5,
              //               value: _audioHandler.speed,
              //               stream: _audioHandler.getSpeedStream(),
              //               onChanged: _audioHandler.setSpeed(),
              //             );
              //           },
              //         ),
              //       ),
              //     ],
              //   ),
              // ),

              // Divider(height: 2, thickness: 1.sp, color: Colors.grey),

              /// 下一曲概述
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 8.sp,
                  child: Builder(
                    builder: (context) {
                      // 获取下一首音乐的基本信息并构建显示内容
                      AudioSource temp = _audioHandler.getAudioSourceByIndex(
                        nextAudionIndex,
                      );

                      final metadata = temp.sequence.first.tag as MediaItem;

                      var nextInfo = "下一首：${metadata.title}-${metadata.artist}";
                      return Center(
                        child: SimpleMarqueeOrText(
                          data: nextInfo,
                          style: TextStyle(fontSize: sizeHeadline2),
                        ),
                      );
                    },
                  ),
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
class ControlButtons extends StatefulWidget {
  const ControlButtons({super.key, required this.callback});

  final Function callback;

  @override
  State<ControlButtons> createState() => _ControlButtonsState();
}

class _ControlButtonsState extends State<ControlButtons> {
  final _audioHandler = getIt<MyAudioHandler>();
  // 统一简单存储操作的工具类实例
  final _simpleShared = getIt<MySharedPreferences>();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ///> 播放方式切换按钮（单曲循环、列表循环、不循环）

        FutureBuilder<Stream<LoopMode>>(
          // a previously-obtained Future<String> or null
          future: _audioHandler.getLoopModeStream(),
          builder: (BuildContext context, AsyncSnapshot<Stream<LoopMode>> ss) {
            if (ss.hasError) {
              return Text(ss.error.toString());
            }

            return StreamBuilder<LoopMode>(
              stream: ss.data,
              builder: (context, snapshot) {
                final loopMode = snapshot.data ?? LoopMode.off;

                const icons = [
                  Icon(Icons.repeat, color: Colors.orange),
                  Icon(Icons.repeat_one, color: Colors.orange),
                  Icon(Icons.repeat, color: Colors.grey),
                ];
                const cycleModes = [
                  LoopMode.all,
                  LoopMode.one,
                  LoopMode.off,
                ];
                final index = cycleModes.indexOf(loopMode);

                print("player detail中的loopMode-$loopMode index $index");

                return IconButton(
                  icon: icons[index],
                  iconSize: 32.sp,
                  onPressed: () async {
                    print(
                      "当前 $loopMode 点击loopmode的索引  ${(cycleModes.indexOf(loopMode) + 1) % cycleModes.length}",
                    );
                    var temp = cycleModes[
                        (cycleModes.indexOf(loopMode) + 1) % cycleModes.length];
                    setState(() {
                      _audioHandler.setRepeatMode(temp);
                    });
                    await _simpleShared.setCurrentCycleMode(temp.toString());
                  },
                );
              },
            );
          },
        ),

        /// 上一曲按钮

        StreamBuilder<SequenceState?>(
          stream: _audioHandler.getSequenceStateStream(),
          builder: (context, snapshot) => IconButton(
            icon: const Icon(Icons.skip_previous),
            iconSize: 32.sp,
            onPressed: _audioHandler.hasPrevious()
                ? () async {
                    // 要确保跳转完成之后再获取下一首的索引，否则可能就是当前正常播放的索引
                    await _audioHandler.seekToPrevious();
                    // 通过回调函数的方式，把下一首歌曲的所以传递个父级，用于构建下一曲的预览
                    widget.callback(_audioHandler.nextIndex);
                  }
                : null,
          ),
        ),

        /// 播放/暂停/再次播放 按钮

        StreamBuilder<PlayerState>(
          stream: _audioHandler.getPlayerStateStream(),
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;
            if (processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering) {
              return Container(
                margin: EdgeInsets.all(8.sp),
                width: 64.sp,
                height: 64.sp,
                child: const CircularProgressIndicator(),
              );
            } else if (playing != true) {
              return IconButton(
                icon: const Icon(Icons.play_arrow),
                iconSize: 64.sp,
                onPressed: () => _audioHandler.play(),
              );
            } else if (processingState != ProcessingState.completed) {
              return IconButton(
                icon: const Icon(Icons.pause),
                iconSize: 64.sp,
                onPressed: () => _audioHandler.pause(),
              );
            } else {
              return IconButton(
                icon: const Icon(Icons.replay),
                iconSize: 64.sp,
                onPressed: () => _audioHandler.seek(Duration.zero,
                    index: _audioHandler.getEffectiveIndices()!.first),
              );
            }
          },
        ),

        /// 下一曲按钮
        StreamBuilder<SequenceState?>(
          stream: _audioHandler.getSequenceStateStream(),
          builder: (context, snapshot) => IconButton(
            icon: const Icon(Icons.skip_next),
            iconSize: 32.sp,
            onPressed: _audioHandler.hasNext()
                ? () async {
                    // 要确保跳转完成之后再获取下一首的索引，否则可能就是当前正常播放的索引
                    await _audioHandler.seekToNext();
                    // 通过回调函数的方式，把下一首歌曲的所以传递个父级，用于构建下一曲的预览
                    widget.callback(_audioHandler.nextIndex);
                  }
                : null,
          ),
        ),

        ///> 随机播放的图标按钮

        FutureBuilder<Stream<bool>>(
          future: _audioHandler.getShuffleModeEnabledStream(),
          builder: (BuildContext context, AsyncSnapshot<Stream<bool>> ss) {
            print(
              "当前 点ssssssssssssssssssssssssss ${ss.hasData} ${ss.data}",
            );

            if (ss.hasError) {
              return Text(ss.error.toString());
            }

            if (!ss.hasData) {
              return Text(ss.error.toString());
            }

            return StreamBuilder<bool>(
              stream: ss.data,
              builder: (context, snapshot) {
                print(
                  "当前 点击 随机播放 的索引 snapshot.data ${snapshot.data}",
                );

                final shuffleModeEnabled = snapshot.data ?? false;
                return IconButton(
                  icon: shuffleModeEnabled
                      ? const Icon(Icons.shuffle, color: Colors.orange)
                      : const Icon(Icons.shuffle, color: Colors.grey),
                  iconSize: 32.sp,
                  onPressed: () async {
                    final enable = !shuffleModeEnabled;
                    print(
                      "当前 点击 随机播放 后  $enable",
                    );

                    // if (enable) {
                    //   await _audioHandler.shuffle();
                    // }
                    // await _audioHandler.setShuffleModeEnabled(enable);

                    // await _simpleShared.setCurrentCycleMode(enable.toString());

                    setState(() {
                      if (enable) {
                        _audioHandler.shuffle();
                      }
                      _audioHandler.setShuffleModeEnabled(enable);

                      _simpleShared.setCurrentIsShuffleMode(enable.toString());
                    });
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}
