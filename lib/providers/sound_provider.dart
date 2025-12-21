import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:uuid/uuid.dart';
import '../models/sound_effect.dart';
import '../services/storage_service.dart';
import '../services/audio_handler.dart';

final storageServiceProvider = Provider((ref) => StorageService());

final audioHandlerProvider = Provider<SerenityAudioHandler>((ref) {
  throw UnimplementedError();
});

class SoundListNotifier extends StateNotifier<List<SoundEffect>> {
  final StorageService _storage;
  SoundListNotifier(this._storage) : super([]) {
    state = _storage.getSounds();
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final List<SoundEffect> newList = [...state];
    final item = newList.removeAt(oldIndex);
    newList.insert(newIndex, item);
    state = newList;
    _storage.saveSounds(newList);
  }

  // 根据保存的顺序重新排列音效
  void applyOrder(List<String> order) {
    if (order.isEmpty) return;
    
    final Map<String, SoundEffect> soundMap = {for (final s in state) s.id: s};
    final List<SoundEffect> newList = [];
    
    // 按保存的顺序添加
    for (final id in order) {
      if (soundMap.containsKey(id)) {
        newList.add(soundMap[id]!);
        soundMap.remove(id);
      }
    }
    
    // 添加可能新增的音效（不在保存顺序中的）
    newList.addAll(soundMap.values);
    
    state = newList;
    _storage.saveSounds(newList);
  }

  void updateVolume(String id, double volume) {
    state = [
      for (final sound in state)
        if (sound.id == id) sound.copyWith(volume: volume) else sound
    ];
    _storage.saveSounds(state);
  }

  /// 添加远程音效
  void addRemoteSounds(List<SoundEffect> sounds) {
    state = [...state, ...sounds];
    _storage.saveSounds(state);
  }

  /// 移除远程音效（按 ID 列表）
  void removeRemoteSounds(List<String> ids) {
    final idsSet = ids.toSet();
    state = state.where((s) => !idsSet.contains(s.id)).toList();
    _storage.saveSounds(state);
  }

  /// 获取所有远程音效
  List<SoundEffect> getRemoteSounds() {
    return state.where((s) => s.isRemote).toList();
  }

  /// 批量恢复音量配置
  void applyVolumes(Map<String, double> volumes) {
    if (volumes.isEmpty) return;
    state = [
      for (final sound in state)
        if (volumes.containsKey(sound.id)) 
          sound.copyWith(volume: volumes[sound.id]!) 
        else 
          sound
    ];
    _storage.saveSounds(state);
  }
}

final soundListProvider = StateNotifierProvider<SoundListNotifier, List<SoundEffect>>((ref) {
  return SoundListNotifier(ref.watch(storageServiceProvider));
});

class ActiveSoundsNotifier extends StateNotifier<Set<String>> {
  final SerenityAudioHandler _handler;
  final Ref _ref;
  ActiveSoundsNotifier(this._handler, this._ref) : super({});

  void toggle(SoundEffect sound) {
    if (state.contains(sound.id)) {
      state = {...state}..remove(sound.id);
      _handler.stopTrack(sound.id);
    } else {
      state = {...state}..add(sound.id);
      _handler.playTrack(sound.id, sound.audioPath, sound.volume);
      if (!_handler.playbackState.value.playing) {
        _handler.play();
      }
    }
  }

  /// 清理掉不在前 12 名的激活音效
  void cleanupNonTop12() {
    final allSounds = _ref.read(soundListProvider);
    final top12Ids = allSounds.take(12).map((e) => e.id).toSet();
    
    final toRemove = state.where((id) => !top12Ids.contains(id)).toList();
    
    if (toRemove.isNotEmpty) {
      final newState = {...state};
      for (final id in toRemove) {
        newState.remove(id);
        _handler.stopTrack(id);
      }
      state = newState;
    }
  }

  /// 停止所有音效播放
  void stopAll() {
    for (final id in state) {
      _handler.stopTrack(id);
    }
    state = {};
    _handler.pause();
  }

  // 应用一个场景配置 (包括音效排序和音量)
  Future<void> applyScene(SoundScene scene) async {
    // 1. 停止当前所有播放
    for (final id in state) {
      await _handler.stopTrack(id);
    }
    
    // 等待音频资源释放，避免 iOS 上的资源竞争
    await Future.delayed(const Duration(milliseconds: 100));
    
    // 2. 恢复音效排序 (如果有保存的排序)
    if (scene.soundOrder.isNotEmpty) {
      _ref.read(soundListProvider.notifier).applyOrder(scene.soundOrder);
    }
    
    // 3. 重新读取音效列表（排序后）
    final allSounds = _ref.read(soundListProvider);
    
    // 4. 根据场景配置开启音效并设置音量
    final newActive = <String>{};
    for (final entry in scene.soundConfig.entries) {
      final sound = allSounds.firstWhere((s) => s.id == entry.key, orElse: () => allSounds.first);
      if (sound.id == entry.key) {
        // 更新音量
        _ref.read(soundListProvider.notifier).updateVolume(sound.id, entry.value);
        await _handler.playTrack(sound.id, sound.audioPath, entry.value);
        newActive.add(sound.id);
      }
    }
    
    state = newActive;
    if (!_handler.playbackState.value.playing) {
      _handler.play();
    }
  }

