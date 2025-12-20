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

  // 应用一个场景配置 (包括音效排序和音量)
  void applyScene(SoundScene scene) {
    final allSounds = _ref.read(soundListProvider);
    
    // 1. 停止当前所有播放
    for (final id in state) {
      _handler.stopTrack(id);
    }
    
    // 2. 恢复音效排序 (如果有保存的排序)
    if (scene.soundOrder.isNotEmpty) {
      _ref.read(soundListProvider.notifier).applyOrder(scene.soundOrder);
    }
    
    // 3. 根据场景配置开启音效并设置音量
    final newActive = <String>{};
    for (final entry in scene.soundConfig.entries) {
      final sound = allSounds.firstWhere((s) => s.id == entry.key, orElse: () => allSounds.first);
      if (sound.id == entry.key) {
        // 更新音量
        _ref.read(soundListProvider.notifier).updateVolume(sound.id, entry.value);
        _handler.playTrack(sound.id, sound.audioPath, entry.value);
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
    final newList = [...state];
    final item = newList.removeAt(oldIndex);
    newList.insert(newIndex, item);
    state = newList;
    _storage.saveScenes(state);
  }

  void deleteScene(String id) {
    state = state.where((s) => s.id != id).toList();
    _storage.saveScenes(state);
  }
}

final sceneProvider = StateNotifierProvider<SceneNotifier, List<SoundScene>>((ref) {
  return SceneNotifier(ref.watch(storageServiceProvider), ref);
});

// 当前激活的场景 ID
final activeSceneProvider = StateProvider<String?>((ref) => null);

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
