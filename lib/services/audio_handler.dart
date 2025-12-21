import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

/// 播放器包装类（携带当前加载的资源路径）
class CachedPlayer {
  final AudioPlayer player;
  String assetPath;
  
  CachedPlayer(this.player, this.assetPath);
  
  Future<void> dispose() async {
    await player.dispose();
  }
}

/// LRU 播放器缓存（复用模式：淘汰时复用播放器实例）
class LruPlayerCache {
  final int maxSize;
  final Map<String, CachedPlayer> _cache = {};
  final List<String> _accessOrder = []; // 最近访问的在末尾
  
  LruPlayerCache({this.maxSize = 16});
  
  /// 获取播放器（更新访问顺序）
  CachedPlayer? get(String id) {
    if (_cache.containsKey(id)) {
      _updateAccessOrder(id);
      return _cache[id];
    }
    return null;
  }
  
  /// 添加或更新播放器
  void put(String id, CachedPlayer cachedPlayer) {
    if (_cache.containsKey(id)) {
      _accessOrder.remove(id);
    }
    _cache[id] = cachedPlayer;
    _accessOrder.add(id);
  }
  
  /// 获取可复用的播放器（从最久未使用的非激活播放器中取出）
  /// 返回被复用的旧 ID 和播放器
  (String?, CachedPlayer?) getReusable({required Set<String> protectedIds}) {
    if (_cache.length < maxSize) {
      return (null, null); // 还有空位，无需复用
    }
    
    // 从最久未使用的开始找可复用的
    for (final id in List.from(_accessOrder)) {
      if (!protectedIds.contains(id)) {
        final player = _cache.remove(id);
        _accessOrder.remove(id);
        return (id, player);
      }
    }
    return (null, null); // 所有都被保护，无法复用
  }
  
  /// 更新访问顺序（移到末尾）
  void _updateAccessOrder(String id) {
    _accessOrder.remove(id);
    _accessOrder.add(id);
  }
  
  /// 移除并返回播放器（不释放，由调用方决定）
  CachedPlayer? remove(String id) {
    _accessOrder.remove(id);
    return _cache.remove(id);
  }
  
  /// 检查是否包含
  bool containsKey(String id) => _cache.containsKey(id);
  
  /// 获取所有 ID
  Iterable<String> get keys => _cache.keys;
  
  /// 当前缓存大小
  int get length => _cache.length;
  
  /// 清理不在保护列表中的播放器
  Future<void> cleanup({required Set<String> keep}) async {
    final toRemove = _cache.keys.where((id) => !keep.contains(id)).toList();
    for (final id in toRemove) {
      final cached = _cache.remove(id);
      _accessOrder.remove(id);
      await cached?.dispose();
    }
  }
  
  /// 清空所有（释放资源）
  Future<void> clear() async {
    for (final cached in _cache.values) {
      await cached.dispose();
    }
    _cache.clear();
    _accessOrder.clear();
  }
}

class SerenityAudioHandler extends BaseAudioHandler with SeekHandler {
  // LRU 播放器缓存池（最多保留 16 个播放器，采用复用策略）
  final LruPlayerCache _playerCache = LruPlayerCache(maxSize: 16);
  
  // 当前激活（正在播放）的音效 ID
  final Set<String> _activeIds = {};
  
