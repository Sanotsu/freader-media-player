import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'layout/app.dart';
import 'services/service_locator.dart';

Future<void> main() async {
  // 启动时注册service
  await setupServiceLocator();

  // 这一堆是为了能够背景播放音乐（返回类型也不再是void）
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.swm.freader_music_player',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  runApp(const FreaderApp());
}
