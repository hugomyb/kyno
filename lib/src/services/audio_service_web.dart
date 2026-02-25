// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use, avoid_print

import 'dart:js' as js;

class AudioService {
  AudioService() {
    _initAudio();
  }

  dynamic _audioContext;
  bool _unlocked = false;
  bool _initialized = false;

  void _initAudio() {
    try {
      // Create Web Audio API context (works better on iOS than AudioElement)
      final audioContextClass = js.context['AudioContext'] ?? js.context['webkitAudioContext'];
      if (audioContextClass != null) {
        _audioContext = js.JsObject(audioContextClass as js.JsFunction);
        print('AudioContext created: ${(_audioContext as js.JsObject)['state']}');
        _initialized = true;
      } else {
        print('AudioContext not available');
      }
    } catch (e) {
      print('Audio initialization error: $e');
    }
  }

  /// Unlock audio for iOS Safari/PWA
  /// This must be called from a user interaction (e.g., button click)
  /// According to iOS restrictions, we must play a sound immediately on user interaction
  Future<void> unlock() async {
    if (!_initialized) _initAudio();
    if (_audioContext == null) return;

    try {
      final context = _audioContext as js.JsObject;
      final state = context['state'];

      print('AudioContext state before unlock: $state');

      // Resume AudioContext if suspended (required on iOS)
      if (state == 'suspended') {
        try {
          context.callMethod('resume', []);
          // Wait a bit for the promise to resolve
          await Future.delayed(const Duration(milliseconds: 50));
          print('AudioContext resumed');
        } catch (e) {
          print('Resume error: $e');
        }
      }

      // Play a beep immediately to unlock
      await _playBeepInternal();

      _unlocked = true;
      print('Audio unlocked successfully');
    } catch (e) {
      print('Audio unlock error: $e');
    }
  }

  /// Play a beep sound using Web Audio API
  Future<void> playBeep() async {
    if (!_initialized) _initAudio();
    if (_audioContext == null) return;

    try {
      // Ensure audio is unlocked before playing
      if (!_unlocked) {
        await unlock();
        return; // unlock() already plays a beep
      }

      await _playBeepInternal();
    } catch (e) {
      print('Audio play error: $e');
    }
  }

  /// Internal method to play a beep using Web Audio API oscillator
  Future<void> _playBeepInternal() async {
    if (_audioContext == null) return;

    try {
      final context = _audioContext as js.JsObject;

      // Create oscillator for beep sound (800Hz)
      final oscillator = context.callMethod('createOscillator', []);
      final gainNode = context.callMethod('createGain', []);

      // Set frequency to 800Hz (nice beep sound)
      final frequency = (oscillator as js.JsObject)['frequency'];
      (frequency as js.JsObject).callMethod('setValueAtTime', [800, context['currentTime']]);

      // Set volume
      final gain = (gainNode as js.JsObject)['gain'];
      (gain as js.JsObject).callMethod('setValueAtTime', [0.3, context['currentTime']]);

      // Connect oscillator -> gain -> destination
      oscillator.callMethod('connect', [gainNode]);
      gainNode.callMethod('connect', [context['destination']]);

      // Play for 100ms
      oscillator.callMethod('start', [context['currentTime']]);
      oscillator.callMethod('stop', [(context['currentTime'] as num) + 0.1]);

      print('Beep played (Web Audio API)');
    } catch (e) {
      print('Beep play error: $e');
    }
  }
}

final AudioService audioService = AudioService();
