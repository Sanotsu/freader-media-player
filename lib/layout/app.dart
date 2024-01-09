// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../common/global/constants.dart';
import '../services/my_audio_handler.dart';
import '../services/service_locator.dart';
import 'home.dart';

class FreaderApp extends StatelessWidget {
  const FreaderApp({super.key});

  // 获取登陆信息，如果已经登录，则进入homepage，否则进入登录页面

  final isLogin = false;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 640), // 1080p / 3 ,单位dp
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, widget) {
        return MaterialApp(
          title: 'freader_media_player',
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('zh', 'CH'),
            Locale('en', 'US'),
          ],
          locale: const Locale('zh'),
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: false,
          ),
          home: const MyHomePage(),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isLogin = false;

  bool isPermissionGranted = false;

  final box = GetStorage();

  // 音乐播放实例
  final _audioHandler = getIt<MyAudioHandler>();

  @override
  void initState() {
    super.initState();
    getLoginState();
    // app初次启动时要获取相关授权，取得之后就不需要重复请求了
    // _requestPermission();
    setState(() {
      _requestPermission();
    });
  }

  // 获取登陆状态
  Future<void> getLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // 如果获取的登录状态字符串是 true，则表示登入过；否则就是没有登入过
      isLogin = (prefs.getBool(GlobalConstants.loginState) ?? false);

      print("isLogin-------$isLogin");
    });
  }

  // 获取存储权限
  _requestPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
    ].request();

    setState(() {
      isPermissionGranted = true;
    });

    final info = statuses[Permission.storage].toString();
    print("_requestPermission------------------$info");

    var a = box.read(GlobalConstants.currentAudioListType);
    var b = box.read(GlobalConstants.currentAudioIndex);
    var c = box.read(GlobalConstants.currentAudioListId);

    print("【【【在app启动时，myAudioHandlerInit前的 当前播放音乐:$a + $b + $c");

    // 获得授权后，音频控制初始化（主要从持久化数据中获取数据构建当前正在播放的音频和播放列表，没有持久化数据则是默认初始值）
    await _audioHandler.myAudioHandlerInit();

    var aa = box.read(GlobalConstants.currentAudioListType);
    var bb = box.read(GlobalConstants.currentAudioIndex);
    var cc = box.read(GlobalConstants.currentAudioListId);

    print("【【【在await myAudioHandlerInit 之后的 当前播放音乐:$aa + $bb + $cc");
  }

  @override
  Widget build(BuildContext context) {
    return isLogin
        ? const HomePage()
        : isPermissionGranted
            ? const HomePage()
            : const Image(image: AssetImage('assets/launch_background.png'));
  }
}
