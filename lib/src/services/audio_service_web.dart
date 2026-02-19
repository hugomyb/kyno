// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

class AudioService {
  AudioService() {
    _audio = html.AudioElement('assets/sounds/beep.wav')
      ..volume = 1.0
      ..preload = 'auto';
  }

  late final html.AudioElement _audio;

  Future<void> playBeep() async {
    try {
      _audio.currentTime = 0;
      await _audio.play();
    } catch (_) {
      // no-op
    }
  }
}

final AudioService audioService = AudioService();
