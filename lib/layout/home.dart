import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Text(
      'Index 0: Home${widget.title}',
      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
    );
  }
}
