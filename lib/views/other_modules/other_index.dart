import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../models/audio_long_press.dart';
import '../../models/change_display_mode.dart';

class OtherIndex extends StatelessWidget {
  const OtherIndex({super.key});

  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    Color color = Theme.of(context).primaryColor;

    // 用户信息标头
    Widget userInfo = Center(
      child: ListTile(
        title: const Text('ListTile with Hero'),
        subtitle: const Text('Tap here for Hero transition'),
        tileColor: Colors.cyan,
        trailing: const Icon(Icons.more_vert),
        leading: const Icon(Icons.account_box),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<Widget>(builder: (BuildContext context) {
              return Scaffold(
                appBar: AppBar(title: const Text('ListTile Hero')),
                body: Center(
                  child: Hero(
                    tag: 'ListTile-Hero',
                    child: Material(
                      child: ListTile(
                        title: const Text('ListTile with Hero'),
                        subtitle: const Text('Tap here to go back'),
                        tileColor: Colors.blue[700],
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );

    Widget buttonSection = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildButtonColumn(color, Icons.call, 'CALL'),
        _buildButtonColumn(color, Icons.near_me, 'ROUTE'),
        _buildButtonColumn(color, Icons.share, 'SHARE'),
        const ChangeDarkModeButton(),
      ],
    );

    Widget textSection = const Padding(
      padding: EdgeInsets.all(32),
      child: Text(
        'Lake Oeschinen lies at the foot of the Blüemlisalp in the Bernese '
        'Alps. Situated 1,578 meters above sea level, it is one of the '
        'larger Alpine Lakes. A gondola ride from Kandersteg, followed by a '
        'half-hour walk through pastures and pine forest, leads you to the '
        'lake, which warms to 20 degrees Celsius in the summer. Activities '
        'enjoyed here include rowing, and riding the summer toboggan run.',
        softWrap: true,
      ),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioLongPress()),
      ],
      child: MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(
          // 避免搜索时弹出键盘，让底部的minibar位置移动到tab顶部导致溢出的问题
          resizeToAvoidBottomInset: false,

          // ??? 从上倒下预计是:个人信息、功能按钮、软件信息等区块
          body: Column(
            children: [
              Expanded(flex: 1, child: userInfo),
              Expanded(flex: 1, child: textSection),
              Expanded(flex: 3, child: buttonSection),
            ],
          ),
        ),
      ),
    );
  }

  Column _buildButtonColumn(Color color, IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color),
        Container(
          margin: const EdgeInsets.only(top: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // 切换主题浅色/深色的按钮
}

class ChangeDarkModeButton extends StatefulWidget {
  const ChangeDarkModeButton({super.key});

  @override
  State<ChangeDarkModeButton> createState() => _ChangeDarkModeButtonState();
}

class _ChangeDarkModeButtonState extends State<ChangeDarkModeButton> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ChangeDisplayMode>(
      builder: (context, cdm, child) {
        bool isDarkMode = cdm.currentDisplayMode == DisplayMode.DARK;

        return ElevatedButton.icon(
          onPressed: () {
            setState(() {
              isDarkMode = !isDarkMode;
              if (isDarkMode) {
                cdm.changeCurrentDisplayMode(DisplayMode.DARK);
              } else {
                cdm.changeCurrentDisplayMode(DisplayMode.LIGHT);
              }
            });
          },
          icon: Icon(
            isDarkMode ? Icons.dark_mode : Icons.light_mode,
            size: 24.0.sp,
          ),
          label: Text(isDarkMode ? "DARK" : "LIGHT"),
        );
      },
    );
  }
}
