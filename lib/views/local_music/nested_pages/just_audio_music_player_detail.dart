import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/global_styles.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../services/my_audio_handler.dart';
import '../../../services/my_audio_query.dart';
import '../../../services/my_get_storage.dart';
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

  // 统一简单存储操作的工具类实例
  final _simpleStorage = getIt<MyGetStorage>();

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
        // backgroundColor: Colors.transparent, // 设置为透明色
        elevation: 0, // 去除阴影
        // 设置返回箭头颜色
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
        // leading: SizedBox(
        //   height: 48.sp,
        //   child: Icon(Icons.arrow_back, size: 24.sp),
        // ),
        actions: [
          IconButton(
            onPressed: () => _buildPlaylistModalBottomSheet(),
            icon: const Icon(Icons.queue_music),
          ),
        ],
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
            Expanded(
              flex: 1,
              child: Center(child: _buildNextMusicInfo()),
            )
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
                          fit: BoxFit.scaleDown,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (BuildContext context, Object exception,
                                  StackTrace? stackTrace) =>
                              Image.asset(
                            placeholderImageUrl,
                            fit: BoxFit.scaleDown,
                          ),
                        )
                      : Image.asset(
                          placeholderImageUrl,
                          fit: BoxFit.scaleDown,
                          errorBuilder: (BuildContext context, Object exception,
                                  StackTrace? stackTrace) =>
                              Image.asset(
                            placeholderImageUrl,
                            fit: BoxFit.scaleDown,
                          ),
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
                    // 在Android上，音频内部存储地址默认前缀是`/storage/emulated/0/`
                    return SimpleMarqueeOrText(
                      data: audios.isNotEmpty
                          ? "存储位置: ${audios[0].data.substring(20)}"
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
          // 和外层的bar高度一样
          height: 70.sp,
          child: Padding(
            padding: EdgeInsets.all(2.sp),
            child: Card(
              elevation: 2.sp,
              child: Padding(
                // 让滚动文字前后有点空白
                padding: EdgeInsets.symmetric(horizontal: 10.sp),
                child: SimpleMarqueeOrText(
                  data: nextInfo,
                  style: TextStyle(fontSize: sizeContent0),
                  // style: TextStyle(fontSize: sizeHeadline2),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建播放列表底部弹窗
  _buildPlaylistModalBottomSheet() async {
    // 当前播放列表
    var playlist = _audioHandler.getAudioSource();
    // 当前播放索引
    var index = _audioHandler.player().currentIndex ?? 0;

    // 创建一个 ScrollController
    final ScrollController scrollController = ScrollController();

    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        // 在弹窗打开时，异步将当前选中的索引元素滚动到列表的第一位
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          // 延迟一小段时间，确保 ListView 已经渲染
          // await Future.delayed(const Duration(milliseconds: 50));
          // 确保 ListView 已经渲染
          await Future.microtask(() {});

          // 56.0 是 ListTile 的平均高度
          // scrollController.jumpTo((index - 1) * 56.0);

          // 滚动到指定播放索引去(越到后面越慢，就看着越卡)
          await scrollController.animateTo(
            (index - 1) * 56.sp, // 目标位置
            duration: const Duration(milliseconds: 200), // 动画持续时间
            curve: Curves.easeInOut, // 动画曲线
          );
        });

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15.sp),
              topRight: Radius.circular(15.sp),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.sp),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("当前播放列表", style: TextStyle(fontSize: 18.sp)),
                    TextButton(
                      child: const Text('关闭'),
                      onPressed: () {
                        Navigator.pop(context);
                        unfocusHandle();
                      },
                    ),
                  ],
                ),
              ),
              Divider(height: 2.sp, thickness: 2.sp),
              Expanded(
                child: ListView.builder(
                  controller: scrollController, // 使用 ScrollController
                  itemCount: playlist.children.length,
                  itemExtent: 56.sp, // 设置每个列表项的高度
                  shrinkWrap: true, // 确保 ListView 的高度自适应内容
                  // 确保 ListView 始终可以滚动
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int i) {
                    bool isCurrent = i == index;
                    MediaItem? sor;

                    // 检查 playlist.children[i].sequence 是否为空
                    if (playlist.children[i].sequence.isNotEmpty) {
                      // 检查 playlist.children[i].sequence.first.tag 是否为 MediaItem 类型
                      if (playlist.children[i].sequence.first.tag
                          is MediaItem) {
                        sor = playlist.children[i].sequence.first.tag;
                      }
                    }

                    return _buildPlaylistItem(sor, isCurrent, i);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  _buildPlaylistItem(MediaItem? sor, bool isCurrent, int index) {
    // 其他的条目样式，暂时还是listtile
    SizedBox(
      height: 56.sp,
      child: InkWell(
        onTap: () async {
          await _audioHandler.player().seek(Duration.zero, index: index);
          await _audioHandler.play();

          // 2024-10-28 在播放详情页只是切换了当前歌单的播放编号，不支持其他内容的修改
          // 所有不必更新其他缓存
          await _simpleStorage.setCurrentAudioIndex(index);

          // 切换到了其他索引要关闭弹窗
          if (!mounted) return;
          Navigator.pop(context);
        },
        // child: RichText(
        //   maxLines: 2,
        //   overflow: TextOverflow.ellipsis,
        //   text: TextSpan(
        //     children: [
        //       TextSpan(
        //         text: sor?.title ?? '',
        //         style: TextStyle(
        //           // fontWeight: FontWeight.bold,
        //           fontSize: 15.sp,
        //           color: isCurrent ? Colors.blue : Colors.black,
        //         ),
        //       ),
        //       TextSpan(
        //         text: "\n${sor?.artist ?? ''}",
        //         style: TextStyle(
        //           fontSize: 12.sp,
        //           color: isCurrent ? Colors.blue : Colors.grey,
        //         ),
        //       ),
        //     ],
        //   ),
        // ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sor != null
                ? Text(
                    sor.title,
                    style: TextStyle(
                      color: isCurrent ? Colors.blue : null,
                    ),
                  )
                : const Text("无效的媒体项"),
            Text(
              sor?.artist ?? '',
              style: TextStyle(fontSize: 12.sp),
            ),
          ],
        ),
      ),
    );

    return SizedBox(
      height: 56.sp,
      child: ListTile(
        onTap: () async {
          await _audioHandler.player().seek(Duration.zero, index: index);
          await _audioHandler.play();

          // 2024-10-28 在播放详情页只是切换了当前歌单的播放编号，不支持其他内容的修改
          // 所有不必更新其他缓存
          await _simpleStorage.setCurrentAudioIndex(index);

          // 切换到了其他索引要关闭弹窗
          if (!mounted) return;
          Navigator.pop(context);
        },
        leading: isCurrent
            ? const Icon(
                Icons.graphic_eq,
                color: Colors.blue,
              )
            : null,
        title: sor != null
            ? Text(
                sor.title,
                style: TextStyle(color: isCurrent ? Colors.blue : null),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : const Text("无效的媒体项"),
        subtitle: Text(
          sor?.artist ?? '',
          style: TextStyle(color: isCurrent ? Colors.blue : null),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
