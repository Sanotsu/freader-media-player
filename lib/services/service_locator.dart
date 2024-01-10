import 'package:get_it/get_it.dart';

import 'my_audio_handler.dart';
import 'my_audio_query.dart';
import 'my_get_storage.dart';

GetIt getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // services
  getIt.registerLazySingleton<MyGetStorage>(() => MyGetStorage());
  getIt.registerLazySingleton<MyAudioQuery>(() => MyAudioQuery());
  getIt.registerLazySingleton<MyAudioHandler>(() => MyAudioHandler());
}
