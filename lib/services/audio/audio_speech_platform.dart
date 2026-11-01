/// Abstract interface for platform-specific audio effects and speech synthesis.
abstract class AudioSpeechPlatform {
  void playSchoolBell();
  void playClickGong();
  bool speak(
    String text, {
    double rate = 1.0,
    double pitch = 1.0,
    void Function()? onStart,
    void Function()? onEnd,
  });
  void pause();
  void resume();
  void stop();
  bool isSpeaking();
}
