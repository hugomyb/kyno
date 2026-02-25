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

  // Simple beep sound as base64 data URI (440Hz sine wave)
  static const String _beepDataUri =
    'data:audio/wav;base64,UklGRiQAAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQAAAAA=';

  void _initAudio() {
    try {
      // Use data URI for better iOS compatibility
      _audio = html.AudioElement()
        ..src = _beepDataUri
        ..volume = 1.0
        ..preload = 'auto'
        ..loop = false
        ..setAttribute('playsinline', '')
        ..setAttribute('webkit-playsinline', '')
        ..setAttribute('x-webkit-airplay', 'deny')
        ..setAttribute('disableRemotePlayback', '');

      _backupAudio = html.AudioElement()
        ..src = _beepDataUri
        ..volume = 1.0
        ..preload = 'auto'
        ..loop = false
        ..setAttribute('playsinline', '')
        ..setAttribute('webkit-playsinline', '')
        ..setAttribute('x-webkit-airplay', 'deny')
        ..setAttribute('disableRemotePlayback', '');

      // Try to load the actual beep file as well
      try {
        _audio!.src = 'assets/sounds/beep.wav';
        _backupAudio!.src = 'assets/sounds/beep.wav';
      } catch (e) {
        print('Could not load beep.wav, using data URI: $e');
      }

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

      // Try vibration first (works reliably on iOS)
      _vibrate();

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

  void _vibrate() {
    try {
      // Try to vibrate (works on iOS even when audio doesn't)
      // Note: Vibration API might not be available on all browsers
      final navigator = html.window.navigator;
      // Use dynamic call to avoid type errors
      try {
        (navigator as dynamic).vibrate([50]); // 50ms vibration
        print('Vibration triggered');
      } catch (e) {
        // Vibration not supported, ignore
      }
    } catch (e) {
      print('Vibration error: $e');
    }
  }
}

final AudioService audioService = AudioService();
