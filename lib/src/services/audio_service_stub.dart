import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioService() {
    _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  }

  late final AudioPlayer _player;

  /// Unlock audio context (no-op on non-web platforms)
  Future<void> unlock() async {
    // No-op on native platforms
  }

  void startSilentLoop() {
    // No-op on native platforms
  }

  Future<void> playBeep({bool isFinal = false}) async {
    try {
      await _player.stop();
      await _player.setPlaybackRate(isFinal ? 1.8 : 1.0);
      await _player.play(AssetSource('sounds/beep.wav'));
    } catch (_) {
      // no-op
    }
  }
}

final AudioService audioService = AudioService();
