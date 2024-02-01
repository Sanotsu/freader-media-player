import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../../../services/my_audio_handler.dart';
import '../../../../services/service_locator.dart';
import '../utils/game_sounds.dart';

class GameAudioPlayer {
  final _audioHandler = getIt<MyAudioHandler>();

  static late AudioPlayer _player;
  static bool playable = true;

  GameAudioPlayer() {
    // 2024-02-01 因为有用到 just_audio_background，不支持多音源播放，可以使用 audio_service ，、
    // 但暂时不做，因为放着歌还听背景音乐不方便，也主要是懒
    // 因为和音乐播放器共用同一个player，所以这里直接复用音乐播放器的那个
    // _player = AudioPlayer();
    _player = _audioHandler.player();
    _player.play();
  }

  // 2024-02-01 因为和音乐播放器共用同一个player，所以扫雷重置音乐播放只是停止即可
  void resetPlayer(bool soundOn) {
    _player.stop();
    _player.setVolume(soundOn ? 1 : 0);
  }

  static void pause() {
    playable = false;
    _player.pause();
  }

  static void resume() {
    playable = true;
    try {
      _player.play();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  static Future<void> setVolume(bool soundOn) async {
    await _player.setVolume(soundOn ? 1 : 0);
  }

  /// 2024-02-01 因为我原本使用的音频播放器也是just audio，所以这里会报错：
  /// Unhandled Exception: PlatformException(error, just_audio_background supports only a single player instance, null, null)

  Future<bool> _setAudio(String audioPath) async {
    try {
      // 2024-02-01 原本使用这些方式替换音乐，但是会报错如下：
      // Error loading audio source: type 'Null' is not a subtype of type 'MediaItem' in type cast
      // 应该还是和背景播放有些冲突，所以使用下面那个
      // await _player.setAudioSource(
      //   AudioSource.asset(audioPath),
      // );
      // await _player.setAsset(audioPath);

      await _player.setAudioSource(AudioSource.asset(
        audioPath,
        tag: MediaItem(
          id: audioPath,
          title: audioPath,
        ),
      ));

      _player.setLoopMode(LoopMode.off);
      return true;
    } catch (e) {
      debugPrint("Error loading audio source: $e");
    }
    return false;
  }

  Future<void> playAudio(Sound sound, {bool loop = false}) async {
    if (await _setAudio(sound.toPath) && playable) {
      if (loop) {
        _player.setLoopMode(LoopMode.one);
      }
      _player.play();
    }
  }
}
