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
        local_music                                     ListView
                            pexels_image_page              Scaffold
                            image_page_demo                Scaffold
        online_music                                      ListView
                            readhub_page                   Scaffold
                            news_page_demo                 Scaffold
        other                                      ListView


```

- 首页即本地音乐界面：
  - 最下方是 3 个 BottomAppBar 的图标：本地、云端、其他（打开默认就是“本地”）
  - 其上是当前播放音乐的简约状态，能点击按钮切换播放/暂定，点击歌名进入播放主页面
  - 在上是“功能分类”，暂时定 4 个（后三个只是单纯显示，默认扫描出的全部，为了方便，不自定义扫描文件夹）：
    - 播放列表/歌单（可新增、删除、修改，其中的歌曲需要在全部音乐列表中添加，或者在指定播放列表详情中移除）
      - 长按播放列表可“删除”、“全选”、“复制”等功能（先只实现删除）
    - 艺术家、
    - 专辑、
    - 全部
      - 后三者进入音乐列表后，长按指定音乐操作多种功能“重命名”、“删除”、“添加到歌单”、“查看信息”等
        - “添加到歌单”则可以“新增歌单”
      - “音乐列表”页面(或者说显示组件)可以复用，只不过根据选择“播放列表”、“艺术家”等显示对应歌曲列表而已
    - 这个“功能分类”可以使用 tab 形式直接当前页面区域显示内容，也可以 card 标题再点一层进入内部显示。
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
