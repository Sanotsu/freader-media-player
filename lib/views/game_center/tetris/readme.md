# 俄罗斯方块小游戏说明

2024-01-30：

原项目在 github 中的 [boyan01/flutter-tetris](https://github.com/boyan01/flutter-tetris)，由于时间关系没有完全细致地学习。

## 和原示例的一些改动：

- GameState 游戏状态增加了一个缓存历史最高分的栏位。
  - 但是因此右侧的 StatusPanel 的布局在横向时可能会有错位；
  - 又因为时间关系和 FMP 的配合情况，“休闲游戏”是强制竖屏的，所以暂时不会出现横屏游戏的情况；
- 原项目的 i10n 也是旧版本内容，暂时也全都取消了；
- 原项目时单独的一个 app，现在作为一个模块的页面，出现了一个返回上一页之后`setState() called after dispose()`报错的问题，已修复；
- 原项目的`navigatorObservers`也似乎没有用到，所以也取消了相关代码。
