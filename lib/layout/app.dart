// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

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
  // 当处于加载中时，显示空白(默认加载中，直到获取存储权限完成)
  bool isLoading = true;

  // 是否获得了存储权限(每获得就要退出app)
  bool isPermissionGranted = false;

  @override
  void initState() {
    super.initState();

    // app初次启动时要获取相关授权，取得之后就不需要重复请求了
    _requestPermission();
  }

  // 获取存储权限
  _requestPermission() async {
    /// 2024-01-12 直接询问存储权限，不给就直接显示退出就好
    // 2024-01-12 Android13之后，没有storage权限了，取而代之的是：
    // Permission.photos, Permission.videos or Permission.audio等
    // 参看:https://github.com/Baseflow/flutter-permission-handler/issues/1247
    if (Platform.isAndroid) {
      // 获取设备sdk版本
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      int sdkInt = androidInfo.version.sdkInt;

      if (sdkInt <= 32) {
        PermissionStatus storageStatus = await Permission.storage.request();
        setState(() {
          if (storageStatus.isGranted) {
            isPermissionGranted = true;
          } else {
            isPermissionGranted = false;
          }
          isLoading = false;
        });
      } else {
        Map<Permission, PermissionStatus> statuses = await [
          Permission.audio,
          Permission.photos,
          Permission.videos,
        ].request();

        if (statuses[Permission.audio]!.isGranted &&
            statuses[Permission.photos]!.isGranted &&
            statuses[Permission.videos]!.isGranted) {
          setState(() {
            isPermissionGranted = true;
            isLoading = false;
          });
        } else {
          setState(() {
            isPermissionGranted = false;
            isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Container(color: Colors.white)
        : !isPermissionGranted
            ? Container(
                color: const Color.fromARGB(1, 0, 206, 209),
                child: AlertDialog(
                  title: const Text('未授予存储访问权限'),
                  content: const Text('无权限去获取存储中的音视频文件。请授予应用程序访问存储的权限以继续使用。'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('确定'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        SystemChannels.platform
                            .invokeMethod('SystemNavigator.pop');
                      },
                    ),
                  ],
                ),
              )
            : const HomePage();
  }
}
