# freader-media-player

freader-media-player(FMP Player)，一个使用 flutter 开发的简单的本地媒体播放器，用于播放本地音频，浏览本地图片，观看本地视频。

没有 i18n，应用名称应该分别为`(FMP Player/Freader 播放器)`。

## 功能说明

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

一开始是只想做简单的音乐播放器，但后来发现开源的在线音乐资源 API 不好找，就补充播放本地媒体，虽然功能也不完善：

- 本地音乐
  - `歌单`、`全部`、`歌手`、`专辑`的模块分类，每个模块都可自主筛选、调整排序；
  - 可以后台播放，有`关闭应用`按钮在退出时关闭后台播放。
- 本地相册
  - 扫描预览本地的图片、视频，可选中两者都获取、仅图片、仅视频；
  - 文件夹中的图片可以进入详情后左右滑动切换上下一张，视频进入详情后就开始播放；
- 可切换默认的 dark、light 主题。

![screenshot_fmp](_screenshots/screenshot_fmp.jpg)

## 项目说明

```txt
├── lib
    ├── common
    │   ├── global
    │   ├── personal
    │   └── utils
    ├── layout
    │   ├── app.dart
    │   └── home.dart
    ├── main.dart
    ├── models
    ├── services
    │   ├── my_audio_handler.dart
    │   ├── my_audio_query.dart
    │   ├── my_get_storage.dart
    │   └── service_locator.dart
    └── views
        ├── local_media
        └── local_music
```

主要使用的插件库:

- shared_preferences: ^2.1.0
- on_audio_query: ^2.9.0
- just_audio: ^0.9.33
- just_audio_background: ^0.0.1-beta.10
- audio_session: ^0.1.13
- get_it: ^7.6.0
- provider: ^6.0.5
- marquee: ^2.2.3
- path_provider: ^2.0.15
- video_player: ^2.6.1
- flick_video_player: ^0.5.0
- photo_manager: ^2.6.0
- photo_view: ^0.14.0

## 很多问题

基本上也是新手写的 demo 的水平，还有很多问题：

- 使用的组件相关（后续可能替换别的库，甚至自己来）：
  1. 使用[on_audio_query: ^2.9.0](https://pub.dev/packages/on_audio_query)库来获取设备中存在的音频资料，提供很多简便的 API。
     - 从 2.7.0 版本开始使用，插件的修改歌单名称 `renamePlaylist()` 方法报错，堆栈溢出，暂时无解
     - `queryPlaylists()` 中的音频 id 与原始音频 id 不一致，无法直接获取原始音频的图片等信息
       - 目前是通过音频名称查询得到该音频原始信息，再使用其图片。
     - `QueryArtworkWidget` 组件的 artworkHeight 高度属性设置无效，实测一直是 56，原因不明
       - 如果在 ListTile 的 leading 中使用 Column 包裹 QueryArtworkWidget 则可以看出，该组件高度是固定的，无法扩展
     - `queryWithFilters()` 接口 查询 playlist 的时候有 bug，没有 `numOfSongs` 属性。所以转为 PlaylistModel 会报错。
       - 目前是转为 map，取得`_id`属性，再使用 queryAudiosFrom 从 playlist 中查询拥有的音频数量，再手动构建`num_of_songs`属性，然后再转为 PlaylistModel 类型。
  2. 使用[photo_manager: ^2.6.0](https://pub.dev/packages/photo_manager)来获取设备中的媒体资源，提供很多简便的 API。
     - 在配合[photo_view: ^0.14.0](https://pub.dev/packages/photo_view)使用时，因为`PhotoViewGallery.builder()`的`PhotoViewGalleryPageOptions()`的 `imageProvider`属性需要是`ImageProvider`类型，但 photo_manager 取得的文件资源 AssetEntity 的 file 属性是一个 `Future<File?>`。
       - 目前是点击进入图片浏览页时，初始化当前文件；切换上下页时，再获取对应文件资源进行显示。这样，如果在黑色背景中，切换会变成一闪一闪，很影响观感。
       - 当然，如果进入图片浏览页时，就加载获取到所有图片数据，在切换时会很流畅，跟自带的相册应用一样，但如果该文件夹下图片很多，这个等待时间就非常长。
     - 如果在应用中`复制`了某些图片到另一个文件夹，`复制的目标文件夹中无法显示新的图片`，但使用别的文件管理应用可以看到复制来的图片；或者`删除`了某个文件夹中的图片，`删除的源文件夹总的数量不会减少`，即 AssetPathEntity 的 assetCountAsync 属性还是删除前的，但看不到多出来的图片。
       - 当然都是刷新状态后，甚至卸载了应用重新安装，还是不对。尤其是显示文件夹中有 2 张图，但点进去只要 1 张，实际也只有 1 张这种情况很糟。
     - 因为从查询相册文件夹列表、指定文件夹媒体文件列表、指定文件信息一层一层下来，如果在图片详情中修改了图片名称，会导致其他问题。
- 能力水平相关：
  1. 本地音乐中`音频列表`长按后显示`加入歌单`、`查看信息`等按钮，但其实长按后每次点击都重新渲染了列表组件。
  2. 图省事，当前播放音频和播放列表信息是放到了 SharedPreferences 中，所以每次退出或强制关闭，可能并不会显示上次的播放歌曲。
     - 当然，这个可以换个持久化库来做应该就好了。
  3. 背景播放中状态栏没有预设的歌曲预览图片。
     - 因为图省事直接使用`just_audio_background`，没有客制化 audio_service，在点击时歌单某首歌曲时会先初始化歌单，再把整个歌单`setAudioSource`到音频源，指定被点击的歌曲索引。
     - MediaItem 的 artUri 属性需要 Uri 类型，on_audio_query 能得到 Uint8List 数据，所以构建整个歌单音源时，要把 Artwork 的数据存放到临时文件中，再赋值其 uri 给 artUri 属性。如果歌单文件列表很大，则非常耗时，所以目前没有这样中。
     - 当然，应该实现绑定音源时只处理当前那一首音频，则不会有这样的问题了。
  4. 图片预览详情页暂时功能不多，如果有异动源文件的功能(比如修改文件夹)，可能会导致一系列的问题。
  5. 视频也是直接使用第三方库的预设功能，没有自定义的修改。
     - 图片仅可以放大缩写、查看详情，视频也不能文件夹内列表循环。
  6. 有使用到`providers`库，但状态异动通知的使用并不熟练，组件的重新渲染或者重复渲染好像挺多。
- 以及其他使用 flutter 经验不足或能力不足的各种问题。

因为时间原因也有很多功能想做但还没有做：

- 涉及到音频文件的异动的功能，例如修改名称、移动、删除等。
- 图片详情中其他功能，例如重命名、删除、赋值、修改、编辑等。
- 视频详情只有播放，没有查看视频信息、列表循环，视频修改等。
- 媒体资源都不能分享、收藏等。
- 预计的在线版本也没有，比如在线音乐。
- 个人资料模块基本不可用，其实没东西可以不作为页面模块，直接改为一个 drawer。
- 还计划练手写一点 2048、俄罗斯方块的小游戏。
