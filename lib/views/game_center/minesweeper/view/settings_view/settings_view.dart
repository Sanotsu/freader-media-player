import 'package:flutter/material.dart';

import '../../utils/exports.dart';
import '../../widgets/option_group_widget.dart';
import '../../widgets/option_widget.dart';
import '../about_view/about_view.dart';
import '../how_to_play_view/how_to_play_view.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.background,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text('设置'),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: GameSizes.getWidth(0.05),
        ),
      ),
      body: SingleChildScrollView(
        padding: GameSizes.getSymmetricPadding(0.05, 0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OptionGroup(options: [
              OptionWidget(
                title: '玩法说明',
                iconData: Icons.play_arrow,
                iconColor: Colors.green,
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HowToPlayView(),
                      ));
                },
              ),
            ]),
            OptionGroup(
              options: [
                OptionWidget(
                  title: '关于',
                  iconData: Icons.info,
                  iconColor: Colors.grey,
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutView(),
                        ));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
