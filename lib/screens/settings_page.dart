import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/asset_cache_service.dart';
import '../services/remote_source_service.dart';
import '../widgets/cupertino_card.dart';
import '../widgets/toast.dart';
import '../theme/serenity_theme.dart';
import 'scene_management_page.dart';
import 'sound_management_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
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
    final cacheService = ref.read(assetCacheServiceProvider);

    return CupertinoPageScaffold(
      backgroundColor: SerenityTheme.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: SerenityTheme.background.withOpacity(0.9),
        border: null,
        middle: const Text('设置'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // ─────────────────────────────────────────
            // 管理
            // ─────────────────────────────────────────
            const CupertinoSectionHeader(text: '管理'),
            
            CupertinoCard(
              child: Column(
                children: [
                  // 场景管理入口
                  _buildNavigationTile(
                    icon: CupertinoIcons.collections,
                    iconColor: CupertinoColors.systemPurple,
                    title: '场景管理',
                    onTap: () => Navigator.push(
                      context,
                      CupertinoPageRoute(builder: (_) => const SceneManagementPage()),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 56),
                    height: 0.5,
                    color: SerenityTheme.separator,
                  ),
                  // 音效管理入口
                  _buildNavigationTile(
                    icon: CupertinoIcons.music_note_list,
                    iconColor: CupertinoColors.systemBlue,
                    title: '音效管理',
                    onTap: () => Navigator.push(
                      context,
                      CupertinoPageRoute(builder: (_) => const SoundManagementPage()),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─────────────────────────────────────────
            // 存储
            // ─────────────────────────────────────────
            const CupertinoSectionHeader(text: '存储'),
            
            CupertinoCard(
              child: Column(
                children: [
                  // 缓存大小
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
                  // 清空全部
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

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: SerenityTheme.body),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: SerenityTheme.tertiaryText,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearAllRemoteSounds() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('确认清空？'),
        content: const Text('这将删除所有已下载的远程音效和音效包。\n保存的场景中相关的音效也会被移除。'),
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
