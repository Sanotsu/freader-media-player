# freader_music_player

A simple local music player

## 结构

### 项目结构

基本和 freader 项目一致：

```
│  main.dart    入口
├─common        一些工具类，如通用方法类、网络接口类、保存全局变量的静态类等
│  ├─config
│  └─utils
├─i18n          国际化相关的类都在此目录下
├─layout        页面布局（一般都是sidebar navbar main，但工具框架好像有）
│  ├─app.dart      入门文件进来之后，在此处确认显示首页（home/login）
│  ├─home.dart       首页，包含抽屉、body、底部导航栏、appbar等（body就是根据底部导航栏选择的值切换views中首层的页面）
│  └─login.dart      假如访问页面需要登录，则根据状态显示home或login
├─models        Json文件对应的Dart Model类会在此目录下
├─routes        存放所有路由页面类
├─states        保存APP中需要跨组件共享的状态类
├─views         页面
│  ├─xxx          各种模块页面
│  │  ├─xxx     模块的子页面或相关组件
│  ……
└─widgets       APP内封装的一些Widget组件都在该目录下
```

### layout 思路

```
|----------layout---------|------views------|------widget------
app
    home                                       DefaultTabController->Scaffold
        local_music(_index)                                     ListView
                            playlist              JustAudioMusicPlayer
                            all                   Scaffold
                            artist                Scaffold
                            album                 Scaffold
        online_music                                      ListView
                            readhub_page                   Scaffold
                            news_page_demo                 Scaffold
        other                                      ListView


```

- 首页即本地音乐界面：
  - 最下方是 3 个 BottomAppBar 的图标：本地、云端、其他（打开默认就是“本地”）
  - 其上是当前播放音乐的简约状态，能点击按钮切换播放/暂定，点击歌名进入播放主页面
  - 在上是“功能分类”，暂时定 4 个（后三个只是单纯显示，默认扫描出的全部 on audio query 依赖。为了方便，不自定义扫描文件夹）：
    - 歌单（可新增、删除、修改，其中的歌曲需要在全部音乐列表中添加，或者在指定歌单详情中移除）
      - 长按歌单可“删除”、“全选”、“复制”等功能（先只实现删除）
    - 艺术家
    - 专辑
    - 全部
      - 后三者进入音乐列表后，长按指定音乐操作多种功能“重命名”、“删除”、“添加到歌单”、“查看信息”等
        - “添加到歌单”则可以“新增歌单”
      - **这 4 者统称为“播放列表(audio-list)”页面**(或者说显示组件,可以尝试复用)，只不过根据选择“歌单”、“艺术家”等显示对应歌曲列表而已
        - 注意："歌单/艺术家/专辑"有 3 层:歌单列表->指定歌单/艺术家/专辑的歌曲列表->点击播放进入播放详情，而"全部"直接:歌曲列表->点击播放进入播放详情
          - 所以前 3 者多一层，然后全部的歌曲列表详情复用
    - 这个“功能分类”可以使用 tab 形式直接当前页面区域显示内容（当前采用），也可以 card 标题再点一层进入内部显示。
  - 在上是“音乐搜索”，暂时模糊搜索名称。可考虑在搜索框右边添加“按 xx 排序”等弹窗选择的小功能
    - 这已经在 appbar 的 actions 位置了，导航栏里面了。
- “云端”、“其他”页面暂时先不考虑细节
- drawer 抽屉在右边，显示可能存在“设置”、“用户信息”、“关于”等功能

大概长这个样子：

![首页](./docs/pictures/%E9%A6%96%E9%A1%B5.png)

## 开发过程记录

### 项目结构和基本布局设计

（都是文件名，省略后缀）

- main 仅当做启动入口，运行 app
  - 在 app 中根据登录状态进入 home-page(也就是默认的“本地”) 或者 login-page(先假装会有，默认都 home-page)
  - home-page 中，拆分`drawer`、`appBar`、`bottomNavigationBar`等组件单独文件
- 底部导航栏对应的三个文件夹暂命名为 local_music、online_music、other_index
  - local_music 对应的 index，显示 4 个 tab 页面：playlist、all、artist、album
    - index 最下面是 mini 播放状态条 music_player_mini_bar，只有歌名和播放暂停按钮
      - 点击歌名进入播放界面 just_audio_music_player_detail
    - 4 个 tab 基本就是 builder 了一个 list 的样子，显示所有的歌单、艺术家之类的
      - 点击“歌单”，则显示该歌单下歌曲列表 playlist_detail，然后是对歌曲的相关操作
- 查询本地音乐的组件 on audio query 和音频播放组件 just audio 需要全局单例，所有抽取到`/services`文件夹
  - 并使用`get_it`库在 main 中延迟注册全局单例

---

依赖（like 数量为 2023-04-03 统计）：

- on_audio_query: ^2.7.0 获取本地音乐信息
- 几个音乐播放器插件

  ```
  just_audio: ^0.9.32           2651 likes  【实际使用】
    just_audio_background: ^0.0.1-beta.9    搭配上者实现背景播放（在AndroidManifest.xml配置蛮多的4处）
  // assets_audio_player: ^3.0.6   942 likes
  // audioplayers: ^3.0.1          2076 likes
  ```

