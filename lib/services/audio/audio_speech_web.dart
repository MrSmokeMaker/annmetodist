// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'audio_speech_platform.dart';

class AudioSpeechPlatformImpl implements AudioSpeechPlatform {
  dynamic get _audio => js.context['MetodistAudio'];

  @override
  void playSchoolBell() {
    try {
      _audio?.callMethod('playSchoolBell');
    } catch (_) {}
  }

  @override
  void playClickGong() {
    try {
      _audio?.callMethod('playClickGong');
    } catch (_) {}
  }

  @override
  bool speak(
    String text, {
    double rate = 1.0,
    double pitch = 1.0,
    void Function()? onStart,
    void Function()? onEnd,
  }) {
    try {
      if (_audio != null) {
        _audio.callMethod('speak', [text, rate, pitch]);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  void pause() {
    try {
      _audio?.callMethod('pause');
    } catch (_) {}
  }

  @override
  void resume() {
    try {
      _audio?.callMethod('resume');
    } catch (_) {}
  }

  @override
  void stop() {
    try {
      _audio?.callMethod('stop');
    } catch (_) {}
  }

  @override
  bool isSpeaking() {
    try {
      return _audio?.callMethod('isSpeaking') == true;
    } catch (_) {
      return false;
    }
  }
}

AudioSpeechPlatform getAudioSpeechPlatform() => AudioSpeechPlatformImpl();
