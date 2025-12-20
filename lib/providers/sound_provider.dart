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
  ActiveSoundsNotifier(this._handler) : super({});

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

  // 应用一个场景配置
  void applyScene(Map<String, double> config, List<SoundEffect> allSounds) {
    // 1. 停止当前所有播放
    for (final id in state) {
      _handler.stopTrack(id);
    }
    
    // 2. 根据新配置开启
    final newActive = <String>{};
    for (final entry in config.entries) {
      final sound = allSounds.firstWhere((s) => s.id == entry.key);
      _handler.playTrack(sound.id, sound.audioPath, entry.value);
      newActive.add(sound.id);
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
  return ActiveSoundsNotifier(ref.watch(audioHandlerProvider));
});

// --- 场景模式 Provider ---

class SceneNotifier extends StateNotifier<List<SoundScene>> {
  final StorageService _storage;
  final Ref _ref;

  SceneNotifier(this._storage, this._ref) : super([]) {
    state = _storage.getScenes();
  }

  void addCurrentAsScene(String name) {
    final activeIds = _ref.read(activeSoundsProvider);
    final allSounds = _ref.read(soundListProvider);
    
    final Map<String, double> config = {};
    for (final id in activeIds) {
      final sound = allSounds.firstWhere((s) => s.id == id);
      config[id] = sound.volume;
    }

    final newScene = SoundScene(
      id: const Uuid().v4(),
      name: name,
      soundConfig: config,
    );

    state = [...state, newScene];
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
