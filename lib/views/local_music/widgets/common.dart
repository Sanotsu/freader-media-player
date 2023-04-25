import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/utils/global_styles.dart';
import '../../../services/my_audio_handler.dart';
import '../../../services/service_locator.dart';

// 音频进度条
class SeekBar extends StatefulWidget {
  final Duration duration; // 音频总时长
  final Duration position; // 音频已播放的时长
  final Duration bufferedPosition; // 已缓冲的位置
  final ValueChanged<Duration>? onChanged; // 当拖动进度开始时
  final ValueChanged<Duration>? onChangeEnd; // 当拖动进度结束时

  const SeekBar({
    Key? key,
    required this.duration,
    required this.position,
    required this.bufferedPosition,
    this.onChanged,
    this.onChangeEnd,
  }) : super(key: key);

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
        // // 此处剩余时间的数字显示区域
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
                  title: "调整速度",
                  divisions: 18,
                  min: 0.2,
                  max: 2.00,
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
              style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }

  // 剩余时长=总时长-已播放的时长
  // Duration get _remaining => widget.duration - widget.position;
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
      backgroundColor: dartThemeMaterialColor3,
      title: Text(title, textAlign: TextAlign.center),
      content: StreamBuilder<double>(
        stream: stream,
        builder: (context, snapshot) => SizedBox(
          height: 80.0,
          child: Column(
            children: [
              Text('${snapshot.data?.toStringAsFixed(1)}$valueSuffix',
                  style: const TextStyle(
                      fontFamily: 'Fixed',
                      fontWeight: FontWeight.bold,
                      fontSize: 24.0)),
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
