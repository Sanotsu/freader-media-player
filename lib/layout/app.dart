// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

import 'home.dart';

class FreaderApp extends StatelessWidget {
  const FreaderApp({super.key});

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
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isPermissionGranted = false;

  @override
  void initState() {
    super.initState();

    // app初次启动时要获取相关授权，取得之后就不需要重复请求了
    _requestPermission();
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
  }

  @override
  Widget build(BuildContext context) {
    return !isPermissionGranted
        ? const Image(image: AssetImage('assets/launch_background.png'))
        : const HomePage();
  }
}
