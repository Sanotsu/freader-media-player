# freader_music_player

A simple local music player

## 功能列表

- [ ] 本地音乐
  - [x] 音频播放详情页面(细节需优化)
  - [x] 记录上次使用时播放的音频状态 mini bar
  - [ ] 音频的查询
  - [ ] 当前 tab 中歌单/音频/歌手/专辑的排序
  - [ ] 分类 tab
    - [ ] 歌单
      - [ ] 歌单列表页面需要优化
      - [x] 点击查看指定歌单内音频列表
        - [x] 歌单内音频列表页面(细节需优化)
        - [x] 点击播放指定音频
        - [ ] 指定歌单内部的音频查询
        - [ ] 指定歌单内部的音频排序
        - [x] 长按指定音频显示的功能按钮
          - [x] 从歌单移除
          - [x] 加入其他歌单
            - [x] 可创建新歌单
          - [ ] 查看音频详情
          - [ ] 其他功能
      - [x] 长按指定歌单显示的功能按钮
        - [x] 修改歌单
        - [x] 查看歌单详情
        - [x] 删除歌单
    - [x] 全部
      - [x] 显示设备内所有音频列表(细节需优化)
        - [x] 点击播放指定音频
      - [x] 长按指定音频显示的功能按钮
        - [x] 加入指定歌单
        - [ ] 音频详情
    - [x] 歌手
      - [ ] 歌手列表页面需要优化
      - [x] 点击查看指定歌手内音频列表(长按暂时不设计功能)
        - [x] 点击播放指定音频
        - [x] 长按指定音频显示的功能按钮
          - [x] 加入指定歌单
          - [ ] 音频详情
    - [x] 专辑
- [ ] 在线音乐
- [ ] 其他预留

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

- local-music-index: 带 appbar 的 Scaffold，内部有 TabBarView 包含以下内容：
  - playlist/artis/album: futureBuilder 构建 listview
    - audio-list-detail: 带 appbar 的 Scaffold
      - music-list-future-builder: futureBuilder 构建 listview
        - music-player-detail: 单独 Scaffold 音频播放页面
          - common: 音频播放页面的 seekBar 等小组件
  - all: futureBuilder 构建 listview
    - music-list-future-builder: futureBuilder 构建 listview
      - music-player-detail: 单独 Scaffold 音频播放页面
        - common: 音频播放页面的 seekBar 等小组件

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

**on_audio_query 库的 bug**:

- 2.7.0 版本插件的 renamePlaylist()方法报错，堆栈溢出，暂时无解
- queryPlaylists() 中的音频 id 与原始音频 id 不一致，无法获取原始音频的图片等信息
- QueryArtworkWidget 组件的 artworkHeight 高度属性设置无效，实测一直是 56，原因不明
  - 如果在 ListTile 的 leading 中使用 Column 包裹 QueryArtworkWidget 则可以看出，该组件高度是固定的，无法扩展
- queryWithFilters 接口 查询 playlist 的时候有 bug，没有 numOfSongs 属性。所以转为 PlaylistModel 会报错。
  - 目前是转为 map，取得`_id`属性，再使用 queryAudiosFrom 从 playlist 中查询拥有的音频数量，再手动构建`num_of_songs`属性，然后再转为 PlaylistModel 类型。

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
- （2023-04-11 基本完成）**简单实现在“全部”中添加歌曲到歌单，在指定歌单中，长按可点击从歌单移除指定音频**
  - “全部”显示的列表是音频的列个，其他 tab 显示的时播放列表，所以长按在 appbar 中显示功能按钮不一样，且已经在 home 页面了。
  - 从歌单移除则已经进入了音频列表，长按显示的功能按钮在 audio list detail 中的 appbar 里。
  - _考虑不要同一，至少全部和其他 tab 的逻辑分开。_
  - **注意**: 添加到歌单的功能还有问题，music list builder 中删除 callback 就不行了，原因不明
- （2023-04-11 基本完成）**简单实现在“歌手”、“专辑”中添加歌曲到歌单，完成添加到歌单时新建歌单的逻辑**
  - **注意**: 添加到歌单的功能还有问题，从 A 歌单添加到 B 歌单不会生效，原因不明。
    - 大概知道原因了: **加入到歌单里的音频的 id，已经不是原始的音频 id 了**，被重新复制过(on audio query 组件内部这样做的),而新增到歌单时，因为找不到对应的 id，会报错：
      `android.database.CursorIndexOutOfBoundsException: Index 0 requested, with a size of 0`
    - 这个“歌单中的 id 不是原始 id”的特征，原库作者说是在 3.0.0-beta.0 已经改为了原始 id，且有一大堆重构和新特征，但是维护力度不如 2.x 版本，所以还是先用 2.x 版本。
      - 或者麻烦点，先取得音频名称(库也不提供此方法，只有过滤性质的，可能模糊查询关键字那种)，在去查询其原始 id，然后再使用 addtoplaylist 方法加入指定歌单。
      - 大概只能不支持歌单到歌单的添加了。
