import 'package:flutter/material.dart';

import '../../controller/game_controller.dart';
import '../../helper/shared_helper.dart';
import '../../model/tile_model.dart';
import '../../utils/exports.dart';
import '../../widgets/game_popup_screen.dart';

class MineField extends StatelessWidget {
  final GameController gameController;
  const MineField({super.key, required this.gameController});

  @override
  Widget build(BuildContext context) {
    List<List<Tile>> mineField = gameController.mineField;

    return Center(
      child: GridView.builder(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10),
          itemCount: gameController.boardLength * 10,
          itemBuilder: (BuildContext context, index) {
            Tile tile = mineField[index ~/ 10][index % 10];

            if (tile.visible == false || tile.hasFlag) {
              return Grass(
                tile: tile,
                gameController: gameController,
                parentContext: context,
              );
            } else {
              if (tile.hasMine) return Mine(index: index, tile: tile);

              return OpenedTile(tile: tile);
            }
          }),
    );
  }
}

class Grass extends StatelessWidget {
  final Tile tile;
  final GameController gameController;
  final BuildContext parentContext;

  const Grass({
    super.key,
    required this.tile,
    required this.gameController,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () async {
          if (tile.hasFlag) return;

          await gameController.clickTile(tile)?.then((win) async {
            if (win != null) {
              final sharedHelper = await SharedHelper.init();
              int? bestTime =
                  await sharedHelper.getBestTime(gameController.gameMode);
              if (win) {
                await sharedHelper.updateAverageTime(
                    gameController.gameMode, gameController.timeElapsed);
                await sharedHelper.increaseGamesWon(gameController.gameMode);
                if (gameController.timeElapsed < (bestTime ?? 999)) {
                  bestTime = gameController.timeElapsed;
                  await sharedHelper.setBestTime(
                      gameController.gameMode, bestTime);
                }
              }
              return (win, bestTime);
            }
            return null;
          }).then((value) {
            if (value?.$1 != null) {
              if (!parentContext.mounted) return;
              GamePopupScreen.gameOver(
                parentContext,
                controller: gameController,
                bestTime: value!.$2,
                win: value.$1,
              );
            }
          });
        },
        onLongPress: () => gameController.placeFlag(tile),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: tile.row % 2 == 0 && tile.col % 2 == 0 ||
                    tile.row % 2 != 0 && tile.col % 2 != 0
                ? GameColors.grassLight
                : GameColors.grassDark,
            border: tileBorder(tile),
          ),
          child: tile.hasFlag
              ? tile.visible
                  ? Image.asset(Images.redCross.toPath)
                  : Image.asset(Images.flag.toPath)
              : const SizedBox(),
        ));
  }
}

class Mine extends StatelessWidget {
  final int index;
  final Tile tile;

  const Mine({super.key, required this.index, required this.tile});

  @override
  Widget build(BuildContext context) {
    Color mineColor =
        GameColors.mineColors[index % GameColors.mineColors.length];
    return Container(
      alignment: Alignment.center,
      padding: GameSizes.getPadding(0.02),
      decoration: BoxDecoration(
        color: mineColor,
        border: tileBorder(tile),
      ),
      child: CircleAvatar(backgroundColor: GameColors.darken(mineColor)),
    );
  }
}

class OpenedTile extends StatelessWidget {
  final Tile tile;

  const OpenedTile({super.key, required this.tile});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tile.row % 2 == 0 && tile.col % 2 == 0 ||
                tile.row % 2 != 0 && tile.col % 2 != 0
            ? GameColors.tileLight
            : GameColors.tileDark,
      ),
      child: tile.value > 0
          ? Text(
              tile.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: GameSizes.getWidth(0.06),
                color: GameColors.valueTextColors[tile.value - 1],
              ),
            )
          : const SizedBox(),
    );
  }
}

BoxBorder tileBorder(Tile tile) {
  return Border(
    top: createBorderSide(tile.ltrb[1]),
    left: createBorderSide(tile.ltrb[0]),
    right: createBorderSide(tile.ltrb[2]),
    bottom: createBorderSide(tile.ltrb[3]),
  );
}

BorderSide createBorderSide(bool isSolid) {
  return BorderSide(
    color: GameColors.tileBorder,
    width: GameSizes.getWidth(0.005),
    style: isSolid ? BorderStyle.solid : BorderStyle.none,
  );
}
