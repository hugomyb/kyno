// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

class AudioService {
  AudioService() {
    _audio = html.AudioElement('assets/sounds/beep.wav')
      ..volume = 1.0
      ..preload = 'auto'
      ..load();
  }

  late final html.AudioElement _audio;
  bool _unlocked = false;

  /// Unlock audio context for iOS Safari/PWA
  /// This must be called from a user interaction (e.g., button click)
  Future<void> unlock() async {
    if (_unlocked) return;
    try {
      // Play and immediately pause to unlock audio on iOS
      await _audio.play();
      _audio.pause();
      _audio.currentTime = 0;
      _unlocked = true;
    } catch (_) {
      // Unlock failed, will retry on next user interaction
    }
  }

  Future<void> playBeep() async {
    try {
      // Ensure audio is unlocked before playing
      if (!_unlocked) {
        await unlock();
      }
      _audio.currentTime = 0;
      await _audio.play();
    } catch (_) {
      // no-op
    }
  }
}

final AudioService audioService = AudioService();
