// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:freader_music_player/common/global/constants.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../models/is_long_press.dart';
import '../services/my_audio_query.dart';
import '../services/service_locator.dart';
import '../views/local_music/index.dart';
import '../views/online_music/online_music_index.dart';
import '../views/other_modules/other_index.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    LocalMusic(),
    OnlineMusic(),
    OtherIndex(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    /// 全层提供通知
    /// （因为歌单、全部歌曲、艺术家、专辑是tab一层，除`全部`外，需要长按列表改变app中显示的功能）
    /// 而在音频列表中长按音频，也有改变内部app bar显示的功能内容。这样`全部`这个没有中间层的也比较特殊
    ///
    return ChangeNotifierProvider(
      create: (context) => AudioInList(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: <Widget>[
            // 因为使用了consumer，在其他组件中改变了其中类的属性，这里也会识别到
            Consumer<AudioInList>(
              builder: (context, alp, child) {
                print(
                  "xxxxxxxxxxxxxxxxxxxxxxxxxxx ${alp.isLongPress} ${alp.isAddToList} ${alp.isRemoveFromList}",
                );

                /// 在“全部”tab长按，是根据音频来显示按钮。其他3个，则是类型子列表来显示
                return alp.isLongPress &&
                        alp.currentTabName == AudioListTypes.all
                    ? Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add),
                            tooltip: '加入歌单',
                            onPressed: () => _dialogBuilder(context, alp),
                          ),
                          IconButton(
                            icon: const Icon(Icons.info),
                            tooltip: '查看信息(暂不做)',
                            onPressed: () {},
                          )
                        ],
                      )
                    : Container();
              },
            ),
          ],
        ),
        body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.business), label: 'Business'),
            BottomNavigationBarItem(icon: Icon(Icons.school), label: 'School'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.amber[800],
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Widget buildLongPressButtons() {
    var alp = context.read<AudioInList>();

    print("buildLongPressButtonsXXXXXXXXXXXXXXX  ${alp.isLongPress}");

    return SizedBox(
      height: 20.sp,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            tooltip: '从列表中移除',
            onPressed: () {
              setState(() {
                // 修改移除歌单中指定音频标志为true
                alp.changeIsRemoveFromList(true);
                // 单击了功能按钮之后，立马切回长按状态为否
                alp.changeIsLongPress(false);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.info),
            tooltip: '详细信息',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This is a 详细信息'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: '删除文件',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This is a 删除文件'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: '更多功能',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This is a 更多功能'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  buildDefaultButtons() {
    return Container();
  }

  Future<void> _dialogBuilder(BuildContext ctx, AudioInList alp) {
    // 获取查询音乐组件实例
    final audioQuery = getIt<MyAudioQuery>();
    // 每次打开添加到歌单，都没有预设被选中的
    int? selectedPlaylistId = 0;

    return showDialog<void>(
      context: ctx,
      builder: (BuildContext ctext) {
        return AlertDialog(
          // 需要在AlertDialog中使用StatefulBuilder，否则内部的ListView改变了状态，是不会及时更新的
          // https://stackoverflow.com/questions/54734512/radio-button-widget-not-working-inside-alertdialog-widget-in-flutter
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return FutureBuilder<List<PlaylistModel>>(
                future: audioQuery.queryPlaylists(),
                builder: (context, item) {
                  // Display error, if any.
                  if (item.hasError) {
                    return Text(item.error.toString());
                  }
                  // Waiting content.
                  if (item.data == null) {
                    return const CircularProgressIndicator();
                  }
                  // 'Library' is empty.
                  if (item.data!.isEmpty) return const Text("Nothing found!");

                  // 得到查询的歌单列表
                  List<PlaylistModel> playlists = item.data!;

                  return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          height: 180.sp,
                          child: ListView.builder(
                            itemCount: playlists.length,
                            itemBuilder: (ctx, index) {
                              return RadioListTile(
                                title: Text(playlists[index].playlist),
                                value: playlists[index].id,
                                groupValue: selectedPlaylistId,
                                onChanged: (int? value) {
                                  print(
                                    "ddddddddddddd $selectedPlaylistId  ${playlists[index].id}",
                                  );

                                  setState(() {
                                    print(
                                        "sssssssssssssssssssssssssssss $value");
                                    selectedPlaylistId = value;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        Divider(
                          height: 10,
                          thickness: 2.sp,
                          indent: 2,
                          endIndent: 0,
                          color: Colors.grey,
                        ),
                        SizedBox(
                          height: 40.sp,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              textStyle: Theme.of(ctext).textTheme.labelLarge,
                            ),
                            child: const Text('创建新歌单（预留）'),
                            onPressed: () {},
                          ),
                        )
                      ]);
                },
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(ctext).textTheme.labelLarge,
              ),
              child: const Text('取消'),
              onPressed: () {
                setState(() {
                  // 单击了取消功能按钮之后，立马切回长按状态为否
                  alp.changeIsLongPress(false);
                });
                Navigator.of(ctext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(ctext).textTheme.labelLarge,
              ),
              child: const Text('添加'),
              onPressed: () {
                setState(() {
                  alp.changeSelectedPlaylistId(selectedPlaylistId!);
                  alp.changeIsAddToList(true);
                  // 单击了添加功能按钮之后，立马切回长按状态为否，等到添加到列表完成
                  alp.changeIsLongPress(false);
                });

                Navigator.of(ctext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
