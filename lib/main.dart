import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'models/sound_effect.dart';
import 'providers/sound_provider.dart';
import 'services/audio_handler.dart';
import 'services/storage_service.dart';
import 'screens/mixer_panel.dart';
import 'screens/timer_panel.dart';
import 'widgets/breathing_logo.dart';
import 'widgets/control_buttons.dart';
import 'widgets/scene_widgets.dart';

late SerenityAudioHandler _handler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  await storageService.init();

  _handler = await AudioService.init(
    builder: () => SerenityAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.serenity.sound.channel.audio',
      androidNotificationChannelName: 'Serenity Sound Playback',
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
        audioHandlerProvider.overrideWithValue(_handler),
      ],
      child: const SerenityApp(),
    ),
  );
}

class SerenityApp extends StatelessWidget {
  const SerenityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Serenity Sound',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late Timer _timer;
  String _timeString = "";

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
    // 初始化默认选中场景
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(initActiveSceneProvider);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    final String formattedTime = DateFormat('HH:mm').format(DateTime.now());
    if (mounted) {
      setState(() {
        _timeString = formattedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sounds = ref.watch(soundListProvider);
    final activeIds = ref.watch(activeSoundsProvider);
    final scenes = ref.watch(sceneProvider);
    final isGlobalPlaying = ref.watch(isGlobalPlayingProvider).value ?? false;
    final timerState = ref.watch(timerProvider);
    final top12 = sounds.take(12).toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF161616),
              Color(0xFF050505),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 场景选择器
              const SizedBox(height: 20),
              SizedBox(
                height: 40,
                child: ReorderableListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  buildDefaultDragHandles: false,
                  onReorder: (oldIndex, newIndex) {
                    ref.read(sceneProvider.notifier).reorderScenes(oldIndex, newIndex);
                  },
                  itemCount: scenes.length + 1,
                  itemBuilder: (context, index) {
                    if (index == scenes.length) {
                      return const KeyedSubtree(
                        key: ValueKey('add_button'),
                        child: AddSceneButton(),
                      );
                    }
                    final scene = scenes[index];
                    final sceneColor = Color(int.parse(scene.color.replaceAll('#', '0xFF')));
                    final activeSceneId = ref.watch(activeSceneProvider);
                    final isSelected = activeSceneId == scene.id;
                    return KeyedSubtree(
                      key: ValueKey(scene.id),
                      child: ReorderableDragStartListener(
                        index: index,
                        child: GestureDetector(
                          onTap: () {
                            ref.read(activeSceneProvider.notifier).state = scene.id;
                            ref.read(activeSoundsProvider.notifier).applyScene(scene);
                            ref.read(activeSoundsProvider.notifier).cleanupNonTop12();
                          },
                          onDoubleTap: () => _showRenameDialog(context, ref, scene),
                          onLongPress: () => _confirmDeleteScene(context, ref, scene),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? sceneColor.withOpacity(0.15) 
                                  : Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? sceneColor : Colors.white10, 
                                width: isSelected ? 1.5 : 0.5,
                              ),
                              boxShadow: isSelected ? [
                                BoxShadow(color: sceneColor.withOpacity(0.3), blurRadius: 8),
                              ] : [],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: sceneColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: sceneColor.withOpacity(0.5), blurRadius: 4)],
                                  ),
                                ),
                                Text(
                                  scene.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10, 
                                    letterSpacing: 2, 
                                    color: isSelected ? Colors.white70 : Colors.white38,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 1. 顶部：复古数字显示屏
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onDoubleTap: () => isGlobalPlaying ? _handler.pause() : _handler.play(),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                EndingFlicker(
                                  isEnding: timerState.isEnding,
                                  child: Text(
                                    (timerState.isRunning || timerState.isEnding) ? timerState.formattedTime : _timeString,
                                    style: TextStyle(
                                      fontSize: 100,
                                      fontWeight: FontWeight.w200,
                                      letterSpacing: -4,
                                      color: Colors.white.withOpacity(0.3),
                                      shadows: [
                                        Shadow(color: Colors.white.withOpacity(0.6), blurRadius: 50),
                                      ],
                                    ),
                                  ),
                                ),
                                EndingFlicker(
                                  isEnding: timerState.isEnding,
                                  child: Text(
                                    (timerState.isRunning || timerState.isEnding) ? timerState.formattedTime : _timeString,
                                    style: const TextStyle(
                                      fontSize: 100,
                                      fontWeight: FontWeight.w200,
                                      letterSpacing: -4,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              timerState.isEnding
                                  ? 'TIMER FINISHED'
                                  : (timerState.isRunning ? 'SLEEP TIMER ACTIVE' : 'STAY FOCUSED'),
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 5,
                                color: (timerState.isRunning || timerState.isEnding) 
                                    ? Colors.orangeAccent.withOpacity(0.7) 
                                    : Colors.white54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // 2. 中部：控制网格
              Expanded(
                flex: 7,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    padding: const EdgeInsets.only(top: 10),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: top12.length,
                    itemBuilder: (context, index) {
                      final sound = top12[index];
                      final isActive = activeIds.contains(sound.id);
                      
                      return GestureDetector(
                        onTap: () => ref.read(activeSoundsProvider.notifier).toggle(sound),
                        child: Column(
                          children: [
                            BreathingLogo(
                              svgPath: sound.svgPath,
                              glowColor: Color(int.parse(sound.themeColor.replaceAll('#', '0xFF'))),
                              isBreathing: isGlobalPlaying && isActive,
                              isActive: isActive,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              sound.name.toUpperCase(),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isActive ? Colors.white : Colors.white24,
                                fontSize: 8,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 3. 底部：控制仪表盘
              Padding(
                padding: const EdgeInsets.only(bottom: 50, left: 50, right: 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ControlKnob(
                      icon: Icons.grid_view_rounded,
                      onPressed: () => _showMixerPanel(context),
                    ),
                    MasterButton(
                      isPlaying: isGlobalPlaying,
                      onPressed: () => isGlobalPlaying ? _handler.pause() : _handler.play(),
                    ),
                    ControlKnob(
                      icon: Icons.hourglass_empty_rounded,
                      onPressed: () => _showTimerPanel(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTimerPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF080808),
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.97),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
      ),
      builder: (context) => const TimerPanel(),
    );
  }

  void _confirmDeleteScene(BuildContext context, WidgetRef ref, SoundScene scene) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        title: const Text('删除场景', style: TextStyle(color: Colors.white70, fontSize: 16)),
        content: Text('确定要删除 "${scene.name}" 吗？', style: const TextStyle(color: Colors.white38)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              ref.read(sceneProvider.notifier).deleteScene(scene.id);
              Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, SoundScene scene) {
    final controller = TextEditingController(text: scene.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        title: const Text('编辑场景', style: TextStyle(color: Colors.white70, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: '输入场景名称',
                hintStyle: TextStyle(color: Colors.white24),
              ),
            ),
            const SizedBox(height: 16),
            // 覆盖保存按钮
            TextButton.icon(
              onPressed: () {
                ref.read(sceneProvider.notifier).updateScene(scene.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('已保存到 "${scene.name}"'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: const Color(0xFF38f9d7).withOpacity(0.8),
                  ),
                );
              },
              icon: const Icon(Icons.save_rounded, size: 16, color: Colors.white54),
              label: const Text('覆盖保存当前配置', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                ref.read(sceneProvider.notifier).renameScene(scene.id, newName);
              }
              Navigator.pop(context);
            },
            child: const Text('保存名称'),
          ),
        ],
      ),
    );
  }

  void _showMixerPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.97),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
      ),
      builder: (context) => const MixerPanel(),
    ).then((_) {
      ref.read(activeSoundsProvider.notifier).cleanupNonTop12();
    });
  }
}