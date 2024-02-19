# 扫雷小游戏说明(TBC)

2024-02-02：

原项目在 github 中的 [einsitang/sudoku-flutter](https://github.com/einsitang/sudoku-flutter)。

原项目也比较完善，有需求可以看看

## 和原项目的一些改动：

因为时间关系，基本上只是拿来放在这里了，很多都没处理，甚至其主页都还是用的 MaterialApp，者一个应用有两个 MaterialApp 就很不合理，放假回来之后再处理：

- 删除了 i10n 的部分，简单替换了中文(主要因为报错太多，为了快速跑起来)
- TODO
  - 原本在加载数独时的\_sudokuGenerate 会有加载中弹窗，但加载完成之后弹窗未关闭(现在是不弹窗了)
  - scoped_model 和 modal_bottom_sheet 库还没看
  - 应该替换掉 hive 和 hive_flutter
  - debug 的 logger 也没有必要
  - 只有一个小地方使用了 sprintf 库，可以想办法取消掉
  - 在使用 just_audio 的前提下，添加 audio_service 支持多音源
  - 需要让播放游戏背景音乐时，状态栏不显示
