import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sound_effect.dart';
import '../providers/sound_provider.dart';
import '../services/remote_source_service.dart';
import '../services/asset_cache_service.dart';
import '../widgets/svg_icon.dart';
import '../widgets/cupertino_card.dart';
import '../widgets/toast.dart';
import '../theme/serenity_theme.dart';

class SettingsPanel extends ConsumerStatefulWidget {
  const SettingsPanel({super.key});

  @override
  ConsumerState<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends ConsumerState<SettingsPanel> {
  bool _isLoading = false;
  String? _loadingMessage;
  int _cacheSize = 0;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    final cacheService = ref.read(assetCacheServiceProvider);
    final size = await cacheService.getCacheSize();
    if (mounted) {
      setState(() => _cacheSize = size);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remoteSources = ref.watch(remoteSourceServiceProvider);
    final allSounds = ref.watch(soundListProvider);
    final remoteSounds = allSounds.where((s) => s.isRemote).toList();
    final cacheService = ref.read(assetCacheServiceProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: SerenityTheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(SerenityTheme.radiusXLarge)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                Text('设置', style: SerenityTheme.title2),
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

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Remote Sounds Section
                const CupertinoSectionHeader(text: '远程音效'),
                
                CupertinoCard(
                  child: Column(
                    children: [
                      // Add button
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        onPressed: _isLoading ? null : _showAddSourceDialog,
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.add_circled,
                              color: SerenityTheme.accent,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '添加音效包',
                              style: SerenityTheme.body.copyWith(color: SerenityTheme.accent),
                            ),
                          ],
                        ),
                      ),
                      
                      // Loading indicator
                      if (_isLoading) ...[
                        Container(height: 0.5, color: SerenityTheme.separator),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const CupertinoActivityIndicator(radius: 10),
                              const SizedBox(width: 12),
                              Text(
                                _loadingMessage ?? '加载中...',
                                style: SerenityTheme.subheadline,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Sounds list
                if (remoteSounds.isNotEmpty)
                  CupertinoCard(
                    child: Column(
                      children: [
                        for (int i = 0; i < remoteSounds.length; i++) ...[
                          _buildSoundTile(remoteSounds[i]),
                          if (i < remoteSounds.length - 1)
                            Container(
                              margin: const EdgeInsets.only(left: 56),
                              height: 0.5,
                              color: SerenityTheme.separator,
                            ),
                        ],
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        '暂无远程音效',
                        style: SerenityTheme.subheadline,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 24),

                // Cache Section
                const CupertinoSectionHeader(text: '存储'),
                
                CupertinoCard(
                  child: Column(
                    children: [
                      // Cache size display
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('缓存大小', style: SerenityTheme.body),
                            Text(
                              cacheService.formatCacheSize(_cacheSize),
                              style: SerenityTheme.body.copyWith(
                                color: SerenityTheme.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(height: 0.5, color: SerenityTheme.separator),
                      // Clear all button
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        onPressed: _clearAllRemoteSounds,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '清空所有远程音效',
                              style: SerenityTheme.body.copyWith(
                                color: SerenityTheme.systemRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundTile(SoundEffect sound) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: null,
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
              child: Text(
                sound.name,
                style: SerenityTheme.body,
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.all(8),
              minSize: 0,
              onPressed: () => _deleteSound(sound),
              child: const Icon(
                CupertinoIcons.minus_circle,
                color: SerenityTheme.systemRed,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteSound(SoundEffect sound) async {
    if (sound.sourceId == null) {
      // 容错处理：没有 sourceId 的情况（旧数据？）
      // 仍然尝试清理文件并从列表中移除
      await ref.read(assetCacheServiceProvider).deleteSourceCache([sound.id]);
      ref.read(soundListProvider.notifier).removeRemoteSounds([sound.id]);
    } else {
      await ref.read(remoteSourceServiceProvider.notifier).removeSoundFromSource(sound.sourceId!, sound.id);
    }
    
    // 刷新缓存大小
    await _loadCacheSize();

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
    // 进度通知器
    final progressNotifier = ValueNotifier<String>('准备下载...');
    
    // 显示进度对话框
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            ValueListenableBuilder<String>(
              valueListenable: progressNotifier,
              builder: (context, value, child) {
                return Text(
                  value,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                );
              },
            ),
          ],
        ),
      ),
    );

    try {
      final result = await ref.read(remoteSourceServiceProvider.notifier).addSource(
        url,
        onProgress: (message) {
          progressNotifier.value = message;
        },
      );

      // 关闭进度对话框
      if (mounted) Navigator.pop(context);
      
      // 立即刷新缓存大小
      await _loadCacheSize();

      if (!mounted) return;

      if (result.isSuccess) {
        String message = '成功添加 ${result.added.length} 个音效';
        if (result.hasConflicts) {
          message += '\n跳过 ${result.skipped.length} 个冲突音效';
        }
        
        // 如果有失败的（部分成功）
        if (result.hasFailures) {
          message += '\n${result.failed.length} 个音效下载失败';
          _showFailureDialog(result.failed);
        }

        showToast(
          context, 
          message, 
          isError: result.hasFailures,
        );
      } else {
        // 完全失败
        if (result.hasFailures) {
          _showFailureDialog(result.failed);
        }
        
        showToast(
          context, 
          result.error ?? '加载失败', 
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // 确保关闭 dialog
      if (mounted) {
        showToast(context, '发生错误: $e', isError: true);
      }
    }
  }



  void _showFailureDialog(Map<String, String> failures) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        title: const Text(
          '下载未完成',
          style: TextStyle(color: Colors.orangeAccent, fontSize: 16),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '以下 ${failures.length} 个音效下载失败：',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: failures.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
                  itemBuilder: (context, index) {
                    final entry = failures.entries.elementAt(index);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entry.value,
                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('了解'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllRemoteSounds() async {
    // 显示确认对话框
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('确认清空？'),
        content: const Text(
          '这将删除所有已下载的远程音效和音效包。\n保存的场景中相关的音效也会被移除。',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(remoteSourceServiceProvider.notifier).clearAllRemoteSources();
    await _loadCacheSize();
    
    if (mounted) {
      showToast(context, '所有远程音效数据已清空');
    }
  }
}
