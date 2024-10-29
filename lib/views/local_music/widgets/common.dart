import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';

import '../../../services/my_audio_handler.dart';
import '../../../services/my_get_storage.dart';
import '../../../services/service_locator.dart';

///
/// 音频播放进度条
///
class SeekBar extends StatefulWidget {
  final Duration duration; // 音频总时长
  final Duration position; // 音频已播放的时长
  final Duration bufferedPosition; // 已缓冲的位置
  final ValueChanged<Duration>? onChanged; // 当拖动进度开始时
  final ValueChanged<Duration>? onChangeEnd; // 当拖动进度结束时

  const SeekBar({
    super.key,
    required this.duration,
    required this.position,
    required this.bufferedPosition,
    this.onChanged,
    this.onChangeEnd,
  });

  @override
  SeekBarState createState() => SeekBarState();
}

class SeekBarState extends State<SeekBar> {
  // 滑块条拖动后的值
  double? _dragValue;

  // 保存 Material Design 滑块主题(slider theme)的颜色、形状和排版值。
  late SliderThemeData _sliderThemeData;

  // 音乐播放实例
  final _audioHandler = getIt<MyAudioHandler>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _sliderThemeData = SliderTheme.of(context).copyWith(
      trackHeight: 2.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        /// 滑块组件，搭配设定其主题样式
        // 已缓存的音频时长滑块
        Positioned(
          left: 0.sp,
          right: 0.sp,
          top: 0.0,
          child: SliderTheme(
            data: _sliderThemeData.copyWith(
              thumbShape: HiddenThumbComponentShape(), // thumb 形状（应该是）
              activeTrackColor: Colors.orange.shade900, // 已缓存轨迹的颜色
              inactiveTrackColor: Colors.grey.shade300, // 未缓存轨迹的颜色
            ),
            // 一个小部件，用于删除其子代的所有语义。
            // 当excluding 属性为true时，此小部件（及其子树）将从语义树中排除。
            child: ExcludeSemantics(
              child: Slider(
                min: 0.0,
                max: widget.duration.inMilliseconds.toDouble(),
                value: min(widget.bufferedPosition.inMilliseconds.toDouble(),
                    widget.duration.inMilliseconds.toDouble()),
                onChanged: (value) {
                  setState(() {
                    _dragValue = value;
                  });
                  if (widget.onChanged != null) {
                    widget.onChanged!(Duration(milliseconds: value.round()));
                  }
                },
                onChangeEnd: (value) {
                  if (widget.onChangeEnd != null) {
                    widget.onChangeEnd!(Duration(milliseconds: value.round()));
                  }
                  _dragValue = null;
                },
              ),
            ),
          ),
        ),
        // 音频总时长的滑块
        Positioned(
          left: 0.sp,
          right: 0.sp,
          top: 0.0,
          child: SliderTheme(
            data: _sliderThemeData.copyWith(
              inactiveTrackColor: Colors.transparent,
              activeTrackColor: Colors.orange, // 已经播放的进度条颜色
              thumbColor: Colors.orange, // 滑块圆点的颜色
            ),
            child: Slider(
              min: 0.0,
              max: widget.duration.inMilliseconds.toDouble(),
              value: min(
                  _dragValue ?? widget.position.inMilliseconds.toDouble(),
                  widget.duration.inMilliseconds.toDouble()),
              onChanged: (value) {
                setState(() {
                  _dragValue = value;
                });
                if (widget.onChanged != null) {
                  widget.onChanged!(Duration(milliseconds: value.round()));
                }
              },
              onChangeEnd: (value) {
                if (widget.onChangeEnd != null) {
                  widget.onChangeEnd!(Duration(milliseconds: value.round()));
                }
                _dragValue = null;
              },
            ),
          ),
        ),

        /**
         *  注意这一堆显示图标文字的位置
         *    已运行的时长和总时长文字宽*高为30*14；文本按钮高度为78*48，其中中文字和按钮所在的Row高度占24；
         *    为了让该4个组件在一行且居中，所以要设置对应的Positioned的左右侧距离和下方距离:
         *      设备总宽度为360，有【xx】包裹为组件宽度，没有包裹的为间距，为了对称平均分布，结果如下:
         *      15 +【30】+ 38 +【78】+ 38 +【78】+ 38 +【30】+ 15 = 360 
         *      
         *      而高度，则以图标显示的底部与Positioned的bottom为0.0时平齐为基准，不同高度组件居中:
         *      文字图标总高度48，但其中Row 24，所以上下空白各12，所以距离底部:-12;
         *      Row高度中心距离bottom为24/2=12，所以时间文字高度距离bottom为12-(14/2)=5
         *  
         *  2023-04-22 为了感官上seekbar居中，文本按钮不再只显示icon部分，所以以下bottom距离整体往上+12.(-12变0,5变17)
         *  此外，为了固定滑块位置，上面滑块组件，也放在了positioned中
         * 
         */

        /// Positioned 必须是 Stack 的后代，用于控制Stack的子项的放置位置。
        // 显示已播放的时长
        Positioned(
          left: 15.sp, // 距离左边界15个单位
          bottom: 17.0,
          child: Text(
              RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
                      .firstMatch("${widget.position}")
                      ?.group(1) ??
                  '${widget.position}',
              style: Theme.of(context).textTheme.bodySmall),
        ),

        /// 此处剩余时间的数字显示区域
        // Positioned(
        //   right: 160.sp, // 距离右边界16个单位
        //   bottom: 0.0,
        //   child: Text(
        //       RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
        //               .firstMatch("$_remaining")
        //               ?.group(1) ??
        //           '$_remaining',
        //       style: Theme.of(context).textTheme.bodySmall),
        // ),

        /// 音量调节按钮
        Positioned(
          left: 83.sp,
          bottom: 0.0,
          child: TextButton(
            style: TextButton.styleFrom(
              textStyle: TextStyle(fontSize: 20.sp), // 字体大小
              foregroundColor: Colors.black, // 前景颜色
            ),
            onPressed: () {
              showSliderDialog(
                context: context,
                title: "音量调节",
                divisions: 20,
                min: 0.0,
                max: 2.0, // 两倍音量不一定有效，可能1以上都同一个音量
                value: _audioHandler.volume,
                stream: _audioHandler.volumeStream,
                onChanged: _audioHandler.setVolume,
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.volume_up),
                Text(
                  "${_audioHandler.volume}x",
                  style: TextStyle(fontSize: 20.sp),
                ),
              ],
            ),
          ),
        ),

