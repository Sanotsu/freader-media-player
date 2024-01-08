// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../common/global/constants.dart';
import '../models/change_display_mode.dart';
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

  // 音乐播放实例
  final _audioHandler = getIt<MyAudioHandler>();

  @override
  void initState() {
    super.initState();
    getLoginState();
    // app初次启动时要获取相关授权，取得之后就不需要重复请求了
    _requestPermission();
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

    // 获得授权后，音频控制初始化（主要从持久化数据中获取数据构建当前正在播放的音频和播放列表，没有持久化数据则是默认初始值）
    _audioHandler.myAudioHandlerInit();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChangeDisplayMode()),
      ],
      child: isLogin
          ? const HomePage()
          : isPermissionGranted
              ? const HomePage()
              : const Image(image: AssetImage('assets/launch_background.png')),
    );
  }
}
