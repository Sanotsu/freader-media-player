// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:freader_music_player/common/global/constants.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../../common/utils/global_styles.dart';
import '../../common/utils/tools.dart';
import '../../models/audio_long_press.dart';

import '../../models/list_long_press.dart';
import '../../models/sort_option_selected.dart';
import '../../services/my_audio_query.dart';
import '../../services/service_locator.dart';
import 'album.dart';
import 'all.dart';
import 'artist.dart';
import 'playlist.dart';
import 'widgets/build_add_to_playlist_dialog.dart';
import 'widgets/build_audio_info_dialog.dart';
import 'widgets/build_remove_playlist_or_audio_dialog.dart';
import 'widgets/build_search_text_field.dart';
import 'widgets/build_sort_options_dialog.dart';
import 'widgets/common_small_widgets.dart';
import 'widgets/music_player_mini_bar.dart';

/// 正常来讲，应该把AudioPlayer处理成全局单例的，例如使用get_it，palyer的所有操作封装为一个service class，然后全局使用。
/// 这里简单测试，就在最外层初始化，然后传递给子组件（虽然麻烦，但暂时不需要其他依赖）

/// 我看别人的示例都是 MaterialApp -> DefaultTabController -> Scaffold>(appBar[TabBar],body[TabBarView]) 嵌套
/// 而我之前是 Scaffold-> DefaultTabController-> Builder -> Center -> Column (children[TabBar,TabBarView])
///     导致tab和appbar有明显的区分，没有融合

class LocalMusic extends StatefulWidget {
  const LocalMusic({super.key});

  @override
  State<LocalMusic> createState() => _LocalMusicState();
}