        /// 播放速度条件按钮
        Positioned(
          right: 83.sp,
          bottom: 0.0,
          child: StreamBuilder<double>(
            stream: _audioHandler.getSpeedStream(),
            builder: (context, snapshot) => TextButton(
              style: TextButton.styleFrom(
                textStyle: TextStyle(fontSize: 20.sp), // 字体大小
                foregroundColor: Colors.black, // 前景颜色
              ),
              onPressed: () {
                showSliderDialog(
                  context: context,
                  title: "播放速度",
                  divisions: 18,
                  min: 0.2,
                  max: 2.0,
                  value: _audioHandler.speed,
                  stream: _audioHandler.getSpeedStream(),
                  onChanged: _audioHandler.setSpeed(),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions_run),
                  Text(
                    "${snapshot.data?.toStringAsFixed(1)}x",
                    style: TextStyle(fontSize: 20.sp),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 总时长
        Positioned(
          right: 15.sp, // 距离右边界15个单位
          bottom: 17.0,
          child: Text(
            RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
                    .firstMatch("${widget.duration}")
                    ?.group(1) ??
                '${widget.duration}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  // 剩余时长=总时长-已播放的时长
  // Duration get _remaining => widget.duration - widget.position;
}

///
/// 当前歌曲控制按钮具体实现
/// 音量、上一曲、暂停/播放、下一曲、倍速
///
class ControlButtons extends StatefulWidget {
  const ControlButtons({super.key, required this.callback});

  final Function callback;

  @override
  State<ControlButtons> createState() => _ControlButtonsState();
}

class _ControlButtonsState extends State<ControlButtons> {
  final _audioHandler = getIt<MyAudioHandler>();
  // 统一简单存储操作的工具类实例
  final _simpleStorage = getIt<MyGetStorage>();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        /// 播放方式切换按钮（单曲循环、列表循环、不循环）
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
            const cycleModes = [LoopMode.all, LoopMode.one, LoopMode.off];
            final index = cycleModes.indexOf(loopMode);

            return IconButton(
              icon: icons[index],
              iconSize: 32.sp,
              onPressed: () async {
                var temp = cycleModes[
                    (cycleModes.indexOf(loopMode) + 1) % cycleModes.length];

                setState(() {
                  _audioHandler.setRepeatMode(temp);
                });

                await _simpleStorage.setCurrentCycleMode(temp.toString());

                // 2024-01-10 理论上，在播放详情页改变了循环方式，也需要更新缓存中音乐编号(歌单类型、专辑编号是没有变化)
                await _simpleStorage.setCurrentAudioIndex(
                  _audioHandler.currentIndex,
                );

                // 2024-01-10 同理，也需要通过回调函数的方式，把下一首歌曲的索引传递个父级，用于构建下一曲的预览
                widget.callback(_audioHandler.nextIndex);
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

        /// 随机播放的图标按钮
        FutureBuilder<bool>(
          future: _audioHandler.getShuffleModeEnabledValue(),
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            if (snapshot.hasError) {
              return Text(snapshot.error.toString());
            }
            if (!snapshot.hasData) {
              return Text(snapshot.error.toString());
            }

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

                setState(() {
                  if (enable) {
                    _audioHandler.shuffle();
                  }
                  _audioHandler.setShuffleModeEnabled(enable);
                });

                await _simpleStorage.setCurrentIsShuffleMode(enable.toString());

                // 2024-01-10 理论上，在播放详情页改变了循环方式，也需要更新缓存中音乐编号(歌单类型、专辑编号是没有变化)
                await _simpleStorage.setCurrentAudioIndex(
                  _audioHandler.currentIndex,
                );

                // 2024-01-10 同理，也需要通过回调函数的方式，把下一首歌曲的索引传递个父级，用于构建下一曲的预览
                widget.callback(_audioHandler.nextIndex);
              },
            );
          },
        ),
      ],
    );
  }
}

/// SliderComponentShape 为拇指(thumb)滑块、拇指覆盖物和数值指示器形状的基类。如果想要一个自定义的形状，需要创建它的子类。
/// 所有的形状都画在同一个画布上，排序很重要。先画覆盖层，然后是值指示器，最后是拇指。
class HiddenThumbComponentShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.zero;

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {}
}

void showSliderDialog({
  required BuildContext context,
  required String title,
  required int divisions,
  required double min,
  required double max,
  String valueSuffix = '',
  // ignore: todo
  // TODO: Replace these two by ValueStream.
  required double value,
  required Stream<double> stream,
  required ValueChanged<double> onChanged,
}) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, textAlign: TextAlign.center),
      content: StreamBuilder<double>(
        stream: stream,
        builder: (context, snapshot) => SizedBox(
          height: 80.sp,
          child: Column(
            children: [
              Text(
                '${snapshot.data?.toStringAsFixed(1)}$valueSuffix',
                style: TextStyle(
                  fontFamily: 'Fixed',
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ),
              Slider(
                divisions: divisions,
                min: min,
                max: max,
                value: snapshot.data ?? value,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
