import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sound_effect.dart';
import '../providers/sound_provider.dart';
import '../services/remote_source_service.dart';
import '../services/asset_cache_service.dart';
import '../widgets/svg_icon.dart';

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
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '设置',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  letterSpacing: 2,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white38),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 32),

          // 远程音效包
          const Text(
            '远程音效包',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white54,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),

          // 添加按钮
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _showAddSourceDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('添加音效包'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white54,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // 加载状态
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _loadingMessage ?? '加载中...',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),

          // 远程音效列表
          Expanded(
            child: remoteSounds.isEmpty
                ? const Center(
                    child: Text(
                      '暂无远程音效',
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  )
                : ListView.separated(
                    itemCount: remoteSounds.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.white10),
                    itemBuilder: (context, index) {
                      final sound = remoteSounds[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: SizedBox(
                          width: 40,
                          height: 40,
                          child: Center(
                            child: SvgIcon(
                              path: sound.svgPath,
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn),
                            ),
                          ),
                        ),
                        title: Text(
                          sound.name,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () => _deleteSound(sound),
                        ),
                      );
                    },
                  ),
          ),

          const Divider(color: Colors.white10, height: 32),

          // 缓存信息
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '缓存大小',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cacheService.formatCacheSize(_cacheSize),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _clearAllRemoteSounds,
                icon: const Icon(Icons.delete_forever_outlined, size: 18),
                label: const Text('清空所有远程音效'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已移除 ${sound.name}'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAddSourceDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        title: const Text(
          '添加音效包',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: '输入配置文件 URL',
                hintStyle: TextStyle(color: Colors.white24),
                prefixIcon: Icon(Icons.link, color: Colors.white24, size: 18),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '支持 JSON 格式的音效配置文件',
              style: TextStyle(color: Colors.white24, fontSize: 10),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: result.hasFailures
                ? Colors.orange.withOpacity(0.8)
                : const Color(0xFF38f9d7).withOpacity(0.8),
          ),
        );
      } else {
        // 完全失败
        if (result.hasFailures) {
          _showFailureDialog(result.failed);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? '加载失败'),
            backgroundColor: Colors.redAccent.withOpacity(0.8),
          ),
        );
      }
      
      // 刷新缓存大小
      await _loadCacheSize();
    } catch (e) {
      if (mounted) Navigator.pop(context); // 确保关闭 dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发生错误: $e'),
            backgroundColor: Colors.redAccent.withOpacity(0.8),
          ),
        );
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        title: const Text('确认清空？', style: TextStyle(color: Colors.white70)),
        content: const Text(
          '这将删除所有已下载的远程音效和音效包。\n保存的场景中相关的音效也会被移除。',
          style: TextStyle(color: Colors.white38),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清空', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(remoteSourceServiceProvider.notifier).clearAllRemoteSources();
    await _loadCacheSize();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('所有远程音效数据已清空')),
      );
    }
  }
}
