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
  });

  final String data;
  final TextStyle style;

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
      // 注意，如果是builder的约束，默认为设备的总宽度(测试机为360.sp)，不是全款跑马灯的话宽度要自定，才能得到准确的行数
      tp.layout(maxWidth: 300.sp); // 和下面的sizedbox宽度一致
      final numLines = tp.computeLineMetrics().length;

      return SizedBox(
        height: 30.sp,
        // width: double.maxFinite, // 如果是这个宽度，那上面maxWidth就可以取最大值了
        width: 300.sp, // app.dart中有宽高说明
        child: numLines > 1
            ? Marquee(
                text: "${widget.data}   ", // 超过一行时滚动的字串加点空白以便识别文字起止
                style: widget.style,
                velocity: 10.0,
              )
            : Center(child: Text(widget.data, style: widget.style)),
      );
    });
  }
}
