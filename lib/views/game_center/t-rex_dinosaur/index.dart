import 'dart:math';
import 'package:flutter/material.dart';

import '../../../services/my_get_storage.dart';
import '../../../services/service_locator.dart';
import 'components/cactus.dart';
import 'components/cloud.dart';
import 'components/dino.dart';
import 'components/ground.dart';
import 'const/constants.dart';
import 'models/game_object.dart';

class TRexDinosaur extends StatefulWidget {
  const TRexDinosaur({super.key});
  @override
  State<TRexDinosaur> createState() => _TRexDinosaurState();
}

class _TRexDinosaurState extends State<TRexDinosaur>
    with SingleTickerProviderStateMixin {
  // 恐龙实例
  Dino dino = Dino();
  // 默认的初始速度
  double runVelocity = initialVelocity;
  // 恐龙前进的距离(当前得分)
  double runDistance = 0;
  // 最高得分(历史最高得分)
  // 2024-01-31 我会加入缓存中进行持久化
  int highScore = 0;
  // 或许设置中各项数值：重力、加速度、跳跃速度、初始速度、昼夜偏移
  // 其实可以使用项目中已经有的formbuilder，但此处保持原样
  TextEditingController gravityController =
      TextEditingController(text: gravity.toString());
  TextEditingController accelerationController =
      TextEditingController(text: acceleration.toString());
  TextEditingController jumpVelocityController =
      TextEditingController(text: jumpVelocity.toString());
  TextEditingController runVelocityController =
      TextEditingController(text: initialVelocity.toString());
  TextEditingController dayNightOffestController =
      TextEditingController(text: dayNightOffest.toString());

  // 整体的动画控制器
  late AnimationController worldController;
  // 上次更新的时间(随着运行时间增加，上次更新的时间也会变化)
  Duration lastUpdateCall = const Duration();

  /// 这些都会根据运行时间，也就是恐龙跑的距离增加而在屏幕中刷新
  /// 所以这里只是初始的值
  // 仙人掌实例
  List<Cactus> cacti = [
    Cactus(worldLocation: const Offset(200, 0)),
  ];
  // 地面实例
  List<Ground> ground = [
    Ground(worldLocation: const Offset(0, 0)),
    Ground(worldLocation: Offset(groundSprite.imageWidth / 10, 0))
  ];
  // 云朵实例
  List<Cloud> clouds = [
    Cloud(worldLocation: const Offset(100, 20)),
    Cloud(worldLocation: const Offset(200, 10)),
    Cloud(worldLocation: const Offset(350, -10)),
  ];

  // 统一简单存储操作的工具类实例
  final _simpleStorage = getIt<MyGetStorage>();

  @override
  void initState() {
    super.initState();

    // 给动画控制器添加更新侦听
    worldController = AnimationController(
      vsync: this,
      duration: const Duration(days: 99),
    );
    worldController.addListener(_update);
    // worldController.forward();
    // 初始默认为停止状态
    _die();

    // 2024-01-31 获取缓存中历史最高分数
    highScore = _simpleStorage.getDinosaurBestScore() ?? 0;
  }

  @override
  void dispose() {
    gravityController.dispose();
    accelerationController.dispose();
    jumpVelocityController.dispose();
    runVelocityController.dispose();
    dayNightOffestController.dispose();
    worldController.dispose();
    super.dispose();
  }

  void _die() {
    setState(() {
      worldController.stop();
      dino.die();
    });
  }

  // 开始新游戏，基本就是全部重置
  void _newGame() async {
    // 添加异步的话，就要先判断是否挂载了
    if (!mounted) return;
    setState(() {
      highScore = max(highScore, runDistance.toInt());
      runDistance = 0;
      runVelocity = initialVelocity;
      dino.state = DinoState.running;
      dino.dispY = 0;
      worldController.reset();
      cacti = [
        Cactus(worldLocation: const Offset(200, 0)),
        Cactus(worldLocation: const Offset(300, 0)),
        Cactus(worldLocation: const Offset(450, 0)),
      ];

      ground = [
        Ground(worldLocation: const Offset(0, 0)),
        Ground(worldLocation: Offset(groundSprite.imageWidth / 10, 0))
      ];

      clouds = [
        Cloud(worldLocation: const Offset(100, 20)),
        Cloud(worldLocation: const Offset(200, 10)),
        Cloud(worldLocation: const Offset(350, -15)),
        Cloud(worldLocation: const Offset(500, 10)),
        Cloud(worldLocation: const Offset(550, -10)),
      ];

      worldController.forward();
    });

    // 2024-01-31 保存历史最好分数
    await _simpleStorage.setDinosaurBestScore(highScore);
  }

  // 动画控制器侦听的更新方法
  _update() {
    try {
      // 实际运行的时间
      double elapsedTimeSeconds;
      // 更新恐龙实例状态
      dino.update(lastUpdateCall, worldController.lastElapsedDuration);
      try {
        elapsedTimeSeconds =
            (worldController.lastElapsedDuration! - lastUpdateCall)
                    .inMilliseconds /
                1000;
      } catch (_) {
        elapsedTimeSeconds = 0;
      }

      // 已经跑的距离就是初始速度*间隔时间
      runDistance += runVelocity * elapsedTimeSeconds;
      if (runDistance < 0) runDistance = 0;

      // 如果有设置加速度了，则更新恐龙的初始速度
      runVelocity += acceleration * elapsedTimeSeconds;

      // 获取屏幕尺寸
      Size screenSize = MediaQuery.of(context).size;
      // 获取恐龙实例的方块位置
      Rect dinoRect = dino.getRect(screenSize, runDistance);

      // 遍历屏幕中的仙人掌
      for (Cactus cactus in cacti) {
        // 如果说恐龙所在的方块和屏幕中的仙人掌方块有重叠，那说明恐龙碰到了障碍物，游戏结束
        Rect obstacleRect = cactus.getRect(screenSize, runDistance);
        if (dinoRect.overlaps(obstacleRect.deflate(20))) {
          _die();
        }

        // 如果有仙人掌实例已经离开了屏幕视野，则从列表中移除，并随机添加一个新的仙人掌
        if (obstacleRect.right < 0) {
          setState(() {
            cacti.remove(cactus);
            cacti.add(Cactus(
                worldLocation: Offset(
                    runDistance +
                        Random().nextInt(100) +
                        MediaQuery.of(context).size.width / worlToPixelRatio,
                    0)));
          });
        }
      }

      // 如果有地面实例已经离开了屏幕视野，则从列表中移除，并随机添加一个新的地面
      for (Ground groundlet in ground) {
        if (groundlet.getRect(screenSize, runDistance).right < 0) {
          setState(() {
            ground.remove(groundlet);
            ground.add(
              Ground(
                worldLocation: Offset(
                  ground.last.worldLocation.dx + groundSprite.imageWidth / 10,
                  0,
                ),
              ),
            );
          });
        }
      }

      // 如果有云朵实例已经离开了屏幕视野，则从列表中移除，并随机添加一个新的云朵
      for (Cloud cloud in clouds) {
        if (cloud.getRect(screenSize, runDistance).right < 0) {
          setState(() {
            clouds.remove(cloud);
            clouds.add(
              Cloud(
                worldLocation: Offset(
                  clouds.last.worldLocation.dx +
                      Random().nextInt(200) +
                      MediaQuery.of(context).size.width / worlToPixelRatio,
                  Random().nextInt(50) - 25.0,
                ),
              ),
            );
          });
        }
      }

      // 更新一下上次更新调用的时间，用于恐龙实例更新等
      lastUpdateCall = worldController.lastElapsedDuration!;
    } catch (e) {
      //
    }
  }

  @override
  Widget build(BuildContext context) {
    // 构建屏幕中出现的各个动画实例用于布局
    Size screenSize = MediaQuery.of(context).size;
    List<Widget> children = [];

    for (GameObject object in [...clouds, ...ground, ...cacti, dino]) {
      children.add(
        AnimatedBuilder(
          animation: worldController,
          builder: (context, _) {
            Rect objectRect = object.getRect(screenSize, runDistance);
            return Positioned(
              left: objectRect.left,
              top: objectRect.top,
              width: objectRect.width,
              height: objectRect.height,
              child: object.render(),
            );
          },
        ),
      );
    }

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 5000),
        color: (runDistance ~/ dayNightOffest) % 2 == 0
            ? Colors.white
            : Colors.black,
        child: GestureDetector(
          // 命中测试行为，恐龙与障碍物有碰撞，游戏结束；如果没有，就让恐龙跳跃
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (dino.state != DinoState.dead) {
              dino.jump();
            }
            if (dino.state == DinoState.dead) {
              _newGame();
            }
          },
          // 构建页面上的各个游戏图像实例和其他分数、设置、结束按钮等组件
          child: Stack(
            alignment: Alignment.center,
            children: [
              ...children,
              AnimatedBuilder(
                animation: worldController,
                builder: (context, _) {
                  return Positioned(
                    left: screenSize.width / 2 - 50,
                    top: 100,
                    child: Text(
                      '当前得分: ${runDistance.toInt()}',
                      style: TextStyle(
                        color: (runDistance ~/ dayNightOffest) % 2 == 0
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: worldController,
                builder: (context, _) {
                  return Positioned(
                    left: screenSize.width / 2 - 50,
                    top: 120,
                    child: Text(
                      '历史最高: $highScore',
                      style: TextStyle(
                        color: (runDistance ~/ dayNightOffest) % 2 == 0
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                right: 20,
                top: 20,
                child: IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    _die();
                    _buildSettingDialog();
                  },
                ),
              ),
              // 2024-02-02 这里有个问题，游戏还没开始，状态也是dead，不知道是未开始还是游戏结束
              // 还是按照原来的，停止了，就是游戏结束了，不用显示文字
              // if (dino.state == DinoState.dead)
              //   Positioned(
              //     top: screenSize.height / 2 - 100,
              //     child: const Text(
              //       "游戏结束",
              //       style: TextStyle(color: Colors.red, fontSize: 28),
              //     ),
              //   ),
              Positioned(
                bottom: 10,
                child: TextButton(
                  onPressed: () {
                    _die();
                  },
                  child: const Text(
                    "强制结束游戏",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _buildSettingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("修改设定"),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                _buildPadding("重力:", gravityController),
                _buildPadding("加速度:", accelerationController),
                _buildPadding("初速度:", runVelocityController),
                _buildPadding("跳跃速度:", jumpVelocityController),
                _buildPadding("昼夜偏移:", dayNightOffestController),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                gravity = int.parse(gravityController.text);
                acceleration = double.parse(accelerationController.text);
                initialVelocity = double.parse(runVelocityController.text);
                jumpVelocity = double.parse(jumpVelocityController.text);
                dayNightOffest = int.parse(dayNightOffestController.text);
                Navigator.of(context).pop();
              },
              child: const Text("完成"),
            )
          ],
        );
      },
    );
  }

  _buildPadding(String text, TextEditingController? controller) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text),
          SizedBox(
            height: 25,
            width: 75,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 这是原版的设定弹窗内容，上面是有一些修改
  originalSettingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Change Physics"),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 25,
                width: 280,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Gravity:"),
                    SizedBox(
                      height: 25,
                      width: 75,
                      child: TextField(
                        controller: gravityController,
                        key: UniqueKey(),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 25,
                width: 280,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Acceleration:"),
                    SizedBox(
                      height: 25,
                      width: 75,
                      child: TextField(
                        controller: accelerationController,
                        key: UniqueKey(),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 25,
                width: 280,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Initial Velocity:"),
                    SizedBox(
                      height: 25,
                      width: 75,
                      child: TextField(
                        controller: runVelocityController,
                        key: UniqueKey(),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 25,
                width: 280,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Jump Velocity:"),
                    SizedBox(
                      height: 25,
                      width: 75,
                      child: TextField(
                        controller: jumpVelocityController,
                        key: UniqueKey(),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 25,
                width: 280,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Day-Night Offset:"),
                    SizedBox(
                      height: 25,
                      width: 75,
                      child: TextField(
                        controller: dayNightOffestController,
                        key: UniqueKey(),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                gravity = int.parse(gravityController.text);
                acceleration = double.parse(accelerationController.text);
                initialVelocity = double.parse(runVelocityController.text);
                jumpVelocity = double.parse(jumpVelocityController.text);
                dayNightOffest = int.parse(dayNightOffestController.text);
                Navigator.of(context).pop();
              },
              child: const Text(
                "Done",
                style: TextStyle(color: Colors.grey),
              ),
            )
          ],
        );
      },
    );
  }
}