class _LocalMusicState extends State<LocalMusic>
    with SingleTickerProviderStateMixin {
  // 是否点击了查询按钮
  bool _iSClickSearch = false;

  // 自定义的tab控制器，主要用来监听tab切换，以便provide的模型可以记录当前的tab是哪一个
  // late TabController _tabController;

  // 是否已经给tab Controller添加了监听器，避免重复监听
  late bool isAddListenerToTabController;

  // 当前tab索引，默认为0
  late int currentTabIndex = 0;

  @override
  void initState() {
    super.initState();

    isAddListenerToTabController = false;

    // 在此处
    // _tabController = TabController(vsync: this, length: 4)
    //   ..addListener(() {
    //     if (_tabController.index.toDouble() ==
    //         _tabController.animation?.value) {
    //       switch (_tabController.index) {
    //         case 0:
    //           print("坚果");
    //           break;
    //         case 1:
    //           print("前端");
    //           break;
    //       }
    //     }
    //   });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioLongPress()),
        ChangeNotifierProvider(create: (_) => ListLongPress()),
        ChangeNotifierProvider(create: (_) => AudioOptionSelected()),
      ],
      child: MaterialApp(
        theme: ThemeData(
          // 主色，子组件取context的主色就会是这个颜色(例如mini bar中)
          primaryColor: dartThemeMaterialColor2,
          // 状态栏的颜色
          primarySwatch: dartThemeMaterialColor3,
          // 深色或者浅色主题
          brightness: Brightness.light,
          // scaffold的背景色
          scaffoldBackgroundColor: dartThemeMaterialColor3,
          // 文字主题（一些文字的颜色）
          textTheme: Theme.of(context).textTheme.apply(
                bodyColor: Colors.white,
                displayColor: Colors.white,
              ),
        ),
        home: DefaultTabController(
          length: 4,
          child: Scaffold(
            // 避免搜索时弹出键盘，让底部的minibar位置移动到tab顶部导致溢出的问题
            resizeToAvoidBottomInset: false,
            appBar: _buildAppBar(),
            body: _buildBody(),
          ),
        ),
      ),
    );
  }

  /// 构建标题工具栏
  _buildAppBar() {
    return AppBar(
      title: Consumer2<AudioLongPress, ListLongPress>(
        builder: (context, alp, llp, child) {
          /// 如果不是搜索状态显示标题；如果是，显示搜索框
          if (!_iSClickSearch) {
            // 选中的音频数量
            var audioNum = alp.selectedAudioList.length;
            // 选中的歌单数量
            var listNum = llp.selectedPlaylistList.length;

            if (audioNum > 0) {
              return Text("选中$audioNum首", style: TextStyle(fontSize: 16.sp));
            } else if (listNum > 0) {
              return Text("选中$listNum个", style: TextStyle(fontSize: 16.sp));
            } else {
              return const Text("本地音乐");
            }
          } else {
            return buildSearchTextField(llp);
          }
        },
      ),
      actions: <Widget>[
        /// 在“全部”tab长按，是根据音频来显示按钮。其他3个，则是类型子列表来显示
        /// 如果没有长按音频也没有长按列表，则显示默认工具按钮
        _buildDefaultButtons(),
        _buildLongPressButtons(),
      ],
      bottom: TabBar(
        // controller: _tabController,
        // 指示器的样式(标签下的下划线)
        indicator: UnderlineTabIndicator(
          // 下划线的粗度和颜色
          borderSide: BorderSide(
            width: 3.0.sp,
            color: Colors.white,
          ),
          // 下划线的四边的间距horizontal橫向
          // insets: EdgeInsets.symmetric(horizontal: 2.0.sp),
        ),
        indicatorWeight: 0,
        // 下划线的尺寸(这个label表示下划线执行器的宽度与标签文本宽度一致。默认是整个tab的宽度)
        indicatorSize: TabBarIndicatorSize.label,
        tabs: [
          Tab(child: Text("歌单", style: TextStyle(fontSize: sizeHeadline2))),
          Tab(child: Text("全部", style: TextStyle(fontSize: sizeHeadline2))),
          Tab(child: Text("歌手", style: TextStyle(fontSize: sizeHeadline2))),
          Tab(child: Text("专辑", style: TextStyle(fontSize: sizeHeadline2))),
        ],
      ),
    );
  }

  /// 构建主体内容（是个 TabBarView）
  _buildBody() {
    return Builder(builder: (BuildContext context) {
      final TabController tabController = DefaultTabController.of(context);

      print(
        "主页index当前tab的索引 ${tabController.index} $isAddListenerToTabController",
      );

      if (!isAddListenerToTabController) {
        tabController.addListener(() {
          if (!tabController.indexIsChanging) {
            // 切换tab后更新当前tab索引
            // (不在这里重置状态，tab切换后，如果之前有被多选中的歌单或音频，状态栏功能按钮还是之前的而不是默认的)
            setState(() {
              currentTabIndex = tabController.index;
            });
            // 不是tab切换后的tab为歌单列表，重置音频长按状态；如果不是，则重置歌单长按状态

            AudioLongPress alp = context.read<AudioLongPress>();
            ListLongPress llp = context.read<ListLongPress>();

            switch (tabController.index) {
              case 0:
                alp.resetAudioLongPress();
                print("主页index中tab为0 时执行了重置");
                break;
              case 1:
                llp.resetListLongPress();
                // llp.switchTabReset();
                print("主页index中tab为1 时执行了重置");
                break;
              case 2:
                // 目前歌手和专辑tab都不能长按，所以歌单或全部歌曲中有选中，切换到歌手或专辑，都重置
                llp.resetListLongPress();
                alp.resetAudioLongPress();
                print("主页index中tab为2 时执行了重置");

                break;
              case 3:
                llp.resetListLongPress();
                alp.resetAudioLongPress();
                print("主页index中tab为3 时执行了重置");
                break;
            }
          }
        });
        // 添加了侦听器，设为 true
        isAddListenerToTabController = true;
      }

      return Center(
        child: Column(
          children: <Widget>[
            const Expanded(
              child: TabBarView(
                // controller: _tabController,
                children: <Widget>[
                  LocalMusicPlaylist(),
                  LocalMusicAll(),
                  LocalMusicArtist(),
                  LocalMusicAlbum(),
                ],
              ),
            ),
            SizedBox(
              height: 60.sp,
              width: 1.sw,
              child: const MusicPlayerMiniBar(),
            ),
          ],
        ),
      );
    });
  }

  // 显示修改歌单名称弹窗
  _buildRenamePlaylistDialog(BuildContext context, ListLongPress llp) async {
    // 获取查询音乐组件实例
    final audioQuery = getIt<MyAudioQuery>();

    print("点击了修改歌单名称");
    var playInput = llp.selectedPlaylistList[0].playlist;
    return await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('创建新歌单'),
            content: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
              return TextFormField(
                autofocus: false,
                initialValue: playInput,
                decoration: const InputDecoration(hintText: '输入新歌单名'),
                onChanged: (value) {
                  setState(() {
                    playInput = value;
                  });
                },
              );
            }),
            actions: <Widget>[
              StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                return MaterialButton(
                  color: Colors.red,
                  textColor: Colors.white,
                  child: const Text('取消'),
                  onPressed: () {
                    setState(() {
                      // 单击了取消功能按钮之后，立马切回长按状态为否，清空被选中的歌单列表,也取消弹窗
                      llp.resetListLongPress();
                      Navigator.pop(context);
                    });
                  },
                );
              }),
              StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                return MaterialButton(
                  color: Colors.green,
                  textColor: Colors.white,
                  child: const Text('确认'),
                  onPressed: () async {
                    // 新建歌单的逻辑，同时加入歌单的逻辑。

                    print(
                      """
                      rename 输入新建的歌单名称 ${llp.selectedPlaylistList[0].id}, $playInput
                      ${await audioQuery.queryDeviceInfo()}
                      """,
                    );

                    ///??? 这里插件自身函数就有bug，需要等待其修复，所以修改歌单暂时无效
                    // await audioQuery.renamePlaylist(
                    //   llp.selectedPlaylistList[0].id,
                    //   playInput,
                    // );

                    setState(() {
                      llp.changeIsPlaylistLongPress(LongPressStats.NO);
                      Navigator.pop(context);
                    });
                  },
                );
              }),
            ],
          );
        });
  }

  // 显示歌单信息的弹窗
  _buildPlaylistInfoDialog(BuildContext context, ListLongPress llp) {
    PlaylistModel list = llp.selectedPlaylistList[0];

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        print(list.dateModified);
        return AlertDialog(
          title: const Text('歌单属性'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true, // 自动根据内容的高度显示list的高度
              children: <Widget>[
                buildRowText("歌单名称", list.playlist),
                buildRowText("歌曲数量", list.numOfSongs.toString()),
                buildRowText("歌单编号", list.id.toString()),
                buildRowText(
                    "创建时间",
                    list.dateAdded != null
                        ? formatTimestampToString(list.dateAdded!)
                        : ""),
                buildRowText(
                    "修改时间",
                    list.dateModified != null
                        ? formatTimestampToString(list.dateModified!)
                        : ""),
                buildRowText("歌单位置", list.data.toString()),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('确认'),
              onPressed: () {
                setState(() {
                  // 单击了取消功能按钮之后，立马切回长按状态为否，清空被选中的歌单列表,也取消弹窗
                  llp.resetListLongPress();
                  Navigator.pop(context);
                });
              },
            ),
          ],
        );
      },
    );
  }

  /// 在index主页中，歌单tab和全部tab中的歌单或音频是可以长按选中的，歌手和专辑暂不支持长按操作
  ///   如果是歌单被选中，index的appbar显示修改、详情、删除(多选时)按钮，
  ///   如果是歌曲被选中，显示 加入歌单、详情按钮
  /// 而默认是 搜索和排序按钮
  ///   搜索在各自tab搜索各自内容，例如歌单tab搜索满足条件的歌单，专辑tab搜索满足条件的专辑
  _buildLongPressButtons() {
    return Row(
      children: [
        // 因为使用了consumer，在其他组件中改变了其中类的属性，这里也会识别到
        // 如果是“全部”tab中音频被长按选中
        Consumer<AudioLongPress>(
          builder: (context, alp, child) {
            print(
              "xxxxxxxxxxxxxxxxxxxxxxxxxxx加入歌单 ${alp.isAudioLongPress} ",
            );
            return alp.isAudioLongPress == LongPressStats.YES
                ? Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        tooltip: '加入歌单',
                        onPressed: () => buildAddToPlaylistDialog(
                            context, alp, AudioListTypes.all),
                      ),
                      IconButton(
                        icon: const Icon(Icons.info),
                        tooltip: '详细信息',
                        onPressed: () => buildAudioInfoDialog(context, alp),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel),
                        tooltip: '取消选中',
                        onPressed: () => alp.resetAudioLongPress(),
                      )
                    ],
                  )
                : Container();
          },
        ),

        Consumer<ListLongPress>(
          builder: (context, llp, child) {
            if (llp.isPlaylistLongPress == LongPressStats.YES &&
                llp.selectedPlaylistList.length == 1) {
              // 如果是“歌单”tab中指定单个歌单被长按选中，可显示修改、查看详情、删除和取消选中
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: '修改歌单名称',
                    onPressed: () => _buildRenamePlaylistDialog(context, llp),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info),
                    tooltip: '查看歌单详情',
                    onPressed: () => _buildPlaylistInfoDialog(context, llp),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: '删除选中歌单',
                    onPressed: () =>
                        buildRemovePlaylistOrAudioDialog(context, llp),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel),
                    tooltip: '取消选中歌单',
                    onPressed: () {
                      // 单击了取消按钮图标，取消所有选中歌单
                      llp.resetListLongPress();
                    },
                  )
                ],
              );
            } else if (llp.isPlaylistLongPress == LongPressStats.YES &&
                llp.selectedPlaylistList.length > 1) {
              // 如果是“歌单”tab中指定多个歌单被长按选中，可显示删除和取消选中
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: '删除选中歌单',
                    onPressed: () =>
                        buildRemovePlaylistOrAudioDialog(context, llp),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel),
                    tooltip: '取消选中歌单',
                    onPressed: () {
                      // 单击了取消按钮图标，取消所有选中歌单
                      llp.resetListLongPress();
                    },
                  )
                ],
              );
            } else {
              // 没有长按，则占位
              return Container();
            }
          },
        ),
      ],
    );
  }

  // 默认的工具按钮（查询和排序）
  _buildDefaultButtons() {
    return Consumer3<AudioLongPress, ListLongPress, AudioOptionSelected>(
      builder: (context, alp, llp, aos, child) {
        return alp.isAudioLongPress != LongPressStats.YES &&
                llp.isPlaylistLongPress != LongPressStats.YES
            ? SizedBox(
                height: 20.sp,
                child: Row(
                  // 如果没点击搜索按钮，正常显示预设的搜索、排序按钮；如果点击了搜索按钮，展示了搜索框，这里按钮也变成清除。
                  children: !_iSClickSearch
                      ? [
                          IconButton(
                            icon: const Icon(Icons.search),
                            tooltip: '音频查询',
                            onPressed: () {
                              setState(() {
                                _iSClickSearch = true;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.sort),
                            tooltip: '排序',
                            onPressed: () {
                              buildSortOptionsDialog(
                                context,
                                aos,
                                currentTabIndex,
                              );
                            },
                          ),
                        ]
                      : [
                          IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _iSClickSearch = false;
                                  llp.changeLocalMusicAppBarSearchInput(null);
                                });
                              })
                        ],
                ),
              )
            : Container();
      },
    );
  }
}
