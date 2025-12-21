import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sound_effect.dart';
import '../providers/sound_provider.dart';
import '../services/remote_source_service.dart';
import '../services/asset_cache_service.dart';
import '../widgets/svg_icon.dart';
import '../widgets/toast.dart';
import '../theme/serenity_theme.dart';

class SoundManagementPage extends ConsumerStatefulWidget {
  const SoundManagementPage({super.key});

  @override
  ConsumerState<SoundManagementPage> createState() => _SoundManagementPageState();
}

class _SoundManagementPageState extends ConsumerState<SoundManagementPage> {
  @override
  Widget build(BuildContext context) {
    final allSounds = ref.watch(soundListProvider);
    final remoteSounds = allSounds.where((s) => s.isRemote).toList();

    return CupertinoPageScaffold(
      backgroundColor: SerenityTheme.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: SerenityTheme.background.withOpacity(0.9),
        border: null,
        middle: const Text('音效管理'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: _showAddSourceDialog,
        ),
      ),
      child: SafeArea(
        child: remoteSounds.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.music_note_list,
                      size: 48,
                      color: SerenityTheme.tertiaryText,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无远程音效',
                      style: SerenityTheme.subheadline,
                    ),
                    const SizedBox(height: 8),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _showAddSourceDialog,
                      child: Text(
                        '添加音效包',
                        style: SerenityTheme.body.copyWith(color: SerenityTheme.accent),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: remoteSounds.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${remoteSounds.length} 个远程音效',
                        style: SerenityTheme.caption1,
                      ),
                    );
                  }
                  
                  final sound = remoteSounds[index - 1];
                  final isLast = index == remoteSounds.length;
                  
                  return Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: SerenityTheme.secondaryBackground,
                          borderRadius: BorderRadius.vertical(
                            top: index == 1 ? const Radius.circular(12) : Radius.zero,
                            bottom: isLast ? const Radius.circular(12) : Radius.zero,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: SerenityTheme.tertiaryBackground,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: SvgIcon(
                                    path: sound.svgPath,
                                    width: 20,
                                    height: 20,
                                    colorFilter: const ColorFilter.mode(
                                      SerenityTheme.secondaryText,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(sound.name, style: SerenityTheme.body),
                              ),
                              CupertinoButton(
                                padding: const EdgeInsets.all(8),
                                minSize: 0,
                                onPressed: () => _deleteSound(sound),
                                child: const Icon(
                                  CupertinoIcons.minus_circle_fill,
                                  color: SerenityTheme.systemRed,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!isLast)
                        Container(
                          color: SerenityTheme.secondaryBackground,
                          child: Container(
                            margin: const EdgeInsets.only(left: 68),
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

  void _deleteSound(SoundEffect sound) async {
    if (sound.sourceId == null) {
      await ref.read(assetCacheServiceProvider).deleteSourceCache([sound.id]);
      ref.read(soundListProvider.notifier).removeRemoteSounds([sound.id]);
    } else {
      await ref.read(remoteSourceServiceProvider.notifier).removeSoundFromSource(sound.sourceId!, sound.id);
    }
    
    if (mounted) {
      showToast(context, '已移除 ${sound.name}');
    }
  }

  void _showAddSourceDialog() {
    final controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('添加音效包'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoTextField(
                controller: controller,
                autofocus: true,
                placeholder: '输入配置文件 URL',
                placeholderStyle: TextStyle(color: CupertinoColors.systemGrey),
                style: const TextStyle(color: CupertinoColors.white),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.darkBackgroundGray,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '支持 JSON 格式的音效配置文件',
                style: SerenityTheme.caption1,
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
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                Navigator.pop(context);
                _addSource(url);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  Future<void> _addSource(String url) async {
    final progressNotifier = ValueNotifier<String>('准备下载...');
    
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CupertinoActivityIndicator(radius: 14),
              const SizedBox(height: 16),
              ValueListenableBuilder<String>(
                valueListenable: progressNotifier,
                builder: (context, value, child) {
                  return Text(value, textAlign: TextAlign.center);
                },
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final result = await ref.read(remoteSourceServiceProvider.notifier).addSource(
        url,
        onProgress: (message) => progressNotifier.value = message,
      );

      if (mounted) Navigator.pop(context);

      if (!mounted) return;

      if (result.isSuccess) {
        String message = '成功添加 ${result.added.length} 个音效';
        if (result.hasConflicts) message += '\n跳过 ${result.skipped.length} 个冲突音效';
        if (result.hasFailures) {
          message += '\n${result.failed.length} 个音效下载失败';
          _showFailureDialog(result.failed);
        }
        showToast(context, message, isError: result.hasFailures);
      } else {
        if (result.hasFailures) {
          _showFailureDialog(result.failed);
        }
        showToast(context, result.error ?? '加载失败', isError: true);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) showToast(context, '发生错误: $e', isError: true);
    }
  }

  void _showFailureDialog(Map<String, String> failures) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.exclamationmark_triangle, color: Colors.orangeAccent, size: 20),
            const SizedBox(width: 8),
            const Text('下载未完成'),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '以下 ${failures.length} 个音效下载失败：',
                style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel),
              ),
              const SizedBox(height: 12),
              ...failures.entries.take(10).map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      entry.value,
                      style: TextStyle(fontSize: 11, color: CupertinoColors.systemGrey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              )),
              if (failures.length > 10)
                Text(
                  '还有 ${failures.length - 10} 个...',
                  style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('了解'),
          ),
        ],
      ),
    );
  }
}
