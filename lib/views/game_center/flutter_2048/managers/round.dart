import 'package:flutter_riverpod/flutter_riverpod.dart';

///
/// 为了完成结束回合逻辑(在./manager/board.dart中的end round)，需要首先添加 2 个管理器中的一个
///
/// A Notifier when a round starts, in order to prevent the next round starts before the current ends
/// prevent's animation issues when user tries to move tiles too soon.
/// 当一轮游戏开始时发出提示，以防止下一轮游戏在当前游戏结束前开始，从而避免用户过早移动图块时出现动画问题。
///
/// RoundManager 持有一个简单的布尔值，用于跟踪回合何时开始和回合何时结束，
/// 这将用于防止动画问题，如果动画在上一个动画结束之前开始，则可能会发生动画问题。
/// 当添加动画时，它会变得更加清晰。
///
class RoundManager extends StateNotifier<bool> {
  RoundManager() : super(true);

  void end() {
    state = true;
  }

  void begin() {
    state = false;
  }
}

final roundManager = StateNotifierProvider<RoundManager, bool>((ref) {
  return RoundManager();
});
