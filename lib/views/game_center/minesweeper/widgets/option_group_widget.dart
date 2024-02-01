import 'package:flutter/material.dart';

import '../utils/exports.dart';

class OptionGroup extends StatelessWidget {
  const OptionGroup({
    required this.options,
    this.groupDescription,
    this.bgColor = Colors.white,
    this.dividerColor,
    this.dividerPadding,
    super.key,
  });

  final List<Widget> options;
  final String? groupDescription;
  final Color bgColor;
  final Color? dividerColor;
  final double? dividerPadding;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: GameSizes.getHeight(0.015)),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: GameSizes.getRadius(14),
          ),
          child: Column(
            children: List.generate(
              options.length,
              (index) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: GameSizes.getSymmetricPadding(0.015, 0.009),
                      child: options[index],
                    ),
                    Visibility(
                      visible: index < options.length - 1,
                      child: Container(
                        height: 0.35,
                        width: double.infinity,
                        margin: EdgeInsets.only(
                            left: dividerPadding ?? GameSizes.getWidth(0.13)),
                        color: dividerColor ?? Colors.grey[300],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        if (groupDescription != null) ...[
          SizedBox(height: GameSizes.getHeight(0.01)),
          Padding(
            padding: GameSizes.getHorizontalPadding(0.02),
            child: Text(
              groupDescription!,
              style: TextStyle(
                color: GameColors.darkBlue,
                fontSize: GameSizes.getWidth(0.04),
              ),
            ),
          ),
        ],
        SizedBox(
            height: groupDescription != null
                ? GameSizes.getHeight(0.01)
                : GameSizes.getHeight(0.015)),
      ],
    );
  }
}
