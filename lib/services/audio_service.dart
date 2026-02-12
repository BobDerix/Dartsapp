import 'audio_interface.dart';
import 'audio_native.dart' if (dart.library.html) 'audio_web.dart'
    as platform_audio;

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final PlatformAudio _audio = platform_audio.createAudio();

  void hit() => _audio.hit();
  void miss() => _audio.miss();
  void win() => _audio.win();
  void tap() => _audio.tap();
  void streak() => _audio.streak();
  void chaosCard() => _audio.chaosCard();
  void timerTick() => _audio.timerTick();
  void timerEnd() => _audio.timerEnd();
  void rouletteSpin() => _audio.rouletteSpin();
  void bigScore() => _audio.bigScore();
}
