import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/global_styles.dart';
import '../../../services/my_audio_handler.dart';
import '../../../services/my_audio_query.dart';
import '../../../services/service_locator.dart';
import '../widgets/common.dart';
import '../widgets/common_small_widgets.dart';

/// 音乐播放器主界面
/// 本地音乐或者之后在线音乐，不管从哪里点击音乐，都进入到此音乐播放详情页面
/// 因此需要传入音乐信息用于播放

class JustAudioMusicPlayer extends StatefulWidget {
  const JustAudioMusicPlayer({super.key});

  @override
  JustAudioMusicPlayerState createState() => JustAudioMusicPlayerState();
}

class JustAudioMusicPlayerState extends State<JustAudioMusicPlayer>
    with WidgetsBindingObserver {
  final _audioHandler = getIt<MyAudioHandler>();

  // 获取查询音乐组件实例
  final _audioQuery = getIt<MyAudioQuery>();

  // 更新当前音乐的下一首
  late int nextAudionIndex = _audioHandler.nextIndex ?? 0;

  @override
  void initState() {
    super.initState();

    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());

    _audioHandler.play();
  }

  // 如果这里处理掉player了，那么切换到其他页面后，自然就停止播放了。
  // 此外，也需要注意全局同一个player实例，否则背景播放可能会出问题
  // @override
  // void dispose() {
  //   _player.dispose();
  //   super.dispose();
  // }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // 在不使用时释放播放器的资源。
      // 使用 "stop"，则可以如果应用程序稍后恢复，它仍会记得从哪个位置恢复。
      _audioHandler.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, // 设置为透明色
        elevation: 0, // 去除阴影
        // 设置返回箭头颜色
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// 正在播放的音频区域
            Expanded(flex: 4, child: _buildCrrentMusicInfo()),

            // divider看位置的，最后不用
            // Divider(height: 2, thickness: 1.sp, color: Colors.grey),

            /// 音频拖动进度条
            Expanded(
              flex: 1,
              child: StreamBuilder<PositionData>(
                // 当前播放位置音频数据
                stream: _audioHandler.positionDataStream,
                builder: (context, snapshot) {
                  final positionData = snapshot.data;
                  // 进度条左边是当前时间，右边是总时间
                  return Center(
                    child: SeekBar(
                      duration: positionData?.duration ?? Duration.zero,
                      position: positionData?.position ?? Duration.zero,
                      bufferedPosition:
                          positionData?.bufferedPosition ?? Duration.zero,
                      onChangeEnd: (newPosition) {
                        _audioHandler.seek(newPosition);
                      },
                    ),
                  );
                },
              ),
            ),

            // divider看位置的，最后不用
            // Divider(height: 2, thickness: 1.sp, color: Colors.grey),

            /// 音频控制按钮区域
            Expanded(
              flex: 1,
              child: Center(
                child: ControlButtons(
                  callback: (value) {
                    // 播放主页面点击了任何按钮，都要返回下一首歌的索引，用来创建下一首歌的概要信息
                    // 点击上下一曲、列表循环切换、随机播放等按钮都会改变下一首歌的索引

                    // 2024-01-12 因此可能存在列表就1首歌，那么控制按钮组件返回的上/下一个音频的编号可能为null
                    // 所以这里要判断先
                    if (value is int) {
                      setState(() {
                        nextAudionIndex = value;
                      });
                    }
                  },
                ),
              ),
            ),

            // divider看位置的，最后不用
            // Divider(height: 2, thickness: 1.sp, color: Colors.grey),

            /// 下一曲概述
            Expanded(flex: 1, child: _buildNextMusicInfo())
          ],
        ),
      ),
      // 左上角一个悬空的返回箭头按钮
      // 2024-01-12 有透明的appbar的话就不要这个类
      // floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      // floatingActionButton: IconButton(
      //   icon: Icon(Icons.arrow_back, size: 30.sp),
      //   onPressed: () => Navigator.of(context).pop(),
      // ),
    );
  }

  /// 当前音频信息区域
  // 2024-01-12 在新手机上(andriod13的努比亚z50ultra)看到缩略图很糊，所以修改一下显示大小
  _buildCrrentMusicInfo() {
    return StreamBuilder<SequenceState?>(
      stream: _audioHandler.getSequenceStateStream(),
      builder: (context, snapshot) {
        final state = snapshot.data;

        if (state?.sequence.isEmpty ?? true) {
          return const SizedBox();
        }

        final metadata = state!.currentSource!.tag as MediaItem;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 9,
              child: Padding(
                padding: EdgeInsets.fromLTRB(0.15.sw, 0, 0.15.sw, 0.1.sw),
                child: SizedBox(
                  width: 1.0.sw,
                  child: metadata.artUri != null
                      ? Image.file(
                          File.fromUri(metadata.artUri!),
                          fit: BoxFit.fitWidth,
                          filterQuality: FilterQuality.high,
                        )
                      : Image.asset(
                          placeholderImageUrl,
                          fit: BoxFit.fitWidth,
                        ),
                ),

                /// 2024-01-12 这两者加载的图片在z50ultra都不清晰。但1080P的小米6 效果好很多
                // QueryArtworkWidget(
                //   id: int.parse(metadata.id),
                //   type: ArtworkType.AUDIO,
                //   artworkQuality: FilterQuality.high,
                //   artworkWidth: 1.sw,
                //   artworkBorder: BorderRadius.zero, // 图标边角无圆弧
                //   keepOldArtwork: true, // 在生命周期内使用旧的缩略图
                //   // 没有歌曲缩略图时使用占位图
                //   nullArtworkWidget: SizedBox(
                //     width: 1.sw,
                //     child: Image.asset(
                //       placeholderImageUrl,
                //       fit: BoxFit.cover,
                //     ),
                //   ),
                // ),
              ),
            ),
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                child: Column(children: [
                  // 歌名
                  SimpleMarqueeOrText(
                    data: '${state.currentIndex}-${metadata.title}',
                    style: TextStyle(fontSize: sizeHeadline0),
                  ),
                  // 分割占位
                  SizedBox(height: 10.sp),
                  // 歌手+专辑名
                  SimpleMarqueeOrText(
                    data:
                        '${metadata.artist ?? "未知歌手"} -- ${metadata.album ?? "未知专辑"}',
                    style: TextStyle(fontSize: sizeHeadline2),
                  ),
                ]),
              ),
            ),

            /// 2024-01-10 避免有些音频嵌入的信息是乱码，显示一个音频所在的地址辅助显示查看
            Expanded(
              flex: 1,
              child: FutureBuilder<List<dynamic>>(
                  future: _audioQuery.queryWithFilters(
                    metadata.title,
                    WithFiltersType.AUDIOS,
                  ),
                  builder: (context, item) {
                    // 有错显示错误
                    if (item.hasError) {
                      return Center(child: Text(item.error.toString()));
                    }
                    // 无数据转圈等到加载完成
                    if (item.data == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    // 数据为空显示无结果
                    if (item.data!.isEmpty) {
                      return const Center(child: Text("暂无音频信息"));
                    }

                    // 得到查询的歌单列表
                    List<SongModel> audios = item.data!.toSongModel();

                    // 滚动显示音频所在的地址，清除前面部分内容
                    // 在Android上，音频内部存储地址默认前缀是`/storage/emulated/0`
                    return SimpleMarqueeOrText(
                      data: audios.isNotEmpty
                          ? "存储位置: ${audios[0].data.substring(19)}"
                          : '',
                      style: TextStyle(fontSize: 12.sp),
                    );
                  }),
            )
          ],
        );
      },
    );
  }

  /// 下一首音频概要信息区域
  _buildNextMusicInfo() {
    return FutureBuilder(
      future: _audioHandler.getLoopModeValue(),
      builder: (context, AsyncSnapshot<LoopMode> snapshot) {
        if (snapshot.hasError) {
          return Text(snapshot.error.toString());
        }

        final loopMode = snapshot.data ?? LoopMode.off;

        // 因为下一曲的索引在初始化的时候就直接取得next，所以如果模式是单曲循环，则重置为当前的
        if (loopMode == LoopMode.one) {
          nextAudionIndex = _audioHandler.currentIndex!;
        }
        // 获取下一首音乐的基本信息并构建显示内容
        AudioSource temp = _audioHandler.getAudioSourceByIndex(
          nextAudionIndex,
        );

        final metadata = temp.sequence.first.tag as MediaItem;
        var nextInfo =
            "下一首：$nextAudionIndex-${metadata.title}-${metadata.artist}";

        return SizedBox(
          // 这个会让下面的 simpleMarqueeOrText 设置的宽度无效
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.all(5.sp),
            child: Card(
              elevation: 5.sp,
              child: SimpleMarqueeOrText(
                data: nextInfo,
                style: TextStyle(fontSize: sizeContent0),
              ),
            ),
          ),
        );
      },
    );
  }
}
