// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';

class Sound extends StatefulWidget {
  final Widget child;

  const Sound({super.key, required this.child});

  @override
  SoundState createState() => SoundState();

  static SoundState of(BuildContext context) {
    final state = context.findAncestorStateOfType<SoundState>();
    assert(state != null, 'can not find Sound widget');
    return state!;
  }
}

const _SOUNDS = [
  'clean.mp3',
  'drop.mp3',
  'explosion.mp3',
  'move.mp3',
  'rotate.mp3',
  'start.mp3'
];

class SoundState extends State<Sound> {
  late Soundpool _pool;

  final _soundIds = <String, int>{};

  bool mute = false;

  void _play(String name) {
    final soundId = _soundIds[name];
    if (soundId != null && !mute) {
      _pool.play(soundId);
    }
  }

  @override
  void initState() {
    super.initState();
    _pool = Soundpool.fromOptions(
      options: const SoundpoolOptions(maxStreams: 6),
    );

    for (var value in _SOUNDS) {
      scheduleMicrotask(() async {
        final data = await rootBundle.load('assets/games/tetris/audios/$value');
        _soundIds[value] = await _pool.load(data);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _pool.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  void start() {
    _play('start.mp3');
  }

  void clear() {
    _play('clean.mp3');
  }

  void fall() {
    _play('drop.mp3');
  }

  void rotate() {
    _play('rotate.mp3');
  }

  void move() {
    _play('move.mp3');
  }
}