  SerenityAudioHandler() {
    _initAudioSession();
    _initMediaItem();
    
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.play,
        MediaControl.pause,
      ],
      systemActions: const {
        MediaAction.seek,
      },
      processingState: AudioProcessingState.ready,
      playing: false,
    ));
  }
  
  /// 设置控制中心显示的媒体信息（固定内容）
  void _initMediaItem() {
    mediaItem.add(const MediaItem(
      id: 'serenity_sound',
      title: 'Serenity Sound',
      artist: '白噪音混音',
      album: '放松 · 专注 · 睡眠',
      artUri: null, // iOS 会使用 Info.plist 中配置的应用图标
    ));
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  /// 获取或创建播放器（带 LRU 缓存 + 复用策略）
  Future<AudioPlayer?> _getOrCreatePlayer(String id, String assetPath) async {
    // 1. 如果已缓存且资源相同，直接返回
    final cached = _playerCache.get(id);
    if (cached != null) {
      // 资源已加载，直接返回
      return cached.player;
    }
    
    // 2. 尝试复用现有播放器（避免创建新实例）
    final (oldId, reusable) = _playerCache.getReusable(protectedIds: _activeIds);
    
    AudioPlayer player;
    if (reusable != null) {
      // 复用旧播放器，只需替换音频资源
      player = reusable.player;
      try {
        if (assetPath.startsWith('/')) {
          await player.setFilePath(assetPath);
        } else {
          await player.setAsset(assetPath);
        }
        await player.setLoopMode(LoopMode.one);
      } on PlatformException catch (e) {
        if (e.code == 'abort') {
          return null;
        }
        rethrow;
      } catch (e) {
        print("Error loading audio source $assetPath: $e");
        return null;
      }
    } else {
      // 无可复用的播放器，创建新实例
      player = AudioPlayer();
      try {
        if (assetPath.startsWith('/')) {
          await player.setFilePath(assetPath);
        } else {
          await player.setAsset(assetPath);
        }
        await player.setLoopMode(LoopMode.one);
      } on PlatformException catch (e) {
        if (e.code == 'abort') {
          await player.dispose();
          return null;
        }
        rethrow;
      } catch (e) {
        print("Error loading audio source $assetPath: $e");
        await player.dispose();
        return null;
      }
    }
    
    // 3. 添加到缓存
    _playerCache.put(id, CachedPlayer(player, assetPath));
    return player;
  }

  /// 播放指定音效
  Future<void> playTrack(String id, String assetPath, double volume) async {
    try {
      final player = await _getOrCreatePlayer(id, assetPath);
      if (player == null) return;
      
      await player.setVolume(volume);
      _activeIds.add(id);
      
      if (playbackState.value.playing) {
        await player.seek(Duration.zero);
        player.play();
      }
    } on PlatformException catch (e) {
      if (e.code != 'abort') {
        print("PlatformException in playTrack: $e");
      }
    } catch (e) {
      print("Exception in playTrack: $e");
    }
  }

  /// 设置音量
  Future<void> setTrackVolume(String id, double volume) async {
    await _playerCache.get(id)?.player.setVolume(volume);
  }

  /// 停止音效（只暂停，保留在 LRU 缓存中）
  Future<void> stopTrack(String id) async {
    _activeIds.remove(id);
    final cached = _playerCache.get(id);
    if (cached != null) {
      await cached.player.pause();
      await cached.player.seek(Duration.zero);
    }
  }

  /// 从缓存中移除并释放播放器（用于音效被删除时）
  Future<void> disposeTrack(String id) async {
    _activeIds.remove(id);
    final cached = _playerCache.remove(id);
    await cached?.dispose();
  }

  /// 清理不再需要的播放器
  Future<void> cleanupUnusedPlayers(Set<String> validIds) async {
    await _playerCache.cleanup(keep: validIds);
  }

  @override
  Future<void> play() async {
    playbackState.add(playbackState.value.copyWith(playing: true));
    for (final id in _activeIds) {
      _playerCache.get(id)?.player.play();
    }
  }

  @override
  Future<void> pause() async {
    playbackState.add(playbackState.value.copyWith(playing: false));
    for (final id in _activeIds) {
      _playerCache.get(id)?.player.pause();
    }
  }

  @override
  Future<void> stop() async {
    for (final id in _activeIds) {
      final cached = _playerCache.get(id);
      await cached?.player.pause();
      await cached?.player.seek(Duration.zero);
    }
    _activeIds.clear();
    
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
    return super.stop();
  }

  /// 完全释放所有资源
  Future<void> disposeAll() async {
    await _playerCache.clear();
    _activeIds.clear();
  }
  
  /// 获取当前缓存状态（调试用）
  String get cacheStatus => 'Cache: ${_playerCache.length}/16, Active: ${_activeIds.length}';
}
