import 'package:get_it/get_it.dart';

import 'my_audio_handler.dart';
import 'my_audio_query.dart';

GetIt getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // services
  getIt.registerLazySingleton<MyAudioHandler>(() => MyAudioHandler());
  getIt.registerLazySingleton<MyAudioQuery>(() => MyAudioQuery());
}
