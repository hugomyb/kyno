import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioService() {
    _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  }

  late final AudioPlayer _player;

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
