import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sound_provider.dart';
import '../widgets/svg_icon.dart';
import '../widgets/cupertino_slider.dart';
import '../theme/serenity_theme.dart';

class MixerPanel extends ConsumerWidget {
  const MixerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sounds = ref.watch(soundListProvider);
    final activeIds = ref.watch(activeSoundsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: SerenityTheme.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(SerenityTheme.radiusXLarge),
        ),
      ),
      child: Column(
        children: [
          // iOS-style drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: SerenityTheme.tertiaryText,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('混音器', style: SerenityTheme.title2),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: SerenityTheme.tertiaryBackground,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.xmark,
                      color: SerenityTheme.secondaryText,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Sound list
          Expanded(
            child: ReorderableListView.builder(
              itemCount: sounds.length,
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              // 拖动时的视觉效果
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    final elevationValue = Tween<double>(begin: 0, end: 8).animate(animation).value;
                    return Material(
                      elevation: elevationValue,
                      color: SerenityTheme.secondaryBackground,
                      borderRadius: BorderRadius.circular(SerenityTheme.radiusMedium),
                      shadowColor: Colors.black26,
                      child: child,
                    );
                  },
                  child: child,
                );
              },
              onReorder: (oldIndex, newIndex) {
                HapticFeedback.lightImpact();
                ref.read(soundListProvider.notifier).reorder(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final sound = sounds[index];
                final isActive = activeIds.contains(sound.id);
                final themeColor = Color(int.parse(sound.themeColor.replaceAll('#', '0xFF')));

                return Container(
                  key: ValueKey(sound.id),
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: isActive 
                        ? SerenityTheme.secondaryBackground 
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(SerenityTheme.radiusMedium),
                  ),
                  child: Column(
                    children: [
                      // Sound row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isActive 
                                    ? themeColor.withOpacity(0.15)
                                    : SerenityTheme.tertiaryBackground,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: SvgIcon(
                                  path: sound.svgPath,
                                  width: 20,
                                  height: 20,
                                  colorFilter: ColorFilter.mode(
                                    isActive ? themeColor : SerenityTheme.tertiaryText,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 12),
                            
                            // Name
                            Expanded(
                              child: Text(
                                sound.name,
                                style: SerenityTheme.body.copyWith(
                                  color: isActive 
                                      ? SerenityTheme.primaryText 
                                      : SerenityTheme.secondaryText,
                                ),
                              ),
                            ),
                            
                            // Play/Pause button
                            CupertinoButton(
                              padding: const EdgeInsets.all(8),
                              minSize: 0,
                              onPressed: () => ref.read(activeSoundsProvider.notifier).toggle(sound),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isActive 
                                      ? themeColor.withOpacity(0.2) 
                                      : SerenityTheme.tertiaryBackground,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isActive 
                                      ? CupertinoIcons.pause_fill 
                                      : CupertinoIcons.play_fill,
                                  color: isActive ? themeColor : SerenityTheme.tertiaryText,
                                  size: 16,
                                ),
                              ),
                            ),
                            
                            // Drag handle（带长按视觉反馈）
                            _DragHandle(index: index),
                          ],
                        ),
                      ),
                      
                      // Volume slider (when active)
                      if (isActive)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(68, 0, 16, 12),
                          child: CupertinoVolumeSlider(
                            value: sound.volume,
                            activeColor: themeColor,
                            showValue: true,
                            onChanged: (val) {
                              ref.read(soundListProvider.notifier).updateVolume(sound.id, val);
                              ref.read(activeSoundsProvider.notifier).updateVolume(sound.id, val);
                            },
                          ),
                        ),
                      
                      // Separator (only between items)
                      if (index < sounds.length - 1 && !isActive)
                        Container(
                          margin: const EdgeInsets.only(left: 68),
                          height: 0.5,
                          color: SerenityTheme.separator,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 带有触摸视觉反馈的拖动手柄
class _DragHandle extends StatefulWidget {
  final int index;
  
  const _DragHandle({required this.index});
  
  @override
  State<_DragHandle> createState() => _DragHandleState();
}

class _DragHandleState extends State<_DragHandle> {
  bool _isPressed = false;
  
  @override
  Widget build(BuildContext context) {
    return ReorderableDragStartListener(
      index: widget.index,
      // 使用 Listener 而不是 GestureDetector，避免手势冲突
      child: Listener(
        onPointerDown: (_) {
          HapticFeedback.selectionClick();
          setState(() => _isPressed = true);
        },
        onPointerUp: (_) {
          setState(() => _isPressed = false);
        },
        onPointerCancel: (_) {
          setState(() => _isPressed = false);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: AnimatedScale(
            scale: _isPressed ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _isPressed 
                    ? SerenityTheme.accent.withValues(alpha: 0.3)
                    : SerenityTheme.tertiaryBackground,
                borderRadius: BorderRadius.circular(8),
                border: _isPressed 
                    ? Border.all(color: SerenityTheme.accent, width: 1.5)
                    : null,
              ),
              child: Icon(
                CupertinoIcons.line_horizontal_3,
                color: _isPressed 
                    ? SerenityTheme.accent 
                    : SerenityTheme.secondaryText,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