  void updateVolume(String id, double volume) {
    if (state.contains(id)) {
      _handler.setTrackVolume(id, volume);
    }
  }
}

final activeSoundsProvider = StateNotifierProvider<ActiveSoundsNotifier, Set<String>>((ref) {
  return ActiveSoundsNotifier(ref.watch(audioHandlerProvider), ref);
});

// --- 场景模式 Provider ---

class SceneNotifier extends StateNotifier<List<SoundScene>> {
  final StorageService _storage;
  final Ref _ref;

  SceneNotifier(this._storage, this._ref) : super([]) {
    state = _storage.getScenes();
  }

  void addCurrentAsScene(String name, {String color = '#38f9d7'}) {
    final activeIds = _ref.read(activeSoundsProvider);
    final allSounds = _ref.read(soundListProvider);
    
    final Map<String, double> config = {};
    for (final id in activeIds) {
      final sound = allSounds.firstWhere((s) => s.id == id);
      config[id] = sound.volume;
    }
    // 保存当前音效排序
    final soundOrder = allSounds.map((s) => s.id).toList();

    final newScene = SoundScene(
      id: const Uuid().v4(),
      name: name,
      soundConfig: config,
      soundOrder: soundOrder,
      color: color,
    );

    state = [...state, newScene];
    _storage.saveScenes(state);
  }

  void renameScene(String id, String newName) {
    state = [
      for (final s in state)
        if (s.id == id) s.copyWith(name: newName) else s
    ];
    _storage.saveScenes(state);
  }

  void reorderScenes(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    if (oldIndex < 0 || oldIndex >= state.length) return;
    if (newIndex < 0) newIndex = 0;
    if (newIndex >= state.length) newIndex = state.length - 1;
    if (oldIndex == newIndex) return;
    
    final newList = [...state];
    final item = newList.removeAt(oldIndex);
    newList.insert(newIndex, item);
    state = newList;
    _storage.saveScenes(state);
  }

  // 更新现有场景为当前配置
  void updateScene(String id) {
    final activeIds = _ref.read(activeSoundsProvider);
    final allSounds = _ref.read(soundListProvider);
    
    final Map<String, double> config = {};
    for (final soundId in activeIds) {
      final sound = allSounds.firstWhere((s) => s.id == soundId);
      config[soundId] = sound.volume;
    }
    
    final soundOrder = allSounds.map((s) => s.id).toList();
    
    state = [
      for (final s in state)
        if (s.id == id) SoundScene(
          id: s.id,
          name: s.name,
          soundConfig: config,
          soundOrder: soundOrder,
          color: s.color,
        ) else s
    ];
    _storage.saveScenes(state);
  }

  // 只更新场景的排序（不改变激活的音效配置）
  void updateSceneOrder(String id) {
    final allSounds = _ref.read(soundListProvider);
    final soundOrder = allSounds.map((s) => s.id).toList();
    
    state = [
      for (final s in state)
        if (s.id == id) SoundScene(
          id: s.id,
          name: s.name,
          soundConfig: s.soundConfig,
          soundOrder: soundOrder,
          color: s.color,
        ) else s
    ];
    _storage.saveScenes(state);
  }

  void deleteScene(String id) {
    state = state.where((s) => s.id != id).toList();
    _storage.saveScenes(state);
  }

  /// 从所有场景中移除指定的音效 ID
  void removeSoundIds(List<String> ids) {
    if (ids.isEmpty) return;
    
    final idSet = ids.toSet();
    bool changed = false;
    
    final newScenes = <SoundScene>[];
    
    for (final scene in state) {
      // 检查该场景是否包含需要移除的音效
      final hasOverlap = scene.soundConfig.keys.any((id) => idSet.contains(id)) ||
                         scene.soundOrder.any((id) => idSet.contains(id));
      
      if (hasOverlap) {
        changed = true;
        // 移除配置中的音效
        final newConfig = Map<String, double>.from(scene.soundConfig)
          ..removeWhere((key, _) => idSet.contains(key));
          
        // 移除排序中的音效
        final newOrder = scene.soundOrder.where((id) => !idSet.contains(id)).toList();
        
        newScenes.add(SoundScene(
          id: scene.id,
          name: scene.name,
          soundConfig: newConfig,
          soundOrder: newOrder,
          color: scene.color,
        ));
      } else {
        newScenes.add(scene);
      }
    }
    
    if (changed) {
      state = newScenes;
      _storage.saveScenes(state);
    }
  }
}

