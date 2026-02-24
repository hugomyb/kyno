// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use, avoid_print

import 'dart:html' as html;

class AudioService {
  AudioService() {
    _initAudio();
  }

  html.AudioElement? _audio;
  html.AudioElement? _backupAudio;
  bool _unlocked = false;
  bool _initialized = false;

  void _initAudio() {
    try {
      // Create primary audio element
      _audio = html.AudioElement('assets/sounds/beep.wav')
        ..volume = 1.0
        ..preload = 'auto'
        ..setAttribute('playsinline', 'true')
        ..setAttribute('webkit-playsinline', 'true');

      // Create backup audio element for iOS
      _backupAudio = html.AudioElement('assets/sounds/beep.wav')
        ..volume = 1.0
        ..preload = 'auto'
        ..setAttribute('playsinline', 'true')
        ..setAttribute('webkit-playsinline', 'true');

      // Load both audio elements
      _audio?.load();
      _backupAudio?.load();

      _initialized = true;
    } catch (e) {
      print('Audio initialization error: $e');
    }
  }

  /// Unlock audio context for iOS Safari/PWA
  /// This must be called from a user interaction (e.g., button click)
  Future<void> unlock() async {
    if (_unlocked) return;
    if (!_initialized) _initAudio();

    try {
      // Try to play and immediately pause both audio elements
      // This is required to unlock audio on iOS
      if (_audio != null) {
        _audio!.muted = true;
        await _audio!.play();
        _audio!.pause();
        _audio!.currentTime = 0;
        _audio!.muted = false;
      }

      if (_backupAudio != null) {
        _backupAudio!.muted = true;
        await _backupAudio!.play();
        _backupAudio!.pause();
        _backupAudio!.currentTime = 0;
        _backupAudio!.muted = false;
      }

      _unlocked = true;
      print('Audio unlocked successfully');
    } catch (e) {
      print('Audio unlock error: $e');
      // Unlock failed, will retry on next user interaction
    }
  }

  Future<void> playBeep() async {
    if (!_initialized) _initAudio();

    try {
      // Ensure audio is unlocked before playing
      if (!_unlocked) {
        await unlock();
      }

      // Try primary audio first
      if (_audio != null) {
        try {
          _audio!.currentTime = 0;
          await _audio!.play();
          return;
        } catch (e) {
          print('Primary audio play error: $e');
        }
      }

      // Fallback to backup audio
      if (_backupAudio != null) {
        try {
          _backupAudio!.currentTime = 0;
          await _backupAudio!.play();
        } catch (e) {
          print('Backup audio play error: $e');
        }
      }
    } catch (e) {
      print('Audio play error: $e');
      // no-op
    }
  }
}

final AudioService audioService = AudioService();
