import 'package:flutter/material.dart';

class OtherIndex extends StatelessWidget {
  const OtherIndex({super.key});

  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    return const Text('Index 2: School', style: optionStyle);
  }
}
