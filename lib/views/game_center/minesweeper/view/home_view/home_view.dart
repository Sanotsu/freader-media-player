import 'package:flutter/material.dart';
import 'package:freader_media_player/layout/home.dart';

import '../../../../../services/my_get_storage.dart';
import '../../../../../services/service_locator.dart';
import '../../utils/exports.dart';
import '../../widgets/custom_button.dart';
import '../settings_view/settings_view.dart';
import '../statistics_view/statistics_view.dart';
import 'components/animated_play_button.dart';
import 'components/miniature_minefield.dart';

class MinesweeperHomeView extends StatefulWidget {
  const MinesweeperHomeView({super.key});

  @override
  State<MinesweeperHomeView> createState() => _MinesweeperHomeViewState();
}

class _MinesweeperHomeViewState extends State<MinesweeperHomeView> {
  // 统一简单存储操作的工具类实例
  final _simpleStorage = getIt<MyGetStorage>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        // 2024-02-01 不包裹在这里面，点击返回到游戏中心可能不生效，还会报错，可参看：
        // https://stackoverflow.com/questions/55618717/error-thrown-on-navigator-pop-until-debuglocked-is-not-true
        // 其他使用pushAndRemoveUntil的同理
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Navigator.of(context)
          //   ..pop()
          //   ..pop();
          // Navigator.of(context).pop();

          // 理论上这里点击返回应该返回到游戏中心页面，但是不加这个popscope，返回就直接退出app了；
          // 如果只有pop，也不会生效； 如果替换路由时gamecenter，那就不会有下方导航栏了
          // 因此，需要指定展示的底部导航索引(存在底部显示3个或者5个索引的情况，要区分传值)

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(
                selectedIndex: _simpleStorage.getBottomNavItemMun() > 3 ? 4 : 2,
              ),
            ),
            (route) => false,
          );
        });
      },
      child: Scaffold(
        backgroundColor: GameColors.mainSkyBlue,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(height: GameSizes.getHeight(0.05)),
            // 游戏名称
            const GameTitle(title: 'minesweeper'),
            // 中间简单的游戏示例
            const MiniatureMinefield(),
            Column(
              children: [
                // 动画开始游戏按钮
                const AnimatedPlayButton(),
                SizedBox(height: GameSizes.getHeight(0.04)),
                // 统计按钮和设置按钮
                Padding(
                  padding: GameSizes.getHorizontalPadding(0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: CustomButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const StatisticsView(),
                                ));
                          },
                          elevation: 6,
                          icon: Icons.bar_chart,
                          text: '统计',
                          iconSize: GameSizes.getWidth(0.06),
                          height: GameSizes.getHeight(0.06),
                        ),
                      ),
                      SizedBox(width: GameSizes.getWidth(0.05)),
                      Expanded(
                        child: CustomButton(
                          onPressed: () async {
                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsView(),
                                ));
                            setState(() {});
                          },
                          elevation: 6,
                          icon: Icons.settings,
                          text: "设置",
                          iconSize: GameSizes.getWidth(0.06),
                          height: GameSizes.getHeight(0.06),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Image.asset(Images.homeScreenBg.toPath),
          ],
        ),
      ),
    );
  }
}

class GameTitle extends StatelessWidget {
  const GameTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: GameSizes.getHorizontalPadding(0.1),
      child: FittedBox(
        child:
            // Text(
            //   title.toUpperCase(),
            //   style: TextStyle(
            //     letterSpacing: 4,
            //     color: Colors.white,
            //     fontWeight: FontWeight.w600,
            //     backgroundColor: Colors.black,
            //     fontSize: GameSizes.getWidth(0.1),
            //   ),
            // ),
            Text(
          title.toUpperCase(),
          style: TextStyle(
            letterSpacing: 4,
            color: Colors.white,
            fontSize: GameSizes.getWidth(0.1),
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
            shadows: const [
              Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
              Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
              Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
              Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }
}