- （2023-04-12 基本完成）: **单独歌单 tab 中长按指定歌单可重命名(依赖库有 bug)、查看详情、删除的功能**
- （2023-04-12 基本完成）: **调整各个 tab 页的列表和音频列表的样式**
- （2023-04-12 基本完成）: **重构长按音频后的功能操作逻辑**，不再在音频列表页面进行数据异动，而是在按钮所在页面直接操作。
  - 就是把选中音频存入 provide 的 model 中，直接只是建立了很多要操作的标志，现在都不需要了。
- （2023-04-12 基本完成）: **单个或多个音频被选中时查看详情的弹窗内容不同**
  - 同时修改了一些歌单或音频多选时，在 appbar 显示被选中的数量
- 2023-04-12 基本完成）**关于本地音乐全局查询的设计，歌单页查歌单，专辑页查专辑等**
  - 全部页面和其他三个 tab 的不同：
    - 其他 3 个是在 index 已经查询到了结果，然后点击具体类别之后再显示 audio list 页面，在 music list build 中 build 具体的音频列表内容；
    - 而全部则是把条件传入 music list build，根据条件 build 音频列表内容。
      - 所有前 3 者点开搜索框，[结果集是空的]，输入之后显示符合条件的结果；后者点开搜索框先是[全部音频内容]，输入条件之后再过滤符合条件的
  - 如果要改成一致的，则把 index 中的查询，改到各个 tab 具体页面中去，和“全部”类似，通过传入“查询条件”区分构建的内容。
- （2023-04-17 基本完成）**重构全局歌单的查询显示在 tab 原始位置下，不构建新的结果显示页面**，还有以下问题：
  - 1 因为 条件查询的 queryWithFilters 接口返回的 playlist 和 默认的 queryPlaylists 接口返回的数据不一致，在 playlist.dart 文件中处理不能直接统一处理。
    - 而且前者因为结果中缺少 numOfSongs 属性，导致直接转为 PlaylistModel 也会失败。
    - 所以是区分两者来源，前者转为 map 之后，再通过 id 使用 queryAudiosFrom 接口查询到音频列表，补上缺少的属性，再转为 PlaylistModel。
  - 2 因为上面多次异步操作，playlist.dart 构建歌单列表组件使用了 FutureBuilder->ListView.builder ->FutureBuilder->ListTile 的嵌套，有可能因为此，导致在判断指定歌单是否被长按选中/取消、加入到被选中列表等地方，原本 contains 方法无效，都改为 where 或者 removeWhere
  - 3 一次长按然后点击变为多选或者取消，会导致 playlist.dart 构建中的打印出现 3 次，说明可能重新 build 了该组件 3 次。虽然功能算实现了。
    - 但这个重复渲染的原因可能是长按和点击回调函数中的 setstate 改变状态时修改了 LongPress 的 model，而 playlist 或其上层可能使用了 Consumer 对应的 model 导致检测到异动重新渲染了。
    - 要如何改正优化暂不确定。
- （2023-04-17 基本完成）**重构全全部歌曲、歌手、专辑的查询显示在 tab 原始位置下，不构建新的结果显示页面**
  - 歌曲、歌手、专辑的 queryWithFilters 结果可以直接转为对应的类型，这和 歌单不一样(歌单这个是库的 bug)
- （2023-04-18 基本完成）**在指定歌单、歌手、专辑中条件查询音频**
- （2023-04-19 基本完成） **歌单、歌手、专辑中的选项排序功能**
  - **[注意]**：歌单 queryPlaylists 默认有 名称、添加时间可用于升序、降序排序，但实测结果是一样的，没有排序的效果
  - 此外，插件默认的排序和中文感官上是不一致的，应该是以其他编码（至少不是拼音顺序）排序的。
  - 指定歌单、歌手、专辑内部的音频排序和 tab 为全部歌曲时逻辑一致，因为都在 audil-list 渲染的。
- （2023-04-19 基本完成） **歌单、音频长按选中后，appbar 可显示一键清除所有选中的按钮**
- （2023-04-21 基本完成） **大幅重构播放详情页面**。有空需要修改歌曲进度条的功能：当前时间、速度调节、音量调节、总时长……
  - 是否随机播放的状态，好像其持久化还有点问题
    - 2023-04-22 修改了上面 bug，因为只是获取了持久化的值，但没有应用它，只有图标变了，但实际还是预设模式。
- （2023-04-25 基本完成） **默认使用 dark 模式的主题。播放详情页加上返回按钮**。
  - 播放详情页面还是自定义的黑色主题
