import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/sound_effect.dart';
import '../providers/sound_provider.dart';
import '../services/audio_handler.dart';
import '../widgets/breathing_logo.dart';
import '../widgets/control_buttons.dart';
import '../widgets/scene_widgets.dart';
import '../widgets/toast.dart';
import '../theme/serenity_theme.dart';
import 'mixer_panel.dart';
import 'timer_panel.dart';
import 'settings_page.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late Timer _timer;
  String _timeString = "";
  late AnimationController _colonAnimController;
  late Animation<double> _colonOpacity;

  @override
  void initState() {
    super.initState();
    _colonAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _colonOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _colonAnimController, curve: Curves.easeInOut),
    );
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
  }

  @override
  void dispose() {
    _timer.cancel();
    _colonAnimController.dispose();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    final String formattedTime = DateFormat('HH:mm').format(now);
    if (mounted) {
      setState(() {
        _timeString = formattedTime;
      });
      // 切换动画方向
      if (_colonAnimController.isCompleted) {
        _colonAnimController.reverse();
      } else {
        _colonAnimController.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final handler = ref.watch(audioHandlerProvider);
    final sounds = ref.watch(soundListProvider);
    final activeIds = ref.watch(activeSoundsProvider);
    final scenes = ref.watch(sceneProvider);
    final isGlobalPlaying = ref.watch(isGlobalPlayingProvider).value ?? false;
    final timerState = ref.watch(timerProvider);
    final top12 = sounds.take(12).toList();
    final hasSceneChanges = ref.watch(hasSceneChangesProvider);
    final activeSceneId = ref.watch(activeSceneProvider);

    return Scaffold(
      backgroundColor: SerenityTheme.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              SerenityTheme.secondaryBackground,
              SerenityTheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // 场景选择器（排序功能移至场景管理页）
                  const SizedBox(height: 20),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  itemCount: scenes.length + 1,
                  itemBuilder: (context, index) {
                    if (index == scenes.length) {
                      return const AddSceneButton();
                    }
                    final scene = scenes[index];
                    final sceneColor = Color(int.parse(scene.color.replaceAll('#', '0xFF')));
                    final activeSceneId = ref.watch(activeSceneProvider);
                    final isSelected = activeSceneId == scene.id;
                    return GestureDetector(
                      onTap: () {
                        final currentActiveId = ref.read(activeSceneProvider);
                        
                        if (isSelected) {
                          // 取消选中：恢复未选中时的排序和音量，并停止播放
                          ref.read(activeSceneProvider.notifier).state = null;
                          ref.read(originalSceneSnapshotProvider.notifier).state = SceneSnapshot.empty();
                          
                          // 恢复排序
                          final unselectedOrder = ref.read(unselectedSoundOrderProvider);
                          if (unselectedOrder.isNotEmpty) {
                            ref.read(soundListProvider.notifier).applyOrder(unselectedOrder);
                          }
                          
                          // 恢复音量
                          final unselectedVolumes = ref.read(unselectedSoundVolumesProvider);
                          if (unselectedVolumes.isNotEmpty) {
                            ref.read(soundListProvider.notifier).applyVolumes(unselectedVolumes);
                          }
                          
                          ref.read(activeSoundsProvider.notifier).stopAll();
                        } else {
                          // 如果从未选中状态切换到选中，先保存当前排序和音量
                          if (currentActiveId == null) {
                            final sounds = ref.read(soundListProvider);
                            final currentOrder = sounds.map((s) => s.id).toList();
                            final currentVolumes = {for (final s in sounds) s.id: s.volume};
                            ref.read(unselectedSoundOrderProvider.notifier).state = currentOrder;
                            ref.read(unselectedSoundVolumesProvider.notifier).state = currentVolumes;
                          }
                          // 选中：应用场景并记录原始配置
                          ref.read(activeSceneProvider.notifier).state = scene.id;
                          ref.read(activeSoundsProvider.notifier).applyScene(scene);
                          ref.read(activeSoundsProvider.notifier).cleanupNonTop12();
                          // 记录原始场景快照（配置+排序）
                          ref.read(originalSceneSnapshotProvider.notifier).state = SceneSnapshot(
                            soundConfig: Map<String, double>.from(scene.soundConfig),
                            soundOrder: List<String>.from(scene.soundOrder),
                          );
                        }
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
                    );
                  },
                ),
              ),

              // 1. 顶部：复古数字显示屏
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: () => _showTimerPanel(context), // 点击显示定时器面板
                  onDoubleTap: () => isGlobalPlaying ? handler.pause() : handler.play(),
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
                                  child: _buildTimeDisplay(
                                    (timerState.isRunning || timerState.isEnding) ? timerState.formattedTime : _timeString,
                                    TextStyle(
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
                                  child: _buildTimeDisplay(
                                    (timerState.isRunning || timerState.isEnding) ? timerState.formattedTime : _timeString,
                                    const TextStyle(
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
                            // 保存按钮（有修改时显示）
                            if (hasSceneChanges && activeSceneId != null) ...[
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () {
                                  ref.read(sceneProvider.notifier).updateScene(activeSceneId);
                                  // 保存后更新快照为当前状态
                                  final allSounds = ref.read(soundListProvider);
                                  final activeIds = ref.read(activeSoundsProvider);
                                  final config = <String, double>{};
                                  for (final id in activeIds) {
                                    final sound = allSounds.firstWhere((s) => s.id == id);
                                    config[id] = sound.volume;
                                  }
                                  ref.read(originalSceneSnapshotProvider.notifier).state = SceneSnapshot(
                                    soundConfig: config,
                                    soundOrder: allSounds.map((s) => s.id).toList(),
                                  );
                                  showToast(context, '场景已保存');
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        CupertinoIcons.arrow_down_doc,
                                        color: Colors.white38,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        '保存场景',
                                        style: TextStyle(
                                          fontSize: 10,
                                          letterSpacing: 1,
                                          color: Colors.white38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
                padding: const EdgeInsets.only(bottom: 50, left: 30, right: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ControlKnob(
                      icon: CupertinoIcons.slider_horizontal_3,
                      onPressed: () => _showMixerPanel(context),
                    ),
                    MasterButton(
                      isPlaying: isGlobalPlaying,
                      onPressed: () => isGlobalPlaying ? handler.pause() : handler.play(),
                    ),
                    ControlKnob(
                      icon: CupertinoIcons.gear,
                      onPressed: () => _showSettingsPanel(context),
                    ),
                  ],
                ),
              ),
            ],
          ), // End of Column
        ], // End of Stack children
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

  // 构建带渐变冒号的时间显示
  Widget _buildTimeDisplay(String time, TextStyle style) {
    final parts = time.split(':');
    if (parts.length != 2) return Text(time, style: style);
    
    return AnimatedBuilder(
      animation: _colonOpacity,
      builder: (context, child) {
        final colonStyle = style.copyWith(
          color: (style.color ?? Colors.white).withOpacity(_colonOpacity.value),
        );
        return RichText(
          text: TextSpan(
            style: style,
            children: [
              TextSpan(text: parts[0]),
              TextSpan(text: ':', style: colonStyle),
              TextSpan(text: parts[1]),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteScene(BuildContext context, WidgetRef ref, SoundScene scene) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('删除场景'),
        content: Text('确定要删除 "${scene.name}" 吗？'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              ref.read(sceneProvider.notifier).deleteScene(scene.id);
              Navigator.pop(context);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, SoundScene scene) {
    final controller = TextEditingController(text: scene.name);
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('重命名场景'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            placeholder: '输入新名称',
            placeholderStyle: TextStyle(color: CupertinoColors.systemGrey),
            style: const TextStyle(color: CupertinoColors.white),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.darkBackgroundGray,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                ref.read(sceneProvider.notifier).renameScene(scene.id, newName);
              }
              Navigator.pop(context);
            },
            child: const Text('保存'),
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
      // 排序变更不再自动保存到场景，需用户手动点击保存按钮
    });
  }

  void _showSettingsPanel(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const SettingsPage()),
    );
  }
}
