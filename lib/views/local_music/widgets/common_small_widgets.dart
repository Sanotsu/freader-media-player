// 构建一行依次为标签+属性的row widget
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:marquee/marquee.dart';

Widget buildRowText(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        flex: 1,
        child: Text(
          label, // 文字内容
          overflow: TextOverflow.ellipsis, // 过长显示省略号
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ), // 文字样式
        ),
      ),
      Expanded(
        flex: 2,
        child: Text(
          value, // 文字内容
          // overflow: TextOverflow.ellipsis, // 过长显示省略号
          overflow: TextOverflow.visible, // 过长显示省略号
          style: TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 14.sp,
            // color: const Color.fromARGB(255, 75, 72, 72),
          ), // 文字样式
        ),
      )
    ],
  );
}

Widget buildRowListTile(String label, String value) {
  return ListTile(
    title: Text(
      label, // 文字内容
      overflow: TextOverflow.ellipsis, // 过长显示省略号
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16.sp,
      ), // 文字样式
    ),
    subtitle: Text(
      value, // 文字内容
      // overflow: TextOverflow.ellipsis, // 过长显示省略号
      overflow: TextOverflow.visible, // 过长显示省略号
      style: TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 14.sp,
        // color: const Color.fromARGB(255, 75, 72, 72),
      ), // 文字样式
    ),
  );
}

// 无访问权限时的占位部件(参数为点击按钮的操作函数)
Widget noAccessToLibraryWidget(Function() cb) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: Colors.redAccent.withOpacity(0.5),
    ),
    padding: const EdgeInsets.all(20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("应用程序暂未获得存储权限"),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: cb,
          child: const Text("授权"),
        ),
      ],
    ),
  );
}

// 自定的带标签的复选框（RadioListTile高度太高，还不能跳整）
class LabeledRadio extends StatelessWidget {
  const LabeledRadio({
    super.key,
    required this.label,
    required this.padding,
    required this.groupValue,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final EdgeInsets padding;
  final dynamic groupValue;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (value != groupValue) {
          onChanged(value);
        }
      },
      child: Padding(
        padding: padding,
        child: Row(
          children: <Widget>[
            Radio<dynamic>(
              groupValue: groupValue,
              value: value,
              onChanged: (dynamic newValue) {
                onChanged(newValue!);
              },
            ),
            Text(label),
          ],
        ),
      ),
    );
  }
}

// text文字超过一行则水平滚动(预设特性不可修改)，不超过一行则单纯Text显示
class SimpleMarqueeOrText extends StatefulWidget {
  const SimpleMarqueeOrText({
    super.key,
    required this.data,
    required this.style,
    this.velocity,
    this.showLines,
    this.height,
    this.width,
  });

  final String data;
  final TextStyle style;
  // 传入速度
  final double? velocity;
  // 传入显示的行数(大于此才滚动)
  final int? showLines;
  // 滚动条的高度
  final double? height;
  // 滚动条的宽度
  final double? width;

  @override
  State<SimpleMarqueeOrText> createState() => _SimpleMarqueeOrTextState();
}

class _SimpleMarqueeOrTextState extends State<SimpleMarqueeOrText> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // 这里是获取文本的行数
      final span = TextSpan(text: widget.data, style: widget.style);
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr);

      // tp.layout(maxWidth: constraints.maxWidth);
      // 注意，如果是builder的约束，默认为设备的总宽度(测试机为360.sp)，不是全宽跑马灯的话宽度要自定，才能得到准确的行数
      // tp.layout(maxWidth: widget.width ?? 300.sp); // 和下面的sizedbox宽度一致

      // 看起来上面的不太准确，这个最小宽度可能是本widget的父widget的宽度。但是在播放详情页面标题和专辑信息时，传过来就是0.0。
      // 所以，要么在使用的时候指定父组件，要么就在这里设定一个最小值。
      // 综上优先级:手动传入宽度 > 大于50的父组件 > 预设的300
      var showWidth = widget.width ??
          (constraints.minWidth > 50.sp ? constraints.minWidth : 300.sp);
      tp.layout(maxWidth: showWidth);
      final numLines = tp.computeLineMetrics().length;

      return SizedBox(
        height: widget.height ?? 30.sp,
        width: showWidth,
        child: numLines > (widget.showLines ?? 1)
            ? Marquee(
                text: "${widget.data}   ", // 超过一行时滚动的字串加点空白以便识别文字起止
                style: widget.style,
                velocity: widget.velocity ?? 10.0, // 滚动速度
              )
            : Center(child: Text(widget.data, style: widget.style)),
      );
    });
  }
}
