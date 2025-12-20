import 'dart:async';
import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'models/sound_effect.dart';
import 'providers/sound_provider.dart';
import 'services/audio_handler.dart';
import 'services/storage_service.dart';
import 'widgets/breathing_logo.dart';

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
    final scenes = ref.watch(sceneProvider); // 监听场景
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
              // 场景选择器 (新增)
              const SizedBox(height: 20),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  itemCount: scenes.length + 1,
                  itemBuilder: (context, index) {
                    if (index == scenes.length) {
                      return _AddSceneButton();
                    }
                    final scene = scenes[index];
                    return GestureDetector(
                      onTap: () => ref.read(activeSoundsProvider.notifier).applyScene(scene.soundConfig, sounds),
                      onLongPress: () => _confirmDeleteScene(context, ref, scene), // 新增长按监听
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10, width: 0.5),
                        ),
                        child: Text(
                          scene.name.toUpperCase(),
                          style: const TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.white38),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 1. 顶部：复古数字显示屏
              Expanded(
                flex: 3, // 稍微增加一点占比
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
                                _EndingFlicker(
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
                                _EndingFlicker(
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
                      childAspectRatio: 0.8,
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
                    _ControlKnob(
                      icon: Icons.grid_view_rounded,
                      onPressed: () => _showMixerPanel(context),
                    ),
                    _MasterButton(
                      isPlaying: isGlobalPlaying,
                      onPressed: () => isGlobalPlaying ? _handler.pause() : _handler.play(),
                    ),
                    _ControlKnob(
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
    );
  }
}

class _ControlKnob extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ControlKnob({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 24, color: Colors.white60),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        padding: const EdgeInsets.all(16),
        side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
        backgroundColor: Colors.white.withOpacity(0.05),
      ),
    );
  }
}

class _MasterButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPressed;

  const _MasterButton({required this.isPlaying, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: 85,
        height: 85,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isPlaying ? Colors.white : Colors.white24,
            width: 2,
          ),
          boxShadow: isPlaying ? [
            BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 30, spreadRadius: 5)
          ] : [],
        ),
        child: Center(
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 45,
            color: isPlaying ? Colors.white : Colors.white60,
          ),
        ),
      ),
    );
  }
}

class MixerPanel extends ConsumerWidget {
  const MixerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sounds = ref.watch(soundListProvider);
    final activeIds = ref.watch(activeSoundsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
      child: Column(
        children: [
          Container(width: 50, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 40),
          const Text('ANALOG MIXER', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 6, color: Colors.white70)),
          const SizedBox(height: 40),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: sounds.length,
              buildDefaultDragHandles: false, // 关键：禁用默认长按手柄
              onReorder: (oldIndex, newIndex) {
                ref.read(soundListProvider.notifier).reorder(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final sound = sounds[index];
                final isActive = activeIds.contains(sound.id);

                return Column(
                  key: ValueKey(sound.id),
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isActive ? Colors.white38 : Colors.white10, width: 1),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            sound.svgPath,
                            width: 18,
                            height: 18,
                            colorFilter: ColorFilter.mode(isActive ? Colors.white : Colors.white30, BlendMode.srcIn),
                          ),
                        ),
                      ),
                      title: Text(sound.name, style: const TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 1)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. 播放/暂停按钮
                          IconButton(
                            icon: Icon(
                              isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: isActive 
                                  ? Color(int.parse(sound.themeColor.replaceAll('#', '0xFF'))) 
                                  : Colors.white24,
                              size: 28,
                            ),
                            onPressed: () => ref.read(activeSoundsProvider.notifier).toggle(sound),
                          ),
                          const SizedBox(width: 8),
                          // 2. 专用的拖拽手柄
                          ReorderableDragStartListener(
                            index: index,
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.reorder_rounded, color: Colors.white10, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isActive)
                      Padding(
                        padding: const EdgeInsets.only(left: 60, right: 16, bottom: 12),
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            activeTrackColor: Color(int.parse(sound.themeColor.replaceAll('#', '0xFF'))).withOpacity(0.5),
                            thumbColor: Colors.white,
                          ),
                          child: Slider(
                            value: sound.volume,
                            onChanged: (val) {
                              ref.read(soundListProvider.notifier).updateVolume(sound.id, val);
                              ref.read(activeSoundsProvider.notifier).updateVolume(sound.id, val);
                            },
                          ),
                        ),
                      ),
                    const Divider(color: Colors.white10, height: 1),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TimerPanel extends ConsumerStatefulWidget {
  const TimerPanel({super.key});

  @override
  ConsumerState<TimerPanel> createState() => _TimerPanelState();
}

class _TimerPanelState extends ConsumerState<TimerPanel> {
  double _currentValue = 30;

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, // 自适应高度
            children: [
              Container(width: 50, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 30),
              const Text('SLEEP TIMER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 6, color: Colors.white30)),
              const SizedBox(height: 30),
              if (timerState.isRunning)
                Column(
                  children: [
                    Text(timerState.formattedTime, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w200, color: Colors.white, letterSpacing: 2)),
                    const SizedBox(height: 30),
                    TextButton(
                      onPressed: () => ref.read(timerProvider.notifier).cancel(),
                      child: const Text('CANCEL TIMER', style: TextStyle(color: Colors.redAccent, letterSpacing: 2, fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Text('${_currentValue.toInt()} MINUTES', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w200, color: Colors.white)),
                    const SizedBox(height: 20),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                        activeTrackColor: Colors.white24,
                        inactiveTrackColor: Colors.white10,
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: _currentValue,
                        min: 1,
                        max: 240,
                        onChanged: (val) => setState(() => _currentValue = val),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _MasterButton(
                      isPlaying: false,
                      onPressed: () {
                        ref.read(timerProvider.notifier).setTimer(_currentValue.toInt());
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EndingFlicker extends StatefulWidget {
  final Widget child;
  final bool isEnding;
  const _EndingFlicker({required this.child, required this.isEnding});
  @override
  State<_EndingFlicker> createState() => _EndingFlickerState();
}

class _EndingFlickerState extends State<_EndingFlicker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    if (widget.isEnding) _controller.repeat(reverse: true);
  }
  @override
  void didUpdateWidget(_EndingFlicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEnding) { _controller.repeat(reverse: true); } else { _controller.stop(); }
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (!widget.isEnding) return widget.child;
    return FadeTransition(opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_controller), child: widget.child);
  }
}

class _AddSceneButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        final name = await _showNameDialog(context);
        if (name != null && name.isNotEmpty) {
          ref.read(sceneProvider.notifier).addCurrentAsScene(name);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: const Icon(Icons.add_circle_outline_rounded, color: Colors.white10, size: 20),
      ),
    );
  }

  Future<String?> _showNameDialog(BuildContext context) {
    String name = "";
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        title: const Text('保存场景', style: TextStyle(color: Colors.white70, fontSize: 16)),
        content: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: '输入场景名称', hintStyle: TextStyle(color: Colors.white24)),
          onChanged: (val) => name = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, name), child: const Text('保存')),
        ],
      ),
    );
  }
}