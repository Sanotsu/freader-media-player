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
import '../../../services/my_get_storage.dart';
// import '../../../services/my_shared_preferences.dart';
import '../../../services/service_locator.dart';
import '../widgets/common.dart';
import '../widgets/common_small_widgets.dart';

/// 音乐播放器主界面
/// 本地音乐或者之后在线音乐，不管从哪里点击音乐，都进入到此音乐播放详情页面
/// 因此需要传入音乐信息用于播放

class JustAudioMusicPlayer extends StatefulWidget {
  const JustAudioMusicPlayer({super.key});

  @override
  JustAudioMusicPlayerState createState() => JustAudioMusicPlayerState();
}

class JustAudioMusicPlayerState extends State<JustAudioMusicPlayer>
    with WidgetsBindingObserver {
  final _audioHandler = getIt<MyAudioHandler>();

  // 更新当前音乐的下一首
  late int nextAudionIndex = _audioHandler.nextIndex ?? 0;

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
    return Scaffold(
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
                        child: SingleChildScrollView(
                          child: Column(children: [
                            // 歌名
                            SimpleMarqueeOrText(
                              data: '${state.currentIndex}-${metadata.title}',
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
                        ),
                      )
                    ],
                  );
                },
              ),
            ),

            // divider看位置的，最后不用
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
                  return Center(
                    child: SeekBar(
                      duration: positionData?.duration ?? Duration.zero,
                      position: positionData?.position ?? Duration.zero,
                      bufferedPosition:
                          positionData?.bufferedPosition ?? Duration.zero,
                      onChangeEnd: (newPosition) {
                        _audioHandler.seek(newPosition);
                      },
                    ),
                  );
                },
              ),
            ),

            // divider看位置的，最后不用
            // Divider(height: 2, thickness: 1.sp, color: Colors.grey),

            /// 音频控制按钮区域
            Expanded(
              flex: 1,
              child: Center(
                child: ControlButtons(
                  callback: (value) {
                    print("xxxxxxxxxxxxxxxxxxxxx$value");
                    setState(() {
                      nextAudionIndex = value;
                    });
                  },
                ),
              ),
            ),

            // Divider(height: 2, thickness: 1.sp, color: Colors.grey),

            /// 下一曲概述
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 8.sp,
                child: FutureBuilder(
                  future: _audioHandler.getLoopModeValue(),
                  builder: (context, AsyncSnapshot<LoopMode> snapshot) {
                    if (snapshot.hasError) {
                      return Text(snapshot.error.toString());
                    }

                    final loopMode = snapshot.data ?? LoopMode.off;

                    // 因为下一曲的索引在初始化的时候就直接取得next，所以如果模式是单曲循环，则重置为当前的
                    if (loopMode == LoopMode.one) {
                      nextAudionIndex = _audioHandler.currentIndex!;
                    }
                    // 获取下一首音乐的基本信息并构建显示内容
                    AudioSource temp = _audioHandler.getAudioSourceByIndex(
                      nextAudionIndex,
                    );

                    final metadata = temp.sequence.first.tag as MediaItem;
                    var nextInfo =
                        "下一首：$nextAudionIndex-${metadata.title}-${metadata.artist}";

                    return SizedBox(
                      // 这个会让下面的 simpleMarqueeOrText 设置的宽度无效
                      width: double.infinity,
                      child: Padding(
                        padding: EdgeInsets.all(2.sp),
                        child: Card(
                          elevation: 10.sp,
                          child: SimpleMarqueeOrText(
                            data: nextInfo,
                            style: TextStyle(fontSize: sizeContent0),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            )
          ],
        ),
      ),
      // 左上角一个悬空的返回箭头按钮
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: Theme.of(context).primaryColor,
          size: 30.sp,
        ),
        onPressed: () => Navigator.of(context).pop(),
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
  // final _simpleShared = getIt<MySharedPreferences>();
  final _simpleStorage = getIt<MyGetStorage>();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ///> 播放方式切换按钮（单曲循环、列表循环、不循环）

        FutureBuilder<LoopMode>(
          future: _audioHandler.getLoopModeValue(),
          builder: (BuildContext context, AsyncSnapshot<LoopMode> snapshot) {
            if (snapshot.hasError) {
              return Text(snapshot.error.toString());
            }

            final loopMode = snapshot.data ?? LoopMode.off;

            // 得到持久化的循环模式数据，要执行它才会生效
            _audioHandler.setRepeatMode(loopMode);

            // 显示对应循环模式的图标
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
                // await _simpleShared.setCurrentCycleMode(temp.toString());
                await _simpleStorage.setCurrentCycleMode(temp.toString());
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

                    var tempList = await _simpleStorage.getCurrentAudioInfo();

                    print("【点击上一曲，当前的音乐信息】tempList,$tempList");

                    print("【点击上一曲后当前的索引】 ${_audioHandler.currentIndex}");

                    // 2024-01-09 理论上，在播放详情页切换上下一曲后，仅更新缓存中音乐编号即可(歌单类型、专辑编号是没有变化)
                    await _simpleStorage.setCurrentAudioIndex(
                      _audioHandler.currentIndex,
                    );

                    // 通过回调函数的方式，把下一首歌曲的索引传递个父级，用于构建下一曲的预览
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

                    var tempList = await _simpleStorage.getCurrentAudioInfo();

                    print("【点击下一曲，当前的音乐信息】tempList,$tempList");

                    print("【点击下一曲 后 当前的索引】 ${_audioHandler.currentIndex}");

                    // 2024-01-09 理论上，在播放详情页切换上下一曲后，仅更新缓存中音乐编号即可(歌单类型、专辑编号是没有变化)
                    await _simpleStorage.setCurrentAudioIndex(
                      _audioHandler.currentIndex,
                    );

                    // 通过回调函数的方式，把下一首歌曲的索引传递个父级，用于构建下一曲的预览
                    widget.callback(_audioHandler.nextIndex);
                  }
                : null,
          ),
        ),

        ///> 随机播放的图标按钮

        FutureBuilder<bool>(
          future: _audioHandler.getShuffleModeEnabledValue(),
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            print(
              "当前 点ssssssssssssssssssssssssss ${snapshot.hasData} ${snapshot.data}",
            );

            if (snapshot.hasError) {
              return Text(snapshot.error.toString());
            }
            if (!snapshot.hasData) {
              return Text(snapshot.error.toString());
            }

            print(
              "当前 点击 随机播放 的索引 snapshot.data ${snapshot.data}",
            );

            final shuffleModeEnabled = snapshot.data ?? false;
            // 得到持久化的随机状态数据，要执行它才会生效
            _audioHandler.setShuffleModeEnabled(shuffleModeEnabled);

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

                setState(() {
                  if (enable) {
                    _audioHandler.shuffle();
                  }
                  _audioHandler.setShuffleModeEnabled(enable);
                  // _simpleShared.setCurrentIsShuffleMode(enable.toString());
                  _simpleStorage.setCurrentIsShuffleMode(enable.toString());
                });
              },
            );
          },
        ),
      ],
    );
  }
}
