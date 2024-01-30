# 2048 小游戏说明

2024-01-29：学习原博文实现 2048 的一些重点。

原博文和项目[angjelkom/flutter_2048](https://github.com/angjelkom/flutter_2048/tree/main)，绝大部分都是直接复制过来的，仅有少部分配合 FMP 进行修改。

理论上已经有使用`provider`做状态管理了，但在学习这个项目时，觉得`riverpod`也还不错。目前都留着，后续有时间前者改为后者。

### 一些常见的 flutter 状态管理组件

关于 flutter 状态管理组件的一些信息，截止 2024-01-16：

[get: ^4.6.6](https://pub.dev/packages/get) : 13575 likes, 上次更新 2023-09-08
[provider: ^6.1.1](https://pub.dev/packages/provider) : 9407 likes, 上次更新 2023-11-10
[riverpod: ^2.4.9](https://pub.dev/packages/riverpod) : 3017 likes, 上次更新 2023-11-26
[flutter_bloc: ^8.1.3](https://pub.dev/packages/flutter_bloc) : 6356 likes, 上次更新 2023-05-20
[mobx: ^2.3.0+1](https://pub.dev/packages/mobx) : 1172 likes, 上次更新 2024-01-04

简单说来:

- getx
  - 优点：
    - 瑞士军刀式护航
    - 对新人友好
    - 可以减少很多代码
  - 缺点：
    - 全家桶，做的太多对于一些使用者来说是致命缺点，需要解决的 Bug 也多
    - “魔法”使用较多，脱离 Flutter 原本轨迹
    - 入侵性极强
- provider
  - 优点：
    - 简单好维护;
    - read、watch、select 提供更简洁的颗粒度管理
    - 官方推荐；
  - 缺点
    - 但相对依赖 Flutter 和 Widget，
    - 需要依赖 Context；
- riverpod
  - 优点：
    - 在 Provider 的基础上更加灵活的实现；
    - 不依赖 BuildContext ，所以业务逻辑也无需注入 BuildContext；
    - Riverpod 会尽可能通过编译时安全来解决存在运行时异常问题
    - 支持全局定义
    - ProviderReference 能更好解决嵌套代码
  - 缺点：
    - 实现更加复杂
    - 学习成本提高
- flutter_bloc
  - 优点：
    - 代码更加解耦，这是事件驱动的特性
    - 把状态更新和事件绑定，可以灵活得实现状态拦截，重试甚至撤回
  - 缺点：
    - 需要写更多的代码，开发节奏会有点影响
    - 接收代码的新维护人员，缺乏有效文档时容易陷入对着事件和业务蒙圈
    - 项目后期事件容易混乱交织
- mobx
  - 某种意义上可以把 Mobx 看成是只有状态管理版本的 GetX

### 项目结构

- components
  - ui 组件，可以是自定义 Button、自定义 AppBar 或其他一些自定义 UI
- managers
  - 状态管理
- model
  - 所有模型类
- screens
  - 存放导航跳转的页面(此处暂无)
- const
  - 一些常量值，如颜色、尺寸、端点等
- apis
  - 从 API 或后端检索数据的服务(此处暂无)

### 组件说明

可以将游戏分为两类组件，游戏组件和 ui 控制组件

- ui 控制组件：
  - “新游戏” 按钮开始一次新的游戏
  - “撤销”按钮撤销前一步操作
- 游戏组件:
  - Tile Widget
    - 可以移动、改变数字和颜色、且有编号的方块
  - Empty Board Widget
    - 空板小部件(注释之类的为了方便可能也称为“棋盘”)，即 4x4 的图块板，Tile 方块将在其上移动
  - Score Widget
    - 显示当前分数和最佳分数的分数小组件
  - Game Over/Won Widget
    - 将在用户输掉或赢得游戏时显示的游戏结束/获胜小部件

### 主体步骤

1. 构建常量，例如游戏中将使用的颜色`const/color.dart`
2. 构建游戏主界面，将包含上面所有的游戏和 UI 控制组件
   1. 需要使用到 Riverpod 的`ConsumerStatefulWidget` 组件来访问 ref 对象，这将允许访问添加的 StateNotifier
   2. 还需要在游戏最上层组件使用 ProviderScope ，以便添加的 StateNotifiers 可以在所有小部件中访问
   3. 逐步建立上面所有的游戏组件和 UI 控制组件，使得游戏主界面完整：
      - score_board、button、empty_board
3. 添加相关模型 Models 和用于管理游戏状态的 StateNotifier
   1. models: 数字方块的 Tile 模型、4x4 棋盘的 Board 模型
   2. manager(状态管理): board
      - board 状态管理是管理游戏中所有流程的主要 StateNotifier，例如：创建新游戏、结束游戏、移动图块、合并图块等。
4. 完善其他逻辑(保存分数到本地缓存等等，略)

### 工作流

how the flow works:

- The user Swipes in some direction
- We call the move method passing the direction
- The logic calculates the nextIndex and assigns it to the tile
- The state gets updated
- Based on the current screen size and the size of the tile and the index, the top/left position are retrieved (point A) and the top/left position for the the nextIndex are retrieved (point B)
- Having the positions for which the tile will move from point A to point B, we use Tweens which will interpolate those values and do the transitions.
- When the movement finishes we need to merge the tiles that are on the same index and mark them merged: true
- We need to mark them merged: true, so that we can start the pop effect only for the tiles that have been merged.
- After the move animation finishes and the tiles are merged we update the state and at the same time start the scale animation which gives us the pop effect.
- After the pop effect ends we need to end the round.
- We end the round by setting the merged tiles to merged: false
- And then the user either: won the game if a tile with number 2048 exists, lost the game if there are no more tiles to add on the board, do a merge if possible and then end the round or we start the next round right away in case the user swiped too soon while the current round wasn’t finished and we have a movement “queued” using the NextDirectionManager

---

- 玩家朝某个方向进行滑动，将调用包含传递方向参数的 `move()`方法，该方法有内部逻辑计算图块移动的下一个索引 nextIndex，并将该索引分配给该图块。
  - 如果 nextIndex 和当前的 index 是一样的，则表示该图块已经不可移动；
  - 如果移动后一行/列中有多个图块的 nextIndex 是一样的，则表示这些图块是可以合并的。
- 移动完成后，更新棋盘的状态。
- 根据当前屏幕的尺寸以及图块的索引和尺寸，获取 top/left 位置（点 A）和 nextIndex 的 top/left 位置（点 B）。
  - 有了图块从 A 点移动到 B 点的位置，使用 Tweens 来插入这些值来添加移动过渡动画。
- 当移动完成时，需要合并同一索引上的图块(本来每个图块的索引不一样，但移动后图块的索引是一样的，就表示他们可合并)，并将它们标记为`merged: true`，这样就可以只对已合并的图块启动弹出效果。
- 移动动画完成并且图块合并后，更新状态，同时启动缩放动画，给图块合并带来了弹出效果。
  - 当弹出动画效果结束后，就结束这个图块移动回合，需要重置已经合并的图块标识为`merged: false`来结束本回合。
- 回合结束后用户的选择如下:
  - 如果棋盘上存在编号为 2048 的图块，则赢得游戏；
  - 如果棋盘上没有更多位置可添加图块，则输掉游戏；
  - 如果有图块可以进行合并，就进行合并，然后结束本轮；
    - 或者立即开始下一轮以防用户在当前回合尚未完成时刷得太快，但要使用 NextDirectionManager 添加到图块移动的队列

> 应用程序中的任何视觉变化，无论是颜色变化、位置变化、文本变化、动画运行……任何小部件变化，都意味着状态变化发生在当前小部件或它的父部件。

其他需要补充完成的：

- 将 BoardManager 连接到记分板，每次图块移动更新得分情况；
- 当游戏获胜或者失败时棋盘上显示"新游戏"或"再来一次"按钮;
- 按下上方的“重新开始”图标按钮开始新游戏；
- 按下上方的“撤销”图标按钮撤销上一次移动；
- 在桌面程序可以使用箭头键移动图块。

### 和原示例的一些改动：

- 原示例使用 json_annotation、json_serialized 和 build_runner 生成 model 的 toJson 和 fromJson 方法，因为内容不多这里就取消了；
- 使用 hive 和 hive_flutter 来持久化棋盘状态，因为我已经有 get_storage 了，所以不再使用前者
- 原示例是个单独的 2048 app，是通过监听 app 状态在退出 app 时才保存棋盘状态
  - 原示例在主页面部件继承了 WidgetsBindingObserver 并进行侦听` WidgetsBinding.instance.addObserver(this);`，然后`didChangeAppLifecycleState()`生命周期函数中进行保存。
  - 现在直接在棋盘状态函数 endRound 时就保存到缓存，更精确。
- 在 Board model 中添加了一个保存历史最大合成整数的栏位 bestNum。
  - 因为原游戏逻辑中，棋盘没有空白和生成图块 2 了游戏才结束，游戏结束后再根据棋盘上是否有 2048 的数值来判断是否赢得游戏
  - 所以理论上可以合成无限大的数。分数和合成的整数是两个栏位，当前分数可以根据合成过程动态显示，最大合成数除非有新高才更新。
