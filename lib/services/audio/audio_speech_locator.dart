import 'audio_speech_platform.dart';
import 'audio_speech_stub.dart'
    if (dart.library.js) 'audio_speech_web.dart';

AudioSpeechPlatform getPlatform() => getAudioSpeechPlatform();
