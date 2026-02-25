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
  int _playCount = 0;

  void _initAudio() {
    try {
      // Create multiple audio elements for better iOS compatibility
      _audio = html.AudioElement()
        ..src = 'assets/sounds/beep.wav'
        ..volume = 1.0
        ..preload = 'auto'
        ..setAttribute('playsinline', '')
        ..setAttribute('webkit-playsinline', '')
        ..setAttribute('x-webkit-airplay', 'deny')
        ..setAttribute('disableRemotePlayback', '');

      _backupAudio = html.AudioElement()
        ..src = 'assets/sounds/beep.wav'
        ..volume = 1.0
        ..preload = 'auto'
        ..setAttribute('playsinline', '')
        ..setAttribute('webkit-playsinline', '')
        ..setAttribute('x-webkit-airplay', 'deny')
        ..setAttribute('disableRemotePlayback', '');

      // Load both
      _audio?.load();
      _backupAudio?.load();

      _initialized = true;
      print('Audio initialized');
    } catch (e) {
      print('Audio initialization error: $e');
    }
  }

  /// Unlock audio for iOS Safari/PWA
  /// This must be called from a user interaction (e.g., button click)
  Future<void> unlock() async {
    if (_unlocked) return;
    if (!_initialized) _initAudio();

    try {
      // Play and pause both audio elements to unlock them
      if (_audio != null) {
        try {
          _audio!.volume = 0;
          await _audio!.play();
          await Future.delayed(const Duration(milliseconds: 10));
          _audio!.pause();
          _audio!.currentTime = 0;
          _audio!.volume = 1.0;
        } catch (e) {
          print('Primary unlock error: $e');
        }
      }

      if (_backupAudio != null) {
        try {
          _backupAudio!.volume = 0;
          await _backupAudio!.play();
          await Future.delayed(const Duration(milliseconds: 10));
          _backupAudio!.pause();
          _backupAudio!.currentTime = 0;
          _backupAudio!.volume = 1.0;
        } catch (e) {
          print('Backup unlock error: $e');
        }
      }

      _unlocked = true;
      print('Audio unlocked successfully');
    } catch (e) {
      print('Audio unlock error: $e');
    }
  }

  Future<void> playBeep() async {
    if (!_initialized) _initAudio();

    try {
      // Ensure audio is unlocked before playing
      if (!_unlocked) {
        await unlock();
      }

      // Alternate between audio elements for better reliability on iOS
      _playCount++;
      final useBackup = _playCount % 2 == 0;

      if (useBackup && _backupAudio != null) {
        try {
          _backupAudio!.currentTime = 0;
          await _backupAudio!.play();
          print('Beep played (backup)');
          return;
        } catch (e) {
          print('Backup audio play error: $e');
        }
      }

      if (_audio != null) {
        try {
          _audio!.currentTime = 0;
          await _audio!.play();
          print('Beep played (primary)');
        } catch (e) {
          print('Primary audio play error: $e');
          // Try backup if primary fails
          if (_backupAudio != null) {
            try {
              _backupAudio!.currentTime = 0;
              await _backupAudio!.play();
              print('Beep played (backup fallback)');
            } catch (e2) {
              print('Backup fallback error: $e2');
            }
          }
        }
      }
    } catch (e) {
      print('Audio play error: $e');
    }
  }
}

final AudioService audioService = AudioService();