- （2023-04-26 基本完成） **实现歌单列表中音频显示缩略图,mini bar 中显示缩略图**。
  - on audio query 截止到 2.8.0 版本都不支持 playlist 中的 id 为原始 id，而是重新编号的 id。
  - 所以实现是根据 title 重新查询音频数据，得到原始 id 之后，再构建音频列表组件。
    - （2023-04-27 修复） _出现一个问题_: 无法按照之前的写法从歌单移除指定音频了，因为不是编号后的音频 id。所以指定歌单“显示缩略图和从歌单移除功能目前 2 选 1”
- （2023-04-26 基本完成） **新增按钮可以手动切换 flutter 预设的 dark 或 light 主题**。
- （2023-04-26 基本完成） **构建用户中心的页面布局 demo**。
- （2023-04-27 基本完成） **app 首次启动时询问是否授权运行存储操作**。

---

- **Bugs**:

  - 2023-04-11: 修复把歌单指定歌曲加入另一歌单失败的问题
  - tab 全部中选择音频，appbar 显示工具按钮，切换到其他 tab 再返回，还是存在工具按钮，但被选中的音频不再被选中。
  - 2023-04-12 on audio query2.7.0 版本插件的 renamePlaylist()方法报错，堆栈溢出，暂时无解
  - 好像 provide 中的修改属性不需要放到 setstate 中去，只要修改操作有 notify，在使用 consumer 的地方就可以识别到修改。
    - 所以那些放在 setstate 中的修改，可以放到外面去，避免产生影响
  - 后台播放在状态栏没有显示歌曲图片
  - 请求存储权限的时机不对，应该是打开显示请求权限页面，而不是退出到桌面再请求，然后再打开 app。
  - **（big）**tab 的子组件，因为有使用 consumer 侦听长按状态，而切换 tab 时有重置长按状态为初始化，导致切换 tab 后，tab 的内容会加载两次。
    - 一次是组件的初始化，另一次是重置长按状态 consumer 侦听到后的重新加载，虽然都是一样的。
    - 为什么要在 tab 切换时重置长按状态导致子组件因为 consumer 的原因重绘？因为不重置，上一个 tab 长按的效果或保留在下一个 tab 的初始 appbar 上。
    - 实际上，所有使用 consumer 的地方，都是希望检测到值变化后自动进行一些操作，里面就有大量的重新渲染组件的行为，这就可能导致很多重复加载
      - 例如改变音频长按被选中的状态，多选中一个，其实是把整个渲染的列表都重新查询，重新构建的。
    - 这个问题暂时不好解决，是设计上的失误，得重构，目前还无思路。
    - 2023-04-24 细节 bug 修复列表：
      - tabbar 与 appbar 有明显的割裂（DefaultTabController 和 Scaffold 的层级和对应的位置问题）
      - 首页的 mini bar 和音频列表 audio list 页面的 mini bar，在搜索弹出键盘时位置不固定，显示溢出的问题
      - 简单将主页的背景色设置为比较浅的深色，文本为白色，统一观感。
      - mini bar 适配 context 的主色，且改为 card widget。
      - 播放详情页的背景色与全局保持一致
  - 2023-04-27 app 首次启动时请求存储权限授权，但不知道是哪里出现的数据越界问题:
    - `I/on_audio_error(11216): android.database.CursorIndexOutOfBoundsException: Index 0 requested, with a size of 0`
    - 其实应该一直都有，即 playlist 歌单内容为空时，则会报出此信息，但似乎并不影响使用。
  - **不知道什么时候播放详情页面的标题和专辑的文字显示不起效，还不知道为什么！**
    - 2023-04-27 修复: 该 simpleMarqueeOrText 组件获取的 layout 宽度原本是 constraints.minWidth，如果没有父组件约束，该值为 0，则不显示任何东西。现在该组件的宽度为 "自行传入 > 父组件大于 50 > 约预设的 300.sp" 的优先级生效。

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

3.

```
This _InheritedProviderScope<AudioInList?> widget cannot be marked as needing to build because the framework is already in the process of building widgets. A widget can be marked as needing to be built during the build phase only if one of its ancestors is currently building. This exception is allowed because the framework builds parent widgets before children, which means a dirty descendant will always be built. Otherwise, the framework might not visit this widget during this build phase.
The widget on which setState() or markNeedsBuild() was called was: _InheritedProviderScope<AudioInList?>
```

在使用 notifyListeners()时，在重建它之前，等待构建方法完成

```
WidgetsBinding.instance.addPostFrameCallback((_) {
  notifyListeners();
});
```

[参看](https://stackoverflow.com/questions/60852896/widget-cannot-be-marked-as-needing-to-build-because-the-framework-is-already-in)第二个答案
