// 构建一行依次为标签+属性的row widget
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
            color: const Color.fromARGB(255, 75, 72, 72),
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
        color: const Color.fromARGB(255, 75, 72, 72),
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
