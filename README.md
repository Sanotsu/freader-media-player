# freader-media-player

freader-media-player(FMP Player)，一个使用 flutter 开发的简单的本地媒体播放器，用于播放本地音频，浏览本地图片，观看本地视频。

额外添加了“2048”和“俄罗斯方块”小游戏，做到“视听娱乐”不耽误。

## 主要功能

- 本地音乐
  - 拥有`全部`、`歌单`、`歌手`、`专辑`的模块分类，每个模块都可自主关键字查询、调整排序；
  - 可以后台播放，状态栏有显示歌曲名称。
- 全部资源
  - 默认扫描设备中的所有音频、视频、图片等媒体文件所在路径，可分类筛选和资源文件关键字模糊查询；
    - 文件夹可以切换网格显示或列表显示。
  - 点击某一个文件夹后可显示对应筛选结果的媒体资源列表，也可切换网格或列表显示；
  - 再点击指定文件夹中指定资源之后，可以进行预览或者播放：
    - 如果点击的是图片文件，可左右滑动查看该文件夹下所有图片，并提供双指缩放等功能；
    - 如果点击的是音频文件，默认该文件夹下所有音频文件都加入当前播放列表，和“本地音乐”模块共用播放；
      - 区别在于：“本地音乐”播放的音乐会在退出 app 后保留上次播放的列表和音乐，“全部资源”模块不会。
    - 如果点击的是视频文件，默认该文件夹下所有视频文件都加入当前播放列表，视频播放器会自动连播。
      - 此外，视频播放器有上一个、暂停、下一个、全屏、关闭，上下滑动屏幕左侧调节应用亮度、上下滑动屏幕右侧调节系统音量、左上角显示视频名称，等功能。
      - 播放器默认根据视频是横屏或竖屏进行播放。
- 休闲游戏
  - 提供“2048”和“俄罗斯方块”小游戏，会本地持久化缓存最高得分。
    - 2048 游戏在退出后也会保留当前状态，重新打开如果没有结束还可以继续。

**由于权限管控越发严格，本地资源均不再提供任何异动(例如重命名、复制、删除等)功能**

开发环境：

- 在 Windows7 主机下使用 VirtualBox7.0 安装的 Ubuntu22.04 虚拟机，配合 VS Code1.85.2 进行开发；
- flutter 版本为 3.16.7,java 版本为 Temurin-11.0.18+10

仅在下面设备进行过实机测试，其他平台完全没处理：

- Nubia Z50 Ultra (Android 13 , 分辨率 `2480 * 1116`，游戏页面显示不算好看)
- xiaomi 6 (Android 9 , 分辨率 `1920 * 1080` )

粗略截图如下：

![screenshot_fmp](_screenshots/screenshot_fmp.jpg)

## 更新说明

### 2024-01-30 主要更新

- feat:添加了俄罗斯方块小游戏
  - 更多参看对应模块的[readme](lib/views/game_center/tetris/readme.md).

### 2024-01-29 主要更新

- feat:添加了 2048 小游戏
  - 更多参看对应模块的[readme](lib/views/game_center/flutter_2048/readme.md).
  - 添加了休闲游戏模块后，原本的“本地图片”和“本地视频”模块就初始默认隐藏，同样长按退出弹窗正文可切换.

### 2024-01-26 主要更新

- feat:
  - 将媒体资源模块拆分为“本地视频”和“本地图片”，可分文件夹预览所有的视频或图片资源。
  - 添加了媒体资源整合管理的“全部资源”模块，可条件查询、分类型展示。图片、视频、音频点击后调用各自播放器播放或预览。
  - 添加了视频播放时左边上下滑动屏幕调整应用内亮度、右边上下滑动屏幕调整系统音量的功能。可原分辨率和全屏播放视频。
- deprecated:
  - 因为实测 `photo_namager` 中`PhotoManager.getAssetPathList()`条件查询时，使用 `AdvancedCustomFilter/ CustomFilter` 的 filter 和 type 中指定`RequestType`不能同时生效(始终是全部类型的资源)，所以“本地视频”和“本地图片”默认显示所有，不可筛选。
  - 因为对文件操作的安全性要求越来越严格，不再继续添加对媒体文件的异动操作(比如重命名、复制、删除等)
