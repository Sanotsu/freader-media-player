import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:scoped_model/scoped_model.dart';

import 'effect/sound_effect.dart';
import 'page/bootstrap.dart';
import 'state/sudoku_state.dart';

class InitSudoku extends StatefulWidget {
  const InitSudoku({super.key});

  @override
  State<InitSudoku> createState() => _InitSudokuState();
}

class _InitSudokuState extends State<InitSudoku> {
  // initialization effect when application build before
  _initEffect() async {
    await SoundEffect().init();
  }

  Future<SudokuState> _loadState() async {
    await _initEffect();
    return await SudokuState.resumeFromDB();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SudokuState>(
      future: _loadState(),
      builder: (context, AsyncSnapshot<SudokuState> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.white,
            alignment: Alignment.center,
            child: Center(
              child: Text(
                '数独游戏初始化中...',
                style: TextStyle(color: Colors.black, fontSize: 12.sp),
                textDirection: TextDirection.ltr,
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          debugPrint("here is builder future throws error you shoud see it");
        }
        SudokuState sudokuState = snapshot.data ?? SudokuState();
        BootstrapPage bootstrapPage = const BootstrapPage(title: "Loading");

        // return ScopedModel<SudokuState>(
        //   model: sudokuState,
        //   child: bootstrapPage,
        // );

        /// todo 2024-02-02 由于这个 scoped_model 还有去研究，所以这里还是app
        return ScopedModel<SudokuState>(
          model: sudokuState,
          child: MaterialApp(
            title: 'Sudoku',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            locale: const Locale('zh'),
            home: bootstrapPage,
          ),
        );
      },
    );
  }
}
