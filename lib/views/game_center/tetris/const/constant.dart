// ignore_for_file: constant_identifier_names

import 'dart:ui';

// 游戏主界面边框宽度
const SCREEN_BORDER_WIDTH = 3.0;

// 主页面背景颜色
const BACKGROUND_COLOR = Color(0xffefcc19);

// 右侧数字行的尺寸
const DIGITAL_ROW_SIZE = Size(14, 24);

// 游戏控制按钮的矩阵宽高
///the height of game pad
const GAME_PAD_MATRIX_H = 20;

///the width of game pad
const GAME_PAD_MATRIX_W = 10;

// 控制板边框
const PLAYER_PANEL_PADDING = 6;

///duration for show a line when reset
///重置时显示行的持续时间
const REST_LINE_DURATION = Duration(milliseconds: 50);

// 游戏难度等级及其对应的方块下落速度
const LEVEL_MAX = 6;
const LEVEL_MIN = 1;
const SPEED = [
  Duration(milliseconds: 800),
  Duration(milliseconds: 650),
  Duration(milliseconds: 500),
  Duration(milliseconds: 370),
  Duration(milliseconds: 250),
  Duration(milliseconds: 160),
];