- fix:修复了一些小 bug。
- perf:清除大量无用的测试、打印等代码，清理一些原本预留的功能但后续不做的模块。
- bonus:添加长按退出弹窗的正文，可切换底部导航栏显示的数量(可隐藏“本地图片”和“本地视频”模块，因为功能基本和“全部资源重复”)。
- warning:
  - 实测，使用 Windows7 系统自带的演示范例视频`Wildlife.wmv`会有很多问题：
    - 这个`photo_manager`库基本无法正常解析(可以判断出是个视频，但无法生成缩略图，无法识别出视频长度等等内容，还会输出一堆报错)；
    - 因此直接`AssetEntity`获取的`file`也就无法使用`video_player`进行正常播放了。
  - 没有测试过视频分辨率大于设备分辨率的视频播放。
  - 在 Nubia Z50 Ultra (分辨率 `2480 * 1116`)、xiaomi6(分辨率 `1920 * 1080`)下进行实机测试，app 正常使用。
    - 但是如果是`flutter run -v`运行本项目，前者在 Android 13 时正常，升级到 Android 14 后，运行项目会卡住在 `Waiting for VM Service port to be available...`，目前还没有搜索到类似出现的原因。
  - “本地音乐”模块在退出后重新打开 app 保留上次播放的列表和音乐时，第一次或者第二次时不对，多几次后面是正常的，原因不明，不是很影响使用，后续有空再继续查看。

### 2024-01-12 主要更新

- 添加了后台播放时通知栏可显示音频缩略图；
- 修正了记录上次播放歌单和歌曲功能未生效的问题；
- 简单重构了本地音乐模块，清除大量无用和无意义的输出、预留功能等代码；
- 升级 flutter 环境为 3.16.7，相关组件库依赖也升级为可用的最新版本；
- 在 Nubia Z50 Ultra 下进行实机测试(Android 13 , 分辨率 `2480 * 1116` )。

---

是之前的练手项目[freader](https://github.com/Sanotsu/freader)的衍生。

## 项目说明

主要项目结构：

```txt
├── lib
    ├── common
    ├── layout
    ├── models
    ├── services
    ├── views
    └── main.dart
```

主要使用的插件库:

- on_audio_query: ^2.9.0
- just_audio: ^0.9.36
- just_audio_background: ^0.0.1-beta.11
- audio_session: ^0.1.18
- get_it: ^7.6.6
- provider: ^6.1.1
- marquee: ^2.2.3
- permission_handler: ^11.1.0
- path_provider: ^2.1.2
- video_player: ^2.8.2
- flick_video_player: ^0.7.0
- photo_manager: ^3.0.0-dev.5
- photo_view: ^0.14.0
- get_storage: ^2.1.1
- screen_brightness: ^0.2.2+1
- flutter_volume_controller: ^1.3.1
- flutter_riverpod: ^2.4.9
- flutter_swipe_detector: ^2.0.0
- soundpool: ^2.4.1
- ……

## 很多问题

- 使用的组件相关
  1. on_audio_query: ^2.9.0
     - 从 2.7.0 版本开始使用，插件的修改歌单名称 `renamePlaylist()` 方法报错，堆栈溢出，暂时无解
     - `queryPlaylists()` 中的音频 id 与原始音频 id 不一致，无法直接获取原始音频的图片等信息
       - 目前是通过音频名称查询得到该音频原始信息，再使用其图片。
     - `queryWithFilters()` 接口 查询 playlist 的时候有 bug，没有 `numOfSongs` 属性。所以转为 PlaylistModel 会报错。
       - 目前是转为 map，取得`_id`属性，再使用 queryAudiosFrom 从 playlist 中查询拥有的音频数量，再手动构建`num_of_songs`属性，然后再转为 PlaylistModel 类型。
  2. photo_manager: ^3.0.0-dev.5
     - 在配合[photo_view](https://pub.dev/packages/photo_view)使用时，`PhotoViewGallery.builder()`的`PhotoViewGalleryPageOptions()`的 `imageProvider`属性需要是`ImageProvider`类型，但 photo_manager 取得的文件资源 AssetEntity 的 file 属性是一个 `Future<File?>`。
     - 在使用`PhotoManager.getAssetPathList()`条件查询时，如果`filterOption`参数直接使用它的高级查询 AdvancedCustomFilter/CustomFilter ，那么同时设定`type`参数不会生效。
  3. photo_manager 和 flick_video_player/video_player
     - 如果视频是 Windows7 系统自动的那个范例视频`野生生物.wmv`(Wildlife.wmv)，不仅无法生成缩略图，也无法播放。
       - photo_manager 能识别出来是个视频，但是无法解析任何相关信息
       - video_player 无法识别，所以不能播放。
       - 但是，这两个插件会报一大堆错误，然后你无法处理
  4. 我是最近才知道 flutter_riverpod，所以和 provider 同时存在了两个状态管理组件，推荐统一为前者，但先就这样。
- 能力水平相关：
  1. 本地音乐中`音频列表`长按后显示`加入歌单`、`查看信息`等按钮，但其实长按后每次点击都重新渲染了列表组件。
  2. 理论上“本地音乐”在每一首歌播放前都会记录当前的歌单和音乐，但是首次或者前几次使用此 app 时，无法正确记录该值。多几次就正常了。
     - 因为不是很影响使用，虽然不明白为什么，也没有去处理。
  3. 在手机升级到 Android14 后，`flutter run -v`启动卡在 Waiting for VM Service port to be available...，就无法热加载或其他操作，原因不明。
- 以及其他使用 flutter 经验不足或能力不足的各种问题。
