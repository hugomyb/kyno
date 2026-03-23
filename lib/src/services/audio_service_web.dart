// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use, avoid_print

import 'dart:js' as js;

class AudioService {
  AudioService() {
    _initAudio();
  }

  dynamic _audioContext;
  bool _unlocked = false;
  bool _initialized = false;
  bool _silentLoopActive = false;

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
  Future<void> playBeep({bool isFinal = false}) async {
    if (!_initialized) _initAudio();
    if (_audioContext == null) return;

    try {
      // Ensure audio is unlocked before playing
      if (!_unlocked) {
        await unlock();
        return; // unlock() already plays a beep
      }

      await _playBeepInternal(isFinal: isFinal);
    } catch (e) {
      print('Audio play error: $e');
    }
  }

  /// Start a silent audio loop to keep iOS audio session alive when screen is off.
  /// Must be called from a user gesture.
  void startSilentLoop() {
    if (_silentLoopActive) return;
    if (_audioContext == null) return;

    try {
      final context = _audioContext as js.JsObject;

      // Create a silent buffer (1 second of silence)
      final sampleRate = (context['sampleRate'] as num).toInt();
      final buffer = context.callMethod('createBuffer', [1, sampleRate, sampleRate]);

      // Create a buffer source that loops forever
      final source = context.callMethod('createBufferSource', []);
      (source as js.JsObject)['buffer'] = buffer;
      source['loop'] = true;

      // Connect through a gain node at zero volume
      final gainNode = context.callMethod('createGain', []);
      final gain = (gainNode as js.JsObject)['gain'];
      (gain as js.JsObject).callMethod('setValueAtTime', [0, context['currentTime']]);

      source.callMethod('connect', [gainNode]);
      gainNode.callMethod('connect', [context['destination']]);
      source.callMethod('start', [0]);

      _silentLoopActive = true;
      print('Silent audio loop started (keeps iOS alive)');
    } catch (e) {
      print('Silent loop error: $e');
    }
  }

  /// Internal method to play a beep using Web Audio API oscillator
  Future<void> _playBeepInternal({bool isFinal = false}) async {
    if (_audioContext == null) return;

    try {
      final context = _audioContext as js.JsObject;

      // Create oscillator for beep sound
      final oscillator = context.callMethod('createOscillator', []);
      final gainNode = context.callMethod('createGain', []);

      final frequency = (oscillator as js.JsObject)['frequency'];
      final gain = (gainNode as js.JsObject)['gain'];

      if (isFinal) {
        (frequency as js.JsObject).callMethod('setValueAtTime', [1200, context['currentTime']]);
        (gain as js.JsObject).callMethod('setValueAtTime', [0.5, context['currentTime']]);
      } else {
        (frequency as js.JsObject).callMethod('setValueAtTime', [800, context['currentTime']]);
        (gain as js.JsObject).callMethod('setValueAtTime', [0.3, context['currentTime']]);
      }

      // Connect oscillator -> gain -> destination
      oscillator.callMethod('connect', [gainNode]);
      gainNode.callMethod('connect', [context['destination']]);

      // Play for 100ms (normal) or 300ms (final)
      final duration = isFinal ? 0.3 : 0.1;
      oscillator.callMethod('start', [context['currentTime']]);
      oscillator.callMethod('stop', [(context['currentTime'] as num) + duration]);

      print('Beep played (Web Audio API) - ${isFinal ? "FINAL 1200Hz" : "800Hz"}');
    } catch (e) {
      print('Beep play error: $e');
    }
  }
}

final AudioService audioService = AudioService();
