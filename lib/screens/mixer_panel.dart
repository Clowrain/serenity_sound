import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/sound_provider.dart';

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
              buildDefaultDragHandles: false,
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
