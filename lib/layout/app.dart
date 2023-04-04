// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../common/personal/constants.dart';
import 'home.dart';

class FreaderApp extends StatelessWidget {
  const FreaderApp({Key? key}) : super(key: key);

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
          title: 'freader_music_player',
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
          ),
          home: const MyHomePage(title: 'freader_music_player_home'),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isLogin = false;

  @override
  void initState() {
    super.initState();
    getLoginState();
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

  @override
  Widget build(BuildContext context) {
    return isLogin
        ? const HomePage(title: 'Flutter Demo Home Page')
        : const HomePage(title: 'Flutter Demo Home Page');
  }
}
