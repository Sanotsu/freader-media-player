import 'package:flutter/material.dart';

import '../../mixins/statistics_mixin.dart';
import '../../utils/game_colors.dart';
import '../../utils/game_consts.dart';
import '../../utils/game_sizes.dart';

class StatsTable extends StatelessWidget with StatisticsMixin {
  final GameMode gameMode;
  const StatsTable({super.key, required this.gameMode});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getStatistic(gameMode),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("statisticsError"));
          }

          Map<String, dynamic> stats = snapshot.data!;

          return Padding(
            padding: GameSizes.getPadding(0.04),
            child: Column(
              children: [
                StatWidget(
                  iconData: Icons.grid_on_rounded,
                  statName: "游戏次数",
                  statValue: stats['gamesStarted'],
                ),
                StatWidget(
                  iconData: Icons.workspace_premium_outlined,
                  statName: "通关次数",
                  statValue: stats['gamesWon'],
                ),
                StatWidget(
                  iconData: Icons.flag_outlined,
                  statName: "通关概率",
                  statValue: stats['winRate'],
                ),
                StatWidget(
                  iconData: Icons.timer_outlined,
                  statName: "最短耗时",
                  statValue: stats['bestTime'],
                ),
                StatWidget(
                  iconData: Icons.access_time_sharp,
                  statName: "平均耗时",
                  statValue: stats['averageTime'],
                ),
              ],
            ),
          );
        });
  }
}

class StatWidget extends StatelessWidget {
  const StatWidget({
    super.key,
    required this.iconData,
    required this.statName,
    required this.statValue,
  });

  final IconData iconData;
  final String statName;
  final dynamic statValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: GameSizes.getPadding(0.04),
      margin: EdgeInsets.only(bottom: GameSizes.getHeight(0.015)),
      decoration: BoxDecoration(
        color: GameColors.darkBlue.withOpacity(0.2),
        borderRadius: GameSizes.getRadius(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                iconData,
                size: GameSizes.getWidth(0.08),
                color: Colors.black,
              ),
              SizedBox(height: GameSizes.getHeight(0.015)),
              Text(
                statName,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: GameSizes.getWidth(0.035),
                ),
              ),
            ],
          ),
          Text(
            statValue == null ? "-" : statValue.toString(),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: GameSizes.getWidth(0.048),
            ),
          ),
        ],
      ),
    );
  }
}
