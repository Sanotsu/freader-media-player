import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/global/constants.dart';
import '../../models/list_long_press.dart';
import 'widgets/music_list_builder.dart';

class LocalMusicAll extends StatefulWidget {
  const LocalMusicAll({super.key});

  @override
  State<LocalMusicAll> createState() => _LocalMusicAllState();
}

class _LocalMusicAllState extends State<LocalMusicAll> {
  @override
  Widget build(BuildContext context) {
    // 只需要监测是否有条件查询值即可(条件查询有输入变化，就及时更新符合查询条件的音频列表)
    return Consumer<ListLongPress>(
      // 如果是全部tab，指定列表类型为all；有输入搜索的条件，则在构建音频列表时带上该输入条件
      // 如果是歌单、歌手、专辑tab，还需要传额外的歌单编号、歌手编号、专辑编号的列表编号栏位
      builder: (context, llp, child) => MusicListBuilder(
        audioListType: AudioListTypes.all,
        queryInputted: llp.localMusicAppBarSearchInput,
      ),
    );
  }
}
