# 扫雷小游戏说明

2024-02-01：

原项目在 github 中的 [recepsenoglu/minesweeper](https://github.com/recepsenoglu/minesweeper/tree/main)。

如果有 flutter 学习的需要，强烈建议查看原项目进行学习，作为一个可以发布到 Google play 的应用，各方面细节也比较完善，比如打分、隐私策略、分享等一般学习 demo 很少考虑的。

## 和原项目的一些改动：

因为时间关系，并没有太深入学习和研究，但为了减少一些内容清除了很多东西：

- 原项目的”settings“有很多内容，基本都删除了，仅仅保留 howToPlay 和原作者简单信息；
- i10n 也删除了，也未启用 generateRoute 的导航方式
  - 原本默认的英文文字也简单替换为中文
- 使用 google_fonts 美化的一些字体体验也取消了
- 因为使用了 just_audio 来播放游戏音乐，和我原本的音乐播放器功能和背景播放使用的 just_audio_background 有一些冲突
  - 后者只能单音源，所以复用了音乐播放器的 AudioPlayer，但在播放游戏背景音乐时还会在状态栏有显示
    - 这个问题，暂不处理，后续考虑整体的替换为 audio_service 来支持多音源
- 原本是单应用，现在作为一个子模块，有修改一些页面导航的问题
  - 部分导航的跳转和之前的小游戏有区别，尤其在使用了 pushAndRemoveUntil 的地方
- TODO
  - 没有替换原本的 shared_preferences，后续可以考虑使用 get_storage 替换之
  - 在使用 just_audio 的前提下，添加 audio_service 支持多音源
  - 游戏背景音乐时，状态栏不显示
