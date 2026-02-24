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

  Future<void> playBeep() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/beep.wav'));
    } catch (_) {
      // no-op
    }
  }
}

final AudioService audioService = AudioService();
