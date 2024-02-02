import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../../../services/my_audio_handler.dart';
import '../../../../services/service_locator.dart';

/// this class define sound effect
// class SoundEffect {
//   static bool _init = false;

//   static final AudioPlayer _wrongAudio = AudioPlayer();
//   static final AudioPlayer _victoryAudio = AudioPlayer();
//   static final AudioPlayer _gameOverAudio = AudioPlayer();
//   // show user tips sound effect
//   static final AudioPlayer _answerTipAudio = AudioPlayer();

//   static init() async {
//     if (!_init) {
//       await _wrongAudio.setAsset("assets/games/sodoku/audio/wrong_tip.mp3");
//       await _victoryAudio.setAsset("assets/games/sodoku/audio/victory_tip.mp3");
//       await _gameOverAudio
//           .setAsset("assets/games/sodoku/audio/gameover_tip.mp3");
//       await _answerTipAudio.setAsset("assets/games/sodoku/audio/wrong_tip.mp3");
//     }
//     _init = true;
//   }

//   static stuffError() async {
//     if (!_init) {
//       await init();
//     }
//     await _wrongAudio.seek(Duration.zero);
//     await _wrongAudio.play();
//     return;
//   }

//   static solveVictory() async {
//     if (!_init) {
//       await init();
//     }
//     await _victoryAudio.seek(Duration.zero);
//     await _victoryAudio.play();
//   }

//   static gameOver() async {
//     if (!_init) {
//       await init();
//     }
//     await _gameOverAudio.seek(Duration.zero);
//     await _gameOverAudio.play();
//   }

//   static answerTips() async {
//     if (!_init) {
//       await init();
//     }
//     await _answerTipAudio.seek(Duration.zero);
//     await _answerTipAudio.play();
//   }
// }

/// 和其他使用just audio插件做游戏背景音的类似，这和我默认的背景播放冲突，简单改造如下

/// this class define sound effect
class SoundEffect {
  static bool _init = false;

  final _audioHandler = getIt<MyAudioHandler>();
  static late AudioPlayer _player;

  final String _wrongAudio = "assets/games/sodoku/audio/wrong_tip.mp3";
  final String _victoryAudio = "assets/games/sodoku/audio/victory_tip.mp3";
  final String _gameOverAudio = "assets/games/sodoku/audio/gameover_tip.mp3";
  final String _answerTipAudio = "assets/games/sodoku/audio/wrong_tip.mp3";

  init() {
    if (!_init) {
      _player = _audioHandler.player();
    }
    _init = true;
  }

  Future<void> playAudio(String audioPath, {bool loop = false}) async {
    try {
      await _player.setAudioSource(AudioSource.asset(
        audioPath,
        tag: MediaItem(id: audioPath, title: audioPath),
      ));

      // 只播放一次
      await _player.setLoopMode(LoopMode.off);
      await _player.seek(Duration.zero);
      await _player.play();
      
      await _player.stop();
    } catch (e) {
      debugPrint("Error loading audio source: $e");
    }
  }

  stuffError() async {
    if (!_init) {
      init();
    }
    await playAudio(_wrongAudio);
    return;
  }

  solveVictory() async {
    if (!_init) {
      init();
    }

    await playAudio(_victoryAudio);
  }

  gameOver() async {
    if (!_init) {
      init();
    }
    await playAudio(_gameOverAudio);
  }

  answerTips() async {
    if (!_init) {
      await init();
    }
    await playAudio(_answerTipAudio);
  }
}
