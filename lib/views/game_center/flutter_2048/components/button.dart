import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../const/colors.dart';

///
/// 撤回上一步、重来、新游戏、再来一次等的控制按钮组件
///
class ButtonWidget extends ConsumerWidget {
  const ButtonWidget({
    super.key,
    this.text,
    this.icon,
    required this.onPressed,
  });

  final String? text;
  final IconData? icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (icon != null) {
      // Button Widget with icon for Undo and Restart Game button.
      return Container(
        decoration: BoxDecoration(
          color: scoreColor,
          borderRadius: BorderRadius.circular(8.sp),
        ),
        child: IconButton(
          color: textColorWhite,
          onPressed: onPressed,
          icon: Icon(icon, size: 24.sp),
        ),
      );
    }
    // Button Widget with text for New Game and Try Again button.
    return ElevatedButton(
      style: ButtonStyle(
        padding: WidgetStateProperty.all<EdgeInsets>(EdgeInsets.all(16.sp)),
        backgroundColor: WidgetStateProperty.all<Color>(buttonColor),
      ),
      onPressed: onPressed,
      child: Text(
        text!,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
      ),
    );
  }
}