final sceneProvider = StateNotifierProvider<SceneNotifier, List<SoundScene>>((ref) {
  return SceneNotifier(ref.watch(storageServiceProvider), ref);
});

// 当前激活的场景 ID
final activeSceneProvider = StateProvider<String?>((ref) => null);

// 未选中场景时的音效排序（用于恢复）
final unselectedSoundOrderProvider = StateProvider<List<String>>((ref) => []);

// 未选中场景时的音效音量（用于恢复）
final unselectedSoundVolumesProvider = StateProvider<Map<String, double>>((ref) => {});

// 场景选中时的原始配置快照（用于检测是否有修改）
// 包含: soundConfig (音效ID->音量) 和 soundOrder (排序)
class SceneSnapshot {
  final Map<String, double> soundConfig;
  final List<String> soundOrder;
  
  SceneSnapshot({
    this.soundConfig = const {},
    this.soundOrder = const [],
  });
  
  static SceneSnapshot empty() => SceneSnapshot();
}

final originalSceneSnapshotProvider = StateProvider<SceneSnapshot>((ref) => SceneSnapshot.empty());

// 检测场景是否有未保存的修改（包括音效增减、音量变化、排序变化）
final hasSceneChangesProvider = Provider<bool>((ref) {
  final activeSceneId = ref.watch(activeSceneProvider);
  if (activeSceneId == null) return false;
  
  final snapshot = ref.watch(originalSceneSnapshotProvider);
  final currentActiveIds = ref.watch(activeSoundsProvider);
  final allSounds = ref.watch(soundListProvider);
  
  // 1. 检测音效增减
  final originalIds = snapshot.soundConfig.keys.toSet();
  if (currentActiveIds.length != originalIds.length) return true;
  if (!currentActiveIds.containsAll(originalIds) || 
      !originalIds.containsAll(currentActiveIds)) return true;
  
  // 2. 检测音量变化
  for (final id in currentActiveIds) {
    final sound = allSounds.firstWhere((s) => s.id == id, orElse: () => allSounds.first);
    if (sound.id == id) {
      final originalVolume = snapshot.soundConfig[id] ?? 0.5;
      if ((sound.volume - originalVolume).abs() > 0.001) return true;
    }
  }
  
  // 3. 检测排序变化
  final currentOrder = allSounds.map((s) => s.id).toList();
  if (snapshot.soundOrder.isNotEmpty && currentOrder.length == snapshot.soundOrder.length) {
    for (int i = 0; i < currentOrder.length; i++) {
      if (currentOrder[i] != snapshot.soundOrder[i]) return true;
    }
  }
  
  return false;
});

// 初始化默认选中场景的 Provider
final initActiveSceneProvider = Provider<void>((ref) {
  final activeScene = ref.read(activeSceneProvider);
  if (activeScene == null) {
    final scenes = ref.read(sceneProvider);
    if (scenes.isNotEmpty) {
      // 延迟设置，避免在 provider 初始化期间修改其他 provider
      Future.microtask(() {
        ref.read(activeSceneProvider.notifier).state = scenes.first.id;
      });
    }
  }
});


// --- 定时器与其他 ---
final isGlobalPlayingProvider = StreamProvider<bool>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.playbackState.map((state) => state.playing);
});

enum TimerStatus { idle, running, ending }

class TimerState {
  final int remainingSeconds;
  final TimerStatus status;
  TimerState({this.remainingSeconds = 0, this.status = TimerStatus.idle});
  bool get isRunning => status == TimerStatus.running;
  bool get isEnding => status == TimerStatus.ending;
  String get formattedTime {
    if (remainingSeconds <= 0) return "00:00";
    final int displayMinutes = (remainingSeconds / 60).ceil();
    final int hours = displayMinutes ~/ 60;
    final int mins = displayMinutes % 60;
    return "${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}";
  }
  TimerState copyWith({int? remainingSeconds, TimerStatus? status}) {
    return TimerState(remainingSeconds: remainingSeconds ?? this.remainingSeconds, status: status ?? this.status);
  }
}

class TimerNotifier extends StateNotifier<TimerState> {
  Timer? _timer;
  final SerenityAudioHandler _handler;
  TimerNotifier(this._handler) : super(TimerState());
  void setTimer(int minutes) {
    _timer?.cancel();
    if (minutes <= 0) { state = TimerState(); return; }
    state = TimerState(remainingSeconds: minutes * 60, status: TimerStatus.running);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds <= 1) { timer.cancel(); _triggerEndSequence(); }
      else { state = state.copyWith(remainingSeconds: state.remainingSeconds - 1); }
    });
  }
  void _triggerEndSequence() {
    state = state.copyWith(remainingSeconds: 0, status: TimerStatus.ending);
    _handler.pause();
    Future.delayed(const Duration(seconds: 4), () { state = TimerState(status: TimerStatus.idle); });
  }
  void cancel() { _timer?.cancel(); state = TimerState(); }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
}

final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  return TimerNotifier(ref.watch(audioHandlerProvider));
});
