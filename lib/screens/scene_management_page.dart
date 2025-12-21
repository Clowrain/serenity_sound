import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sound_effect.dart';
import '../providers/sound_provider.dart';
import '../widgets/toast.dart';
import '../theme/serenity_theme.dart';

class SceneManagementPage extends ConsumerWidget {
  const SceneManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenes = ref.watch(sceneProvider);

    return CupertinoPageScaffold(
      backgroundColor: SerenityTheme.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: SerenityTheme.background.withOpacity(0.9),
        border: null,
        middle: const Text('场景管理'),
      ),
      child: SafeArea(
        child: scenes.isEmpty
            ? Center(
                child: Text(
                  '暂无场景',
                  style: SerenityTheme.subheadline,
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: scenes.length + 1, // +1 for header
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${scenes.length} 个场景',
                        style: SerenityTheme.caption1,
                      ),
                    );
                  }
                  
                  final scene = scenes[index - 1];
                  final sceneColor = Color(int.parse(scene.color.replaceAll('#', '0xFF')));
                  final isLast = index == scenes.length;
                  
                  return Column(
                    children: [
                      if (index == 1)
                        Container(
                          decoration: BoxDecoration(
                            color: SerenityTheme.secondaryBackground,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          ),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          color: SerenityTheme.secondaryBackground,
                          borderRadius: BorderRadius.vertical(
                            top: index == 1 ? const Radius.circular(12) : Radius.zero,
                            bottom: isLast ? const Radius.circular(12) : Radius.zero,
                          ),
                        ),
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _showSceneActions(context, ref, scene),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: sceneColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: sceneColor,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(color: sceneColor.withOpacity(0.5), blurRadius: 4),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(scene.name, style: SerenityTheme.body),
                                      Text(
                                        '${scene.soundConfig.length} 个音效',
                                        style: SerenityTheme.caption1,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  CupertinoIcons.chevron_right,
                                  color: SerenityTheme.tertiaryText,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (!isLast)
                        Container(
                          color: SerenityTheme.secondaryBackground,
                          child: Container(
                            margin: const EdgeInsets.only(left: 64),
                            height: 0.5,
                            color: SerenityTheme.separator,
                          ),
                        ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  void _showSceneActions(BuildContext context, WidgetRef ref, SoundScene scene) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(scene.name),
        message: Text('${scene.soundConfig.length} 个音效配置'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showRenameDialog(context, ref, scene);
            },
            child: const Text('重命名'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _confirmDelete(context, ref, scene);
            },
            child: const Text('删除'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
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

  void _confirmDelete(BuildContext context, WidgetRef ref, SoundScene scene) {
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
}
