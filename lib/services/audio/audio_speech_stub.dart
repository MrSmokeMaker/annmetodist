import 'dart:async';
import 'audio_speech_platform.dart';

class AudioSpeechPlatformImpl implements AudioSpeechPlatform {
  bool _speaking = false;
  Timer? _mockTimer;

  @override
  void playSchoolBell() {
    // Stub for non-web / testing
  }

  @override
  void playClickGong() {
    // Stub for non-web / testing
  }

  @override
  bool speak(
    String text, {
    double rate = 1.0,
    double pitch = 1.0,
    void Function()? onStart,
    void Function()? onEnd,
  }) {
    stop();
    _speaking = true;
    onStart?.call();
    final durationMs = (text.length * 40 / rate).clamp(400, 8000).toInt();
    _mockTimer = Timer(Duration(milliseconds: durationMs), () {
      _speaking = false;
      onEnd?.call();
    });
    return true;
  }

  @override
  void pause() {
    _speaking = false;
    _mockTimer?.cancel();
  }

  @override
  void resume() {
    _speaking = true;
  }

  @override
  void stop() {
    _speaking = false;
    _mockTimer?.cancel();
  }

  @override
  bool isSpeaking() => _speaking;
}

AudioSpeechPlatform getAudioSpeechPlatform() => AudioSpeechPlatformImpl();
