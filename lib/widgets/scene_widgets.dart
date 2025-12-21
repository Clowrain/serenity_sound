import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sound_provider.dart';
import '../theme/serenity_theme.dart';

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
        child: Icon(CupertinoIcons.add_circled, color: Colors.white24, size: 20),
      ),
    );
  }

  Future<Map<String, dynamic>?> _showSaveDialog(BuildContext context) {
    String name = "";
    String selectedColor = _presetColors[0];

    return showCupertinoDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => CupertinoAlertDialog(
          title: const Text('保存场景'),
          content: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CupertinoTextField(
                  autofocus: true,
                  placeholder: '输入场景名称',
                  placeholderStyle: TextStyle(color: CupertinoColors.systemGrey),
                  style: const TextStyle(color: CupertinoColors.white),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.darkBackgroundGray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onChanged: (val) => name = val,
                ),
                const SizedBox(height: 16),
                Text(
                  '选择颜色',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presetColors.map((color) {
                    final isSelected = color == selectedColor;
                    final colorValue = Color(int.parse(color.replaceAll('#', '0xFF')));
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: colorValue,
                          shape: BoxShape.circle,
                          border: isSelected 
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                          boxShadow: [
                            BoxShadow(color: colorValue.withOpacity(0.3), blurRadius: 4),
                          ],
                        ),
                        child: isSelected 
                            ? Icon(CupertinoIcons.checkmark, color: Colors.white, size: 14)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, {'name': name, 'color': selectedColor}),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
