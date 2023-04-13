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
