// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

import '../../common/global/constants.dart';
import 'widgets/music_list_future_builder.dart';

class LocalMusicAll extends StatefulWidget {
  const LocalMusicAll({super.key});

  @override
  State<LocalMusicAll> createState() => _LocalMusicAllState();
}

class _LocalMusicAllState extends State<LocalMusicAll> {
  @override
  Widget build(BuildContext context) {
    return const MusicListFutureBuilder(audioListType: AudioListTypes.all);
  }
}
