import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

class SerenityAudioHandler extends BaseAudioHandler with SeekHandler {
  final Map<String, AudioPlayer> _players = {};
  
  SerenityAudioHandler() {
    _initAudioSession();
    
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

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  Future<void> playTrack(String id, String assetPath, double volume) async {
    try {
      if (!_players.containsKey(id)) {
        final player = AudioPlayer();
        // 判断是否为本地文件路径（以 / 开头）
        try {
          if (assetPath.startsWith('/')) {
            await player.setFilePath(assetPath);
          } else {
            await player.setAsset(assetPath);
          }
        } catch (e) {
          print("Error loading audio source $assetPath: $e");
          return;
        }

        await player.setLoopMode(LoopMode.one);
        await player.setVolume(volume);
        _players[id] = player;
      }
      
      if (playbackState.value.playing) {
        _players[id]?.play();
      }
    } catch (e) {
      print("Exception in playTrack: $e");
    }
  }

  Future<void> setTrackVolume(String id, double volume) async {
    await _players[id]?.setVolume(volume);
  }

  Future<void> stopTrack(String id) async {
    await _players[id]?.stop();
    await _players[id]?.dispose();
    _players.remove(id);
  }

  @override
  Future<void> play() async {
    playbackState.add(playbackState.value.copyWith(playing: true));
    for (var player in _players.values) {
      player.play();
    }
  }

  @override
  Future<void> pause() async {
    playbackState.add(playbackState.value.copyWith(playing: false));
    for (var player in _players.values) {
      player.pause();
    }
  }

  @override
  Future<void> stop() async {
    for (var player in _players.values) {
      await player.stop();
      await player.dispose();
    }
    _players.clear();
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
    return super.stop();
  }
}
