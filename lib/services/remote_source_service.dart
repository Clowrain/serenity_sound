import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/sound_effect.dart';
import '../providers/sound_provider.dart';
import 'asset_cache_service.dart';
import 'storage_service.dart';

/// 加载结果
class LoadResult {
  final List<SoundEffect> added;
  final List<SoundEffect> skipped;
  final String? error;

  LoadResult({
    this.added = const [],
    this.skipped = const [],
    this.error,
  });

  bool get hasConflicts => skipped.isNotEmpty;
  bool get isSuccess => error == null;
}

/// 远程来源服务
class RemoteSourceService extends StateNotifier<List<RemoteSource>> {
  final StorageService _storage;
  final AssetCacheService _cacheService;
  final Ref _ref;
  final Dio _dio = Dio();

  RemoteSourceService(this._storage, this._cacheService, this._ref) 
      : super(_storage.getRemoteSources());

  /// 添加远程来源
  Future<LoadResult> addSource(String url, {String? customName}) async {
    try {
      // 1. 下载配置文件
      final response = await _dio.get(url);
      final List<dynamic> remoteList;
      
      if (response.data is String) {
        remoteList = jsonDecode(response.data);
      } else {
        remoteList = response.data;
      }

      // 2. 获取当前所有音效 ID
      final currentSounds = _ref.read(soundListProvider);
      final existingIds = currentSounds.map((s) => s.id).toSet();

      // 3. 处理冲突
      final sourceId = const Uuid().v4();
      final added = <SoundEffect>[];
      final skipped = <SoundEffect>[];
      final soundIds = <String>[];

      for (final json in remoteList) {
        final sound = SoundEffect.fromJson(Map<String, dynamic>.from(json));
        
        if (existingIds.contains(sound.id)) {
          skipped.add(sound);
        } else {
          // 标记为远程音效
          final remoteSound = SoundEffect(
            id: sound.id,
            name: sound.name,
            svgPath: sound.svgPath,
            audioPath: sound.audioPath,
            themeColor: sound.themeColor,
            volume: sound.volume,
            isRemote: true,
            sourceId: sourceId,
          );
          added.add(remoteSound);
          soundIds.add(sound.id);
        }
      }

      if (added.isEmpty) {
        return LoadResult(
          skipped: skipped,
          error: skipped.isNotEmpty ? '所有音效都与本地冲突' : '配置文件为空',
        );
      }

      // 4. 创建来源记录
      final source = RemoteSource(
        id: sourceId,
        url: url,
        name: customName ?? _extractNameFromUrl(url),
        soundIds: soundIds,
        addedAt: DateTime.now(),
      );

      // 5. 保存来源
      state = [...state, source];
      _storage.saveRemoteSources(state);

      // 6. 添加音效到列表
      _ref.read(soundListProvider.notifier).addRemoteSounds(added);

      return LoadResult(added: added, skipped: skipped);
    } on DioException catch (e) {
      return LoadResult(error: '网络错误: ${e.message}');
    } catch (e) {
      return LoadResult(error: '加载失败: $e');
    }
  }

  /// 删除远程来源及其音效
  Future<void> removeSource(String sourceId) async {
    final source = state.firstWhere((s) => s.id == sourceId);
    
    // 1. 从音效列表中移除
    _ref.read(soundListProvider.notifier).removeRemoteSounds(source.soundIds);
    
    // 2. 清除缓存
    await _cacheService.deleteSourceCache(source.soundIds);
    
    // 3. 更新来源列表
    state = state.where((s) => s.id != sourceId).toList();
    _storage.saveRemoteSources(state);
  }

  /// 刷新远程来源
  Future<LoadResult> refreshSource(String sourceId) async {
    final source = state.firstWhere((s) => s.id == sourceId);
    
    // 先删除旧的
    await removeSource(sourceId);
    
    // 重新添加
    return addSource(source.url, customName: source.name);
  }

  String _extractNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final filename = pathSegments.last;
        return filename.replaceAll('.json', '').replaceAll('_', ' ');
      }
    } catch (_) {}
    return '远程音效包';
  }
}

/// 远程来源 Provider
final remoteSourceServiceProvider = StateNotifierProvider<RemoteSourceService, List<RemoteSource>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final cacheService = ref.watch(assetCacheServiceProvider);
  return RemoteSourceService(storage, cacheService, ref);
});
