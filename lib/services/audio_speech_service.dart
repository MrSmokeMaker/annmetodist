import 'dart:async';
import 'package:flutter/foundation.dart';
import 'audio/audio_speech_locator.dart';
import 'audio/audio_speech_platform.dart';

/// Сервис синтеза речи и звуковых эффектов для уроков и заметок (Web Speech API + Web Audio)
class AudioSpeechService {
  static final AudioSpeechService instance = AudioSpeechService._internal();

  AudioSpeechService._internal() {
    _platform = getPlatform();
  }

  late final AudioSpeechPlatform _platform;

  final _speakingController = StreamController<bool>.broadcast();
  Stream<bool> get onSpeakingChanged => _speakingController.stream;

  bool _isSpeaking = false;
  bool get isSpeaking => _platform.isSpeaking() || _isSpeaking;

  /// Воспроизводит чистый кристаллический школьный колокольчик 🔔 (Web Audio API)
  void playSchoolBell() {
    try {
      _platform.playSchoolBell();
    } catch (e) {
      debugPrint('Error playing school bell: $e');
    }
  }

  /// Воспроизводит мягкий щелчок метронома / гонг диктанта
  void playClickGong() {
    try {
      _platform.playClickGong();
    } catch (e) {
      debugPrint('Error playing click gong: $e');
    }
  }

  /// Запускает синтез речи через Web Speech API (голос Совёнка)
  bool speak(
    String text, {
    double rate = 1.0,
    double pitch = 1.0,
    VoidCallback? onStart,
    VoidCallback? onEnd,
  }) {
    if (text.trim().isEmpty) return false;
    _isSpeaking = true;
    _speakingController.add(true);

    final success = _platform.speak(
      text,
      rate: rate,
      pitch: pitch,
      onStart: () {
        _isSpeaking = true;
        _speakingController.add(true);
        onStart?.call();
      },
      onEnd: () {
        _isSpeaking = false;
        _speakingController.add(false);
        onEnd?.call();
      },
    );

    return success;
  }

  /// Приостановить воспроизведение
  void pause() {
    _platform.pause();
    _isSpeaking = false;
    _speakingController.add(false);
  }

  /// Возобновить воспроизведение
  void resume() {
    _platform.resume();
    _isSpeaking = true;
    _speakingController.add(true);
  }

  /// Остановить воспроизведение
  void stop() {
    _platform.stop();
    _isSpeaking = false;
    _speakingController.add(false);
  }

  void dispose() {
    _speakingController.close();
  }
}
