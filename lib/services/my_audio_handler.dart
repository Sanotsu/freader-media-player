// ignore_for_file: avoid_print

import 'package:freader_music_player/services/my_shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:rxdart/rxdart.dart';

import '../common/global/constants.dart';
import 'my_audio_query.dart';
import 'service_locator.dart';

/// 单例的audio player，以及他的一些方法

class MyAudioHandler {
  // 播放器
  final _player = AudioPlayer();
  // 当前播放列表
  var _currentPlaylist = ConcatenatingAudioSource(children: []);
  // 当前播放列表中播放的第几首歌
  var _initIndex = 0;

  // 获取查询音乐组件实例
  final _audioQuery = getIt<MyAudioQuery>();

  // 统一简单存储操作的工具类实例
  final _simpleShared = getIt<MySharedPreferences>();

  // 构造函数
  MyAudioHandler() {
    _loadInitCurrentPlaylist();
    _notifyAudioHandlerAboutPlaybackEvents();
  }

  // 获取当前播放列表和当前音乐索引（正常来讲，这个会存入db）
  // 其他情况改变了当前列表，则额外处理
  Future<void> _getInitPlaylistAndIndex() async {
    // todo
    // // 获取权限
    // await _audioQuery.checkAndRequestPermissions(retry: true);

    print("这是在_getInitPlaylistAndIndex");
    // // 获取当前的播放列表数据

    // 这个list有依次3个值：当前列表类型、当前音频在列表中的索引、当前播放列表编号
    var tempList = await _simpleShared.getCurrentAudioInfo();

    print("$tempList,,,,,,${tempList[0]},,,,${AudioListTypes.all}");

    List<SongModel> songs;
    switch (tempList[0]) {
      case AudioListTypes.all:
        songs = await _audioQuery.querySongs();
        break;
      case AudioListTypes.playlist:
        // 当前歌单编号
        songs = await _audioQuery.queryAudiosFrom(
            AudiosFromType.PLAYLIST, tempList[2]);
        break;
      case AudioListTypes.artist:
        // 当前歌手编号
        songs = await _audioQuery.queryAudiosFrom(
            AudiosFromType.ARTIST_ID, tempList[2]);
        break;
      case AudioListTypes.album:
        // 当前专辑编号
        songs = await _audioQuery.queryAudiosFrom(
            AudiosFromType.ALBUM_ID, tempList[2]);
        break;
      default:
        songs = await _audioQuery.querySongs();
    }
    await buildPlaylist(songs, songs[tempList[1]]);
  }

  // 设置初始化播放列表源（这在app启动时就要加载完成）
  Future<void> _loadInitCurrentPlaylist() async {
    try {
      // 等待获取到持久化中的播放列表和索引之后，再绑定音源
      await _getInitPlaylistAndIndex();
      await _player.setAudioSource(_currentPlaylist, initialIndex: _initIndex);

      print(
          "_player.sequenceStateStream.length${_player.sequenceStateStream.length}");
    } catch (e) {
      print("_loadInitCurrentPlaylist Error: $e");
    }
  }

  /// ------------ 上面是内部私有方法

