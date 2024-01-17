import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../global/constants.dart';

//  hexadecimal color code 转为 material color
MaterialColor buildMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map<int, Color> swatch = {};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}

// 生成随机颜色
Color genRandomColor() =>
    Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);

// 随机icon（可能没效果）
final List<int> points = <int>[0xe0b0, 0xe0b1, 0xe0b2, 0xe0b3, 0xe0b4];
final Random r = Random();
IconData genRandomIcon() =>
    IconData(r.nextInt(points.length), fontFamily: 'MaterialIcons');

// 显示底部提示条(默认都是出错或者提示的)
void showSnackMessage(
  BuildContext context,
  String message, {
  Color? backgroundColor = Colors.red,
}) {
  var snackBar = SnackBar(
    content: Text(message),
    duration: const Duration(seconds: 3),
    backgroundColor: backgroundColor,
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

commonExceptionDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message, style: TextStyle(fontSize: 13.sp)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("确定"),
          ),
        ],
      );
    },
  );
}

buildFileImage(File file, {BoxFit? fit}) => Image.file(
      file,
      errorBuilder: (
        BuildContext context,
        Object exception,
        StackTrace? stackTrace,
      ) =>
          Image.asset(
        placeholderImageUrl,
        fit: fit ?? BoxFit.scaleDown,
      ),
    );
