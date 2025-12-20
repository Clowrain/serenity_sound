import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sound_provider.dart';

/// 场景添加按钮及对话框
class AddSceneButton extends ConsumerStatefulWidget {
  const AddSceneButton({super.key});

  @override
  ConsumerState<AddSceneButton> createState() => _AddSceneButtonState();
}

class _AddSceneButtonState extends ConsumerState<AddSceneButton> {
  static const List<String> _presetColors = [
    '#38f9d7', // 青色
    '#4FACFE', // 蓝色
    '#43e97b', // 绿色
    '#fee140', // 黄色
    '#cd9cf2', // 紫色
    '#fa709a', // 粉色
    '#E2B0FF', // 淡紫
    '#ff6b6b', // 红色
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await _showSaveDialog(context);
        if (result != null && result['name'].isNotEmpty) {
          ref.read(sceneProvider.notifier).addCurrentAsScene(
            result['name'],
            color: result['color'],
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: const Icon(Icons.add_circle_outline_rounded, color: Colors.white10, size: 20),
      ),
    );
  }

  Future<Map<String, dynamic>?> _showSaveDialog(BuildContext context) {
    String name = "";
    String selectedColor = _presetColors[0];

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF161616),
          title: const Text('保存场景', style: TextStyle(color: Colors.white70, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: '输入场景名称',
                  hintStyle: TextStyle(color: Colors.white24),
                ),
                onChanged: (val) => name = val,
              ),
              const SizedBox(height: 20),
              const Text('选择颜色', style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _presetColors.map((color) {
                  final isSelected = color == selectedColor;
                  final colorValue = Color(int.parse(color.replaceAll('#', '0xFF')));
                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colorValue,
                        shape: BoxShape.circle,
                        border: isSelected 
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                        boxShadow: [BoxShadow(color: colorValue.withOpacity(0.4), blurRadius: 6)],
                      ),
                      child: isSelected 
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            TextButton(
              onPressed: () => Navigator.pop(context, {'name': name, 'color': selectedColor}),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
