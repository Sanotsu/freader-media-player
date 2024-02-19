# “恐龙游戏”小游戏说明

恐龙游戏是原本内嵌在 chrome 里的小游戏，更多可去官网 [T-Rex Chrome Dino Game](https://chromedino.com/) 游玩。

这个原项目是 github 上的 [HeveshL/flutter-dinosaur](https://github.com/HeveshL/flutter-dinosaur)，上次提交是在 2022-06-28。

但我还发现一个项目 [avinashkranjan/Dino](https://github.com/avinashkranjan/Dino) 代码几乎一模一样，上次提交是在 2023-05-09,但好像没有明确说明是否 fork 而来。

## 和原项目的一些改动：

- 简单调整了项目的结构和加了一点点注释帮助自己理解
- 设置的弹窗有一些小改动，避免了键盘弹出后出现溢出问题和莫名自动收起的情况
- 添加了当游戏结束时界面上显示“游戏结束”文字
- 最高得分进行本地持久化，下一次游玩还能看到之前历史最佳
