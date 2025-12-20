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
  final Map<String, String> failed; // soundName -> error
  final String? error;

  LoadResult({
    this.added = const [],
    this.skipped = const [],
    this.failed = const {},
    this.error,
  });

  bool get hasConflicts => skipped.isNotEmpty;
  bool get hasFailures => failed.isNotEmpty;
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
  Future<LoadResult> addSource(
    String url, {
    String? customName,
    void Function(String message)? onProgress,
  }) async {
    try {
      onProgress?.call('正在加载配置文件...');
      print('RemoteSourceService: Starting to load URL: $url');
      
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

      // 3. 准备下载
      final sourceId = const Uuid().v4();
      final added = <SoundEffect>[];
      final skipped = <SoundEffect>[];
      final failed = <String, String>{};
      final soundIds = <String>[];
      
      int totalItems = remoteList.length;
      int processed = 0;

      for (final json in remoteList) {
        processed++;
        // 解析基本信息（此时 path 是 URL）
        final rawSound = SoundEffect.fromJson(Map<String, dynamic>.from(json));
        
        onProgress?.call('正在下载资源 ($processed/$totalItems): ${rawSound.name}');
        
        if (existingIds.contains(rawSound.id)) {
          skipped.add(rawSound);
          continue;
        }

        try {
          // 下载音频
          final localAudioPath = await _cacheService.getOrDownloadAudio(
            rawSound.audioPath,
            rawSound.id,
          );
          
          // 下载 SVG
          final localSvgPath = await _cacheService.getOrDownloadSvg(
            rawSound.svgPath,
            rawSound.id,
          );

          // 创建指向本地文件的 SoundEffect
          final localSound = SoundEffect(
            id: rawSound.id,
            name: rawSound.name,
            svgPath: localSvgPath,   // 本地绝对路径
            audioPath: localAudioPath, // 本地绝对路径
            themeColor: rawSound.themeColor,
            volume: rawSound.volume,
            isRemote: true,
            sourceId: sourceId,
          );

          added.add(localSound);
          soundIds.add(rawSound.id);
        } catch (e) {
          print('Failed to download assets for ${rawSound.name}: $e');
          failed[rawSound.name] = e.toString();
          continue;
        }
      }

      if (added.isEmpty) {
        return LoadResult(
          skipped: skipped,
          failed: failed,
          error: skipped.isNotEmpty && remoteList.isNotEmpty 
              ? '所有音效都与本地冲突' 
              : failed.isNotEmpty 
                  ? '所有下载都失败了' 
                  : '未成功下载任何有效音效',
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

      return LoadResult(added: added, skipped: skipped, failed: failed);
    } on DioException catch (e) {
      print('RemoteSourceService: DioException: ${e.message}');
      return LoadResult(error: '网络错误: ${e.message}');
    } catch (e, stack) {
      print('RemoteSourceService: Error: $e');
      print('RemoteSourceService: Stack: $stack');
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
