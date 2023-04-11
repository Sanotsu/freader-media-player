import 'package:flutter/material.dart';

class OnlineMusic extends StatelessWidget {
  const OnlineMusic({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("在线音乐(预留)"), actions: const <Widget>[]),
      body: const DefaultTabController(
        initialIndex: 1,
        length: 3,
        child: TabBarView(
          children: <Widget>[
            Center(
              child: Text("It's cloudy here tab1"),
            ),
            Center(
              child: Text("It's rainy here tab2"),
            ),
            Center(
              child: Text("It's sunny here tab3"),
            ),
          ],
        ),
      ),
    );
  }
}