- get_it: ^7.2.0 全局单例的工具箱

---

其他说明：

- 在进入“本地音乐”主页时，不管是切换在“歌单”、“全部”、“专辑”等哪一个 tab，下方都显示 mini 当前播放状态条
  - 该当前播放的音乐、以及播放列表的名称，可以存到数据库或者缓存，每次进入“本地音乐”时重新获取
  - 这也意味着，player 要在最上层就初始化，且全局单一实例。
- 同理，查询音频的 onAudioQuery 也应该全局单一。
  - 以上两者，抽出来单独的 service，并使用 get_it 单例化

注意，“全部”、“专辑”、“艺术家”、“歌单”等，使用 on audio query 创建和查询即可，**统一称为“播放列表”**，但在构建播放列表时，
使用的音频文件则不是他们的各自格式，需要在对应。

### 完成进度

- （2023-04-04 基本完成）“全部歌曲”页面、并显示 mini 状态 bar、播放页面

  - 注意，当前播放列表和音频没有传入 db，重新打开页面无法显示上次内容。

- （2023-04-06 基本完成）**缓存播放列表和进度**

  - 使用最简单的 SharedPreferences，简单的 key value 存放列表的 id 和对应音频的 id，再多一个类型表示存入的列表是“歌单”、“全部”、“艺术家”、“专辑”
    - 有想着把用到该依赖的方法集中起来，放到 my shared preferences，但不知道是好是坏
  - 什么时候修改？
    - **播放歌曲有变化的时候，目前先统一在进入播放详情页面和歌曲播放完跳到下一首时**，
      - 注意：页面停留在 player detail 时音频切换，minibar 的音频索引会跟着变，但页面停留在 mini bar 时，palyer detail 是不会跟着变的（因为还没到该组件内，进入之后就触发了）。
    - 其他比如返回/切换到其他页面时、app 退出前等时机逐步完善。
  - 什么时候读？
    - 在 run app 时，会使用 get it 注册 audio handler 的实例，在其构造函数处读取
    - 注意初始化(app 首次运行等)时，是没有值的
  - 保存的内容：
    - 播放列表类型 `{currentAudioListType: all | playlist | artist | album}`
      - **保存时机**: 这个类型，在点击进入 tab 时，就要保存
    - 播放列表编号 {currentPlaylistId: xxx } => 改为 `{currentAudioListId: xxx }`
      - **保存时机**: 点击“歌单”进入播放详情前保存
    - 当前音频在列表中索引 `{currentAudioIndex: xxx }`
      - **保存时机**: mini bar 或 player detail 中索引变化时保存
      - _注意：这是该音频在各种播放列表中的索引，不是音频本身的 id_。
  - 注意: “全部”、“艺术家”、“专辑”,使用工具类方法 querySongs()、queryAlbums()、queryArtists()直接查，不需要存播放列表编号。
    - 而歌单需要指定编号，再在 queryPlaylists()获取到指定的列表编号，在通过音频索引进行播放列表的处理。
  - **【2023-04-07 补充】**
    - 歌单、艺术家、专辑，都是想要查询出他们的列表，然后点击进入指定 item，显示该 item 中的歌曲列表，而全部直接点进去就是歌曲列表。
    - 所以实际上不是歌单和其他几个不同，而是“全部”和其他几个不同。所以上面的规则要改一下。currentPlaylistId=> currentAudioListId
    - 【特别注意】: queryAlbums()、queryArtists()查到列表等后再使用 queryAudiosFrom()得到的音频的 id 和 querySongs()中的 id 不一样，所以用前者的 id 来构建的自定义图片 QueryArtworkWidget 也不会显示

- （2023-04-06 基本完成）**初始化播放状态**

  - 在 app 启动的时候，就需要查询到持久化的播放列表和音频，绑定音源，这样在 mini bar 中才能获取到音频流信息，才能正常显示歌名和播放/暂停按钮切换。
  - 这部分操作在 my audio handle 的构造函数处执行，那就在 service 注册时能完成。
  - 当然，手动切换 tab、播放列表然后点击音频，会更新持久化的数据，也会更新正在播放的列表和音频。

- （2023-04-07 基本完成）**歌单、歌手、专辑的 tab 进入列表和进入指定列表后展示其中音频列表的功能**

  - tab 主页要查询对应播放列表的数据，点击之后进入指定播放列表显示音频列表数据，再点击进入播放页面。

- 有空需要修改歌曲进度条的功能：当前时间、速度调节、音量调节、总时长……

- 歌单的功能

--- 出现的错误

1.

```sh
 Audio sink error
E/MediaCodecAudioRenderer(32055):   com.google.android.exoplayer2.audio.AudioSink$UnexpectedDiscontinuityException: Unexpected audio track timestamp discontinuity: expected 1000753599141, got 1000753214693
```

可能是解析的音频时间戳有问题，应该是组件内部的依赖库爆出来的，不过这和 调试时一直断开连接有没有关系还不清楚

2. 询问存取等权限的时机不对

调试时首次安装会中断，然后才显示获取权限的请求，然后再次连接才正常。这步获取权限的操作，应该在进入页面后询问，然后再判断，而不是直接退出才询问。
