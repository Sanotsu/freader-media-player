import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_swipe_detector/flutter_swipe_detector.dart';

/*
In case user swipes too fast we prevent for the next round to start until the current round finishes, we do that using the RoundManager,
but instead of canceling that round we will queue it so that the round automatically starts as soon the current finishes,
that way we will prevent the user feeling like the game is lag-ish or slow.

如果用户刷得太快，使用 RoundManager 防止下一轮开始，直到当前一轮结束;
但不会取消下一轮游戏，而是将其排成队列，以便在当前游戏结束后自动开始下一轮游戏，这样用户就不会感觉游戏迟滞或缓慢。
*/
class NextDirectionManager extends StateNotifier<SwipeDirection?> {
  NextDirectionManager() : super(null);

  void queue(direction) {
    state = direction;
  }

  void clear() {
    state = null;
  }
}

final nextDirectionManager =
    StateNotifierProvider<NextDirectionManager, SwipeDirection?>((ref) {
  return NextDirectionManager();
});