  // 在播放过程中侦听错误。
  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
      print('A stream error occurred: $e');
    });
  }

  // 构建当前播放列表和音频（一般是在 播放列表、专辑、艺术家、全部 等主页点击指定音乐时，需要替换到现有的播放列表和音频）
  // 注意：音频格式为 on audio query 组件中得到的，且设置完之后要重新加载播放列表
  Future<void> buildPlaylist(
      List<SongModel> list, SongModel currentSong) async {
    List<AudioSource> tempChildren = [];

    // 1 遍历歌单歌曲地址，获取元数据信息，构建列表组件
    for (var i = 0; i < list.length; i++) {
      var ele = list[i];

      // 判断当前音频在不在列表中（理论上必须存在，需要在其他地方限制好），获取该音频的在列表中的位置，设为播放列表初始播放的位置
      var tempIndex = list.indexWhere((e) => e.id == currentSong.id);
      _initIndex = tempIndex > 0 ? tempIndex : 0; // 找不到就从列表第一个开始

      /// 目前这个cusExtras保存的东西就很多了
      ///     1 音频新增到db时的文件元数据，"metadata"
      ///     2 本条 LocalPlaylistHasAudio 的row数据， "playlistHasAudio"
      ///  这里不先转换json而是直接赋值的的话，会导致因为引用类型的原因，在addAll()之后修改了原本的extrax的结构，会出问题

      // 其他的音频，顺序加入列表组件
      tempChildren.add(
        AudioSource.uri(
          Uri.parse(ele.data),
          tag: MediaItem(
            id: ele.id.toString(),
            title: ele.title,
            artist: ele.artist,
            album: ele.album,
            // extras: cusExtras,
          ),
        ),
      );
    }

    // 构建新的播放列表就直接替换，在原列表上新增或删除在使用add、remove等方法修改
    _currentPlaylist = ConcatenatingAudioSource(children: tempChildren);

    print("****************");
    print(_currentPlaylist);
    print(_initIndex);
  }

  // 设置初始化播放列表源
  Future<void> refreshCurrentPlaylist() async {
    print("refreshCurrentPlaylist ================");
    try {
      // 更新，重新绑定音源
      await _player.setAudioSource(_currentPlaylist, initialIndex: _initIndex);

      print(_player.sequenceStateStream);
    } catch (e) {
      print("refreshCurrentPlaylist Error: $e");
    }
  }

  // 通过索引获取当前播放列表中的指定音源
  AudioSource getAudioSourceByIndex(int audioIndex) =>
      _currentPlaylist.children[audioIndex];

  // 继续播放
  Future<void> play() => _player.play();

  // 暂停播放
  Future<void> pause() => _player.pause();

  // 是否有上一曲
  bool hasPrevious() => _player.hasPrevious;

  List<int>? getEffectiveIndices() => _player.effectiveIndices;

  // 上一曲
  Future<void> seekToPrevious() => _player.seekToPrevious();

  // 是否有下一曲
  bool hasNext() => _player.hasNext;

  // 下一曲
  Future<void> seekToNext() => _player.seekToNext();

  // 进度条拉取跳转
  Future<void> seek(Duration? position, {int? index}) =>
      _player.seek(position, index: index);

  // 随机播放
  Future<void> shuffle() => _player.shuffle();
  // 设置随机播放模式
  Future<void> setShuffleModeEnabled(bool flag) =>
      _player.setShuffleModeEnabled(flag);

  // 设置歌曲循环的模式（单曲循环、不循环、列表循环）
  Future<void> setRepeatMode(LoopMode repeatMode) async {
    switch (repeatMode) {
      case LoopMode.off:
        _player.setLoopMode(LoopMode.off);
        break;
      case LoopMode.one:
        _player.setLoopMode(LoopMode.one);
        break;
      case LoopMode.all:
        _player.setLoopMode(LoopMode.all);
        break;
    }
  }

  // 停止播放
  void stop() {
    _player.stop();
  }

  // 处置播放器（一般关闭时）
  void dispose() {
    _player.dispose();
  }

  // 获取播放器的各种流
  // Stream<LoopMode> getLoopModeStream() => _player.loopModeStream;
  Future<Stream<LoopMode>> getLoopModeStream() async {
    var temp = await _simpleShared.getCurrentCycleMode();
    return BehaviorSubject.seeded(temp).stream;
  }

  Stream<SequenceState?> getSequenceStateStream() =>
      _player.sequenceStateStream;

  // Stream<bool> getShuffleModeEnabledStream() =>
  //     _player.shuffleModeEnabledStream;

  // 持久化数据中获取
  Future<Stream<bool>> getShuffleModeEnabledStream() async {
    var temp = await _simpleShared.getCurrentIsShuffleMode();
    return BehaviorSubject.seeded(temp).stream;
  }

  Stream<PlayerState> getPlayerStateStream() => _player.playerStateStream;

  // 音频播放速度相关流和属性、方法
  Stream<double> getSpeedStream() => _player.speedStream;
  // 当前播放速度
  double get speed => _player.speed;
  // 设置播放速度
  Future<void> Function(double) setSpeed() => _player.setSpeed;

  // 音量相关的流和属性、方法
  Stream<double> get volumeStream => _player.volumeStream;
  double get volume => _player.volume;
  Future<void> Function(double) get setVolume => _player.setVolume;

  // 获取当前播放位置音频数据
  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          _player.positionStream,
          _player.bufferedPositionStream,
          _player.durationStream,
          (position, bufferedPosition, duration) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero));

  // 音频播放速度相关流和属性、方法
  int? get nextIndex => _player.nextIndex;
  int? get currentIndex => _player.currentIndex;

  // ？？？获取当前播放列表和其音频索引，存入数据库中
}

/// 音频进度条位置数据（当前位置、缓存位置、总时长）
class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}
