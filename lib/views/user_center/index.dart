// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:random_avatar/random_avatar.dart';

import '../../common/utils/global_styles.dart';
import '../../common/utils/tools.dart';
import '../../models/change_display_mode.dart';
import '../local_music/widgets/common_small_widgets.dart';

class UserCenter extends StatefulWidget {
  const UserCenter({super.key});

  @override
  State<UserCenter> createState() => _UserCenterState();
}

class _UserCenterState extends State<UserCenter> {
  @override
  Widget build(BuildContext context) {
    ChangeDisplayMode cdm = context.watch<ChangeDisplayMode>();

    bool isDarkMode = cdm.currentDisplayMode == DisplayMode.DARK;

    // 用户信息标头
    Widget userInfoSection = Center(
      child: ListTile(
        title: Text(
          ' Named 小流',
          style: TextStyle(fontSize: sizeHeadline1),
        ),
        subtitle: SimpleMarqueeOrText(
          data: '个人资料模块占位页面，只有【切换主题按钮】可用。',
          style: TextStyle(fontSize: sizeContent2),
          velocity: 50,
          showLines: 2,
          height: 40.sp,
        ),
        // tileColor: Colors.cyan,
        // leading: Icon(Icons.account_box, size: 50.sp),
        leading: RandomAvatar('南方有', trBackground: true, height: 50, width: 50),
        trailing: SizedBox(
          width: 50.sp,
          child: Center(child: Icon(Icons.more_vert, size: 24.sp)),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<Widget>(builder: (BuildContext context) {
              return Scaffold(
                appBar: AppBar(title: const Text('(预留的某功能详情页)')),
                body: Center(
                  child: Hero(
                    tag: 'ListTile-Hero',
                    child: Material(
                      child: ListTile(
                        title: const Text('这里预留的个人详情或其他新页面'),
                        subtitle: const Text('点击此处返回'),
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

    // 功能按钮区域
    Widget buttonSection = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          width: 60.sp,
          child: Card(
            elevation: 1.sp,
            child: IconButton(
              icon: const Icon(Icons.language),
              iconSize: 24.sp,
              // color: Theme.of(context).primaryColor,
              onPressed: () {},
            ),
          ),
        ),
        SizedBox(
          width: 60.sp,
          child: Card(
            elevation: 1.sp,
            child: TextButton(
              style: TextButton.styleFrom(
                // iconColor: Theme.of(context).primaryColor,
                textStyle: TextStyle(fontSize: sizeContent2),
              ),
              onPressed: () {},
              child: const Text('团结', style: TextStyle(color: Colors.black)),
            ),
          ),
        ),
        SizedBox(
          width: 60.sp,
          child: Card(
            elevation: 1.sp,
            child: TextButton(
              style: TextButton.styleFrom(
                textStyle: TextStyle(fontSize: sizeContent2),
              ),
              onPressed: () {},
              child: const Text('进步', style: TextStyle(color: Colors.black)),
            ),
          ),
        ),
        SizedBox(
          width: 60.sp,
          child: Card(
            elevation: 1.sp,
            child: const ChangeDarkModeButton(),
          ),
        ),
      ],
    );

    // 显示不定长为本信息区域
    Widget textSection = const Padding(
      padding: EdgeInsets.all(12),
      child: Text(
        """(预留来显示一段固定区域但内容不定长的文字)\n"""
        "南方有鸟焉，名曰“蒙鸠”，以羽为巢，而编之以发，系之苇苕。风至苕折，卵子死。"
        "巢非不完也，所系者然也。西方有木焉，名曰“射干”，茎长四寸，生于高山之上，"
        "而临百仞之渊。木茎非能也，所立者然也。蓬生麻中，不扶而直；白沙在涅，与之俱黑。"
        "兰槐之根是为芷，其渐之滫，君子不近，庶人不服。其质非不美也，所渐者然也。"
        "故君子居必择乡，游必就士，所以防邪僻而中正也。",
        softWrap: true,
      ),
    );

    // 占位区域

    Widget demoSection = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildButtonColumn(Icons.call, 'CALL'),
        _buildButtonColumn(Icons.near_me, 'ROUTE'),
        _buildButtonColumn(Icons.share, 'SHARE'),
      ],
    );

    return MaterialApp(
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        // ??? 从上倒下预计是:个人信息、功能按钮、软件信息等区块
        body: ListView(
          children: [
            SizedBox(
              height: 100.sp,
              child: Container(
                // color: Colors.amber,
                child: userInfoSection,
              ),
            ),
            SizedBox(
              height: 100.sp,
              child: Container(
                // color: Colors.orange,
                child: buttonSection,
              ),
            ),
            SizedBox(
              height: 100.sp,
              child: SingleChildScrollView(
                child: Container(
                  // color: Colors.red,
                  child: textSection,
                ),
              ),
            ),
            SizedBox(height: 60.sp, child: Center(child: demoSection)),
            SizedBox(
              height: 40.sp,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ListTile(
                  title: Text("更多功能(预留)", style: TextStyle(fontSize: 20.sp)),
                  // subtitle: const Text("随机生成很多头像，带圆角或透明背景"),
                ),
              ),
            ),

            // 生成这一堆随机头像好像挺耗费性能的，暂时不显示了
            // 嵌套list view，内部这个需要加入 shrinkWrap 和 physics 这两个属性和值
            /*
            ListView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              // list每个Item的高度
              itemExtent: 100,
              itemCount: 4,
              itemBuilder: (context, index) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildRondomAvatar(),
                    buildRondomAvatar(),
                    RandomAvatar(getRandomString(8), height: 50, width: 50),
                    RandomAvatar(getRandomString(4), height: 50, width: 50)
                  ],
                );
              },
            ),
            */
          ],
        ),
      ),
    );
  }

  Column _buildButtonColumn(IconData icon, String label) {
    // Color cusColor = Theme.of(context).primaryColorDark;
    Color cusColor = Colors.black;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: cusColor),
        Container(
          margin: const EdgeInsets.only(top: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: cusColor,
            ),
          ),
        ),
      ],
    );
  }

  buildRondomAvatar() {
    return RandomAvatar(
      getRandomString(8),
      trBackground: true, // 将背景颜色设置为透明
      height: 50,
      width: 50,
    );
  }
}

// 切换主题浅色/深色的按钮

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

        return IconButton(
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
            color: Theme.of(context).primaryColor,
            size: 24.0.sp,
          ),
        );

        // return ElevatedButton.icon(
        //   onPressed: () {
        //     setState(() {
        //       isDarkMode = !isDarkMode;
        //       if (isDarkMode) {
        //         cdm.changeCurrentDisplayMode(DisplayMode.DARK);
        //       } else {
        //         cdm.changeCurrentDisplayMode(DisplayMode.LIGHT);
        //       }
        //     });
        //   },
        //   icon: Icon(
        //     isDarkMode ? Icons.dark_mode : Icons.light_mode,
        //     size: 24.0.sp,
        //   ),
        //   label: Text(isDarkMode ? "DARK" : "LIGHT"),
        // );
      },
    );
  }
}
