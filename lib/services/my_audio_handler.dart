// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:rxdart/rxdart.dart';

import '../common/global/constants.dart';
import 'my_audio_query.dart';
import 'my_get_storage.dart';
import 'service_locator.dart';

// 定义一个 ValueNotifier 来管理当前正在处理的音频文件的状态
var currentProcessingAudio = ValueNotifier<SongModel?>(null);

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
  final _simpleStorage = getIt<MyGetStorage>();

  // 构造函数（原本在构造函数中执行初始化，现在在获得授权后在app处初始化）
  // MyAudioHandler();

  // 获取当前播放列表和当前音乐索引（正常来讲，这个会存入db）
  // 其他情况改变了当前列表，则额外处理
  Future<void> _getInitPlaylistAndIndex() async {
    // 获取当前的播放列表数据
    // 这个list有依次3个值：当前列表类型、当前音频在列表中的索引、当前播放列表编号
    var tempList = await _simpleStorage.getCurrentAudioInfo();

    print(
        "listType ${tempList[0]}, audioIndex ${tempList[1]}, playlistId ${tempList[2]}");

    List<SongModel> songs;
    switch (tempList[0]) {
      case AudioListTypes.all:
        songs = await _audioQuery.querySongs();
        break;
      case AudioListTypes.playlist:
        // 当前歌单编号
        // songs = await _audioQuery.queryAudiosFrom(
        //     AudiosFromType.PLAYLIST, tempList[2]);

        var temp = await _audioQuery.queryAudiosFrom(
          AudiosFromType.PLAYLIST,
          tempList[2],
          sortType: SongSortType.TITLE,
          orderType: OrderType.ASC_OR_SMALLER,
        );

        // 如果是歌单tab进入来查询歌单中拥有的音频，因为组件接口从歌单中查询的音频结果没有原始音频id，而是编码后的编号，
        // 所以想用该音频id查询音频的例如封面图等，就取不到。
        // 所以在这里对得到的结果，用名称再查询一次，构建新的音频列表，带上原始id

        var tempList1 = [];

        for (SongModel e in temp) {
          var tempAl = await _audioQuery.queryWithFilters(
              e.title, WithFiltersType.AUDIOS);
          tempList1.add(tempAl[0]);
        }

        songs = tempList1.toSongModel();

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

  // 2024-01-10 启动时也把占位图片Uri保存到缓存
  Future<void> setDefaultArtUriFromAssets() async {
    // 预设当音频文件没有自带缩略图时，用来显示的预设图片位置
    final byteData = await rootBundle.load(placeholderImageUrl);
    final buffer = byteData.buffer;
    // 从asset加载到缓存文件夹中
    Directory tempDir = await getApplicationDocumentsDirectory();
    String tempPath = tempDir.path;
    var filePath = '$tempPath/placeholder.png';
    final file = await File(filePath).writeAsBytes(
      buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      ),
    );

    // 将缓存文件夹的地址保存到缓存去中，key为预设字符串
    await box.write("placeholderArtUri", file.uri.toString());
  }

  //  将歌曲列表分成多个批次，逐批处理，避免一次性处理过多歌曲导致内存和性能问题。
  Future<void> cacheAllAudioThumbnail() async {
    // var start = DateTime.now().millisecondsSinceEpoch;

    // 1. 查询所有音频文件
    var songs = await _audioQuery.querySongs();
    // var end1 = DateTime.now().millisecondsSinceEpoch;

    // print("缓存所有的音频----${songs.length} ${box.read("placeholderArtUri")}");

    // 如果缓存中还没有预设的占位音频缩略图，就先添加到缓存
    if (box.read("placeholderArtUri") == null) {
      await setDefaultArtUriFromAssets();
    }

    // 2. 批量处理缩略图缓存，避免一次性处理过多歌曲导致内存和性能问题
    const batchSize = 10; // 每批处理的歌曲数量
    for (var i = 0; i < songs.length; i += batchSize) {
      var batch = songs.sublist(
        i,
        i + batchSize > songs.length ? songs.length : i + batchSize,
      );
      await Future.wait(batch.map((e) async {
        // 更新当前正在处理的音频文件的状态
        currentProcessingAudio.value = e;

        // 如果对应音频id的缩略图缓存已经存在，就不新加了
        if (box.read(e.id.toString()) != null) {
          return;
        }

        // 查询指定音频的缩略图数据
        var tempData = await _audioQuery.queryArtwork(e.id, ArtworkType.AUDIO);
        if (tempData == null) {
          // 音频文件没有缩略图就用预设图片
          await box.write(e.id.toString(), box.read("placeholderArtUri"));
          return;
        }

        // 音频有带缩略图，就保存为缓存文件，然后缓存音频编号记录uri字符串
        final directory = await getApplicationDocumentsDirectory();
        final pathOfImage = File('${directory.path}/${e.id}.png');
        await pathOfImage.writeAsBytes(tempData);
        await box.write(e.id.toString(), pathOfImage.uri.toString());
      }).toList());

      // 处理完成后，重置状态
      currentProcessingAudio.value = null;
    }

    // var end2 = DateTime.now().millisecondsSinceEpoch;

    // print("查询歌曲 耗时${end1 - start}");
    // print("构建缩略图 耗时${end2 - start}");
  }

  // 异步构建音频缩略图，但可能会出现一大串
  // E/flutter (25098): [ERROR:flutter/runtime/dart_vm_initializer.cc(41)]
  //  Unhandled Exception: FileSystemException: An async operation is currently pending,
  // path = '/data/user/0/com.swm.freadermediaplayer/app_flutter/GetStorage.gs'
  Future<void> _cacheAllAudioThumbnailNew1() async {
    var start = DateTime.now().millisecondsSinceEpoch;

    // 1. 查询所有音频文件
    var songs = await _audioQuery.querySongs();
    var end1 = DateTime.now().millisecondsSinceEpoch;

    print("缓存所有的音频----${songs.length} ${box.read("placeholderArtUri")}");

    // 如果缓存中还没有预设的占位音频缩略图，就先添加到缓存
    if (box.read("placeholderArtUri") == null) {
      await setDefaultArtUriFromAssets();
    }

    // 2. 并行处理缩略图缓存
    await Future.wait(songs.map((e) async {
      // 如果对应音频id的缩略图缓存已经存在，就不新加了
      if (box.read(e.id.toString()) != null) {
        return;
      }

      // 查询指定音频的缩略图数据
      var tempData = await _audioQuery.queryArtwork(e.id, ArtworkType.AUDIO);
      if (tempData == null) {
        // 音频文件没有缩略图就用预设图片
        await box.write(e.id.toString(), box.read("placeholderArtUri"));
        return;
      }

      // 音频有带缩略图，就保存为缓存文件，然后缓存音频编号记录uri字符串
      final directory = await getApplicationDocumentsDirectory();
      final pathOfImage = File('${directory.path}/${e.id}.png');
      await pathOfImage.writeAsBytes(tempData);
      await box.write(e.id.toString(), pathOfImage.uri.toString());
    }).toList());

    var end2 = DateTime.now().millisecondsSinceEpoch;

    print("查询歌曲 耗时${end1 - start}");
    print("构建缩略图 耗时${end2 - start}");
  }

  /// 缓存所有音频的缩略图
  /// 2024-10-28 因为全是同步的操作，所以音频文件非常多的时候会很慢
  Future<void> _cacheAllAudioThumbnailOld() async {
    /// 1 查到所有的音频文件
    ///
    var start = (DateTime.now().millisecondsSinceEpoch);
    var songs = await _audioQuery.querySongs();

    var end1 = (DateTime.now().millisecondsSinceEpoch);

    /// 2 将音频文件内置的缩略图缓存到app内部缓存文件夹中
    ///
    ///
    print("缓存所有的音频----${songs.length} ${box.read("placeholderArtUri")}");

    // 如果缓存中还没有预设的占位音频缩略图，就先添加到缓存
    if (box.read("placeholderArtUri") == null) {
      await setDefaultArtUriFromAssets();
    }

    /// 2024-01-10 在初始化时，遍历音频文件，把查询到的音频文件的缩略图，保存到缓存中去
    for (var e in songs) {
      // 如果对应音频id的缩略图缓存已经存在，就不新加了
      if (box.read(e.id.toString()) != null) {
        continue;
      }

      // 查询指定音频的缩略图数据
      var tempData = await _audioQuery.queryArtwork(e.id, ArtworkType.AUDIO);
      if (tempData == null) {
        // 音频文件没有缩略图就用预设图片
        await box.write(e.id.toString(), box.read("placeholderArtUri"));
        continue;
      }

      // 音频有带缩略图，就保存为缓存文件，然后缓存音频编号记录uri字符串
      final directory = await getApplicationDocumentsDirectory();
      final pathOfImage = await File('${directory.path}/${e.id}.png').create();
      File imageFile = await pathOfImage.writeAsBytes(tempData);
      await box.write(e.id.toString(), imageFile.uri.toString());
    }

    var end2 = (DateTime.now().millisecondsSinceEpoch);

    print("查询歌曲 耗时${end1 - start}");
    print("构建缩略图 耗时${end2 - start}");
  }

  // 设置初始化播放列表源（这在app启动时就要加载完成）
  Future<void> _loadInitCurrentPlaylist() async {
    try {
      /// ？？？TODO 2024-01-09 暂时解释不了
      /// 我需要先这里设置一次音源，然后再去缓存查询上次记录音乐信息才有效果，否则就查询结果是空
      ///     有尝试寻找原因，在app.dart进行_audioHandler.myAudioHandlerInit() 前获取也是空
      ///     在这里重复查询，等待这几个工具类实例初始化完成，还是空。从现有代码就是先设置音乐，再查询就可以
      ///
      ///     但是，如果这里重复了，选择了其他歌手、专辑等分类，更新了当前播放的音乐，退出app之后再进来，可能会报错，
      ///     Cannot set the method call handler before the binary messenger has been initialized.
      ///     报错位置就是上面的 final _player = AudioPlayer();
      ///     但偶尔又没有报错
      ///
      ///  2024-01-12 不先设置好像缓存中上次播放内容又不是null了
      // await _player.setAudioSource(_currentPlaylist, initialIndex: _initIndex);

      // TEST
      // var [a, b, c] = await _simpleStorage.getCurrentAudioInfo();

      // print("TEST】】】】 初始化当前播放列表和音频【前】读取的缓存:");
      // print("listType $a, audioIndex $b, playlistId $c");

      // 等待获取到持久化中的播放列表和索引之后，再绑定音源
      await _getInitPlaylistAndIndex();

      // TEST
      // var [aa, bb, cc] = await _simpleStorage.getCurrentAudioInfo();
      // print("TEST】】】】 初始化当前播放列表和音频【后】读取的缓存:");
      // print("listType $aa, audioIndex $bb, playlistId $cc");

      await _player.setAudioSource(_currentPlaylist, initialIndex: _initIndex);
    } catch (e) {
      print("【Error】 --- in _loadInitCurrentPlaylist : $e");
    }
  }

  // 在播放过程中侦听错误。
  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
      print("【Error】 --- in _notifyAudioHandlerAboutPlaybackEvents : $e");
    });
  }

  /// ------------ 上面是内部私有方法

  Future<bool> myAudioHandlerInit() async {
    try {
      // 2024-01-11
      // 第一步：启动app时，缓存所有音频文件的缩略图
      await cacheAllAudioThumbnail();
      // 第二步：构建上次退出时所播放的歌单和歌曲
      await _loadInitCurrentPlaylist();
      // 第三步：添加在播放过程中的错误监听器
      _notifyAudioHandlerAboutPlaybackEvents();

      return true;
    } catch (e) {
      print("【Error】 --- in myAudioHandlerInit : $e");
      return false;
    }
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
            // 这个属性与背景播放时状态栏显示音频缩略图相关。但just audio 不支持UInt8List了。
            // 这里是得到Uint8List之后存为图片，放到临时地址，再获取该地址用于构建音源。
            // 如果在构建的歌单音频很多，那这里会花很多时间。却没有什么办法
            // artUri: await getImageFileFromAssets(ele.id),

            /// 2024-01-10 新想法，在首次加载音频的时候，就把这些音频的缩略图放到缓存中，这里通过id查询该图片地址
            /// 所以初次使用时，显示扫描的圈圈，就是构建缩略图操作，一个key value的map：{audio_id,image_path}
            /// 之后直接从缓存取缩略图地址会快些
            artUri: box.read(ele.id.toString()) != ""
                ? Uri.parse(box.read(ele.id.toString()))
                : null,
            // extras: cusExtras,
          ),
        ),
      );
    }

    // 构建新的播放列表就直接替换，在原列表上新增或删除在使用add、remove等方法修改
    _currentPlaylist = ConcatenatingAudioSource(children: tempChildren);
  }

  /// 2024-01-23 photo manage查询的音频，也用这个通用的播放器，只不过不缓存当前播放音频
  /// 但是构建播放列表的源数据格式不一样了
  Future<void> buildPlaylistByAssetEntity(
    List<AssetEntity> list,
    int currentIndex,
  ) async {
    List<AudioSource> tempChildren = [];

    // 初始化索引为当前索引
    _initIndex = currentIndex;

    // 1 遍历歌单歌曲地址，获取元数据信息，构建列表组件
    for (var i = 0; i < list.length; i++) {
      var entity = list[i];

      /// 目前这个cusExtras保存的东西就很多了
      ///     1 音频新增到db时的文件元数据，"metadata"
      ///     2 本条 LocalPlaylistHasAudio 的row数据， "playlistHasAudio"
      ///  这里不先转换json而是直接赋值的的话，会导致因为引用类型的原因，在addAll()之后修改了原本的extrax的结构，会出问题

      // 其他的音频，顺序加入列表组件
      tempChildren.add(
        AudioSource.uri(
          Uri.parse((await entity.file)!.path),
          tag: MediaItem(
            id: entity.id.toString(),
            title: entity.title ?? "",
            // 实际上是没有这些属性的，就占位用
            artist: entity.relativePath,
            album: entity.id,
            artUri: box.read(entity.id.toString()) != ""
                ? Uri.parse(box.read(entity.id.toString()))
                : null,
            // extras: cusExtras,
          ),
        ),
      );
    }

    // 构建新的播放列表就直接替换，在原列表上新增或删除在使用add、remove等方法修改
    _currentPlaylist = ConcatenatingAudioSource(children: tempChildren);
  }

  // 获取指定音频的artwork UInt8List数据，转为file并返回其uri
  Future<Uri?> getImageFileFromAssets(int audioId) async {
    var tempData = await _audioQuery.queryArtwork(audioId, ArtworkType.AUDIO);

    if (tempData == null) {
      return null;
    }

    final directory = await getApplicationDocumentsDirectory();
    final pathOfImage = await File('${directory.path}/$audioId.png').create();
    File imageFile = await pathOfImage.writeAsBytes(tempData);
    return imageFile.uri;
  }

  // 设置初始化播放列表源
  Future<void> refreshCurrentPlaylist() async {
    print("refreshCurrentPlaylist ================");
    try {
      // 更新，重新绑定音源
      await _player.setAudioSource(_currentPlaylist, initialIndex: _initIndex);

      print(_player.sequenceStateStream);
    } catch (e) {
      print("【refreshCurrentPlaylist Error:】】】】】】】】 $e");
      rethrow;
    }
  }

  // 通过索引获取当前播放列表中的指定音源
  AudioSource getAudioSourceByIndex(int audioIndex) =>
      _currentPlaylist.children[audioIndex];

  // 通过当前播放列表中
  ConcatenatingAudioSource getAudioSource() => _currentPlaylist;

  // 获取音频播放实例
  AudioPlayer player() => _player;

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

  /// 原本是直接从当前播放获取模式的stream，后来是从缓存获取stream，再后来是直接取value
  /// ???可能出现取值问题，但这里暂时都认为不会出错。真有bug再说吧。
  /// 下面获取持久化的随机模式值也一样

  // Stream<LoopMode> getLoopModeStream() => _player.loopModeStream;
  Future<Stream<LoopMode>> getLoopModeStream() async {
    var temp = await _simpleStorage.getCurrentCycleMode();
    return BehaviorSubject.seeded(temp).stream;
  }

  Future<LoopMode> getLoopModeValue() async {
    var temp = await _simpleStorage.getCurrentCycleMode();
    return BehaviorSubject.seeded(temp).stream.value;
  }

  // Stream<bool> getShuffleModeEnabledStream() =>
  //     _player.shuffleModeEnabledStream;

  // 持久化数据中获取
  Future<Stream<bool>> getShuffleModeEnabledStream() async {
    var temp = await _simpleStorage.getCurrentIsShuffleMode();
    return BehaviorSubject.seeded(temp).stream;
  }

  Future<bool> getShuffleModeEnabledValue() async {
    var temp = await _simpleStorage.getCurrentIsShuffleMode();
    return BehaviorSubject.seeded(temp).stream.value;
  }

  // --------------------

  Stream<SequenceState?> getSequenceStateStream() =>
      _player.sequenceStateStream;

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
}

/// 音频进度条位置数据（当前位置、缓存位置、总时长）
class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}
