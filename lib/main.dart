import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'layout/app.dart';
import 'services/service_locator.dart';

Future<void> main() async {
  // 启动时注册service
  await setupServiceLocator();

  // 这一堆是为了能够背景播放音乐（返回类型也不再是void）
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.swm.freadermediaplayer',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
    notificationColor: const Color.fromARGB(1, 0, 206, 209),
  );
  runApp(const FreaderApp());
}
