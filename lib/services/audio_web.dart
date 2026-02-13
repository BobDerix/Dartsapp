import 'dart:js_interop';
import 'audio_interface.dart';

PlatformAudio createAudio() => WebAudio();

@JS('playDartTone')
external void _playDartTone(
    JSNumber freq, JSNumber dur, JSString type, JSNumber vol);

class WebAudio implements PlatformAudio {
  void _tone(double freq, double dur,
      {String type = 'sine', double vol = 0.25}) {
    _playDartTone(freq.toJS, dur.toJS, type.toJS, vol.toJS);
  }

  @override
  void hit() {
    _tone(880, 0.12, vol: 0.2);
    Future.delayed(const Duration(milliseconds: 60), () {
      _tone(1175, 0.08, vol: 0.15);
    });
  }

  @override
  void miss() {
    _tone(250, 0.25, type: 'sawtooth', vol: 0.12);
    Future.delayed(const Duration(milliseconds: 80), () {
      _tone(180, 0.2, type: 'sawtooth', vol: 0.1);
    });
  }

  @override
  void win() {
    _tone(523, 0.15, vol: 0.2);
    Future.delayed(const Duration(milliseconds: 120), () {
      _tone(659, 0.15, vol: 0.2);
    });
    Future.delayed(const Duration(milliseconds: 240), () {
      _tone(784, 0.2, vol: 0.25);
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _tone(1047, 0.3, vol: 0.2);
    });
  }

  @override
  void tap() {
    _tone(660, 0.04, vol: 0.1);
  }

  @override
  void streak() {
    _tone(587, 0.1, vol: 0.15);
    Future.delayed(const Duration(milliseconds: 80), () {
      _tone(784, 0.1, vol: 0.18);
    });
    Future.delayed(const Duration(milliseconds: 160), () {
      _tone(988, 0.15, vol: 0.2);
    });
  }

  @override
  void chaosCard() {
    // Dramatic low rumble + rising tone
    _tone(150, 0.3, type: 'sawtooth', vol: 0.15);
    Future.delayed(const Duration(milliseconds: 200), () {
      _tone(300, 0.2, type: 'square', vol: 0.12);
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      _tone(600, 0.15, vol: 0.18);
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      _tone(900, 0.1, vol: 0.15);
    });
  }

  @override
  void timerTick() {
    _tone(1000, 0.05, type: 'square', vol: 0.08);
  }

  @override
  void timerEnd() {
    _tone(200, 0.4, type: 'sawtooth', vol: 0.2);
    Future.delayed(const Duration(milliseconds: 150), () {
      _tone(150, 0.3, type: 'sawtooth', vol: 0.15);
    });
  }

  @override
  void rouletteSpin() {
    _tone(440, 0.06, vol: 0.1);
  }

  @override
  void bigScore() {
    // Crowd-like celebration: rising fanfare
    _tone(440, 0.1, vol: 0.15);
    Future.delayed(const Duration(milliseconds: 80), () {
      _tone(554, 0.1, vol: 0.18);
    });
    Future.delayed(const Duration(milliseconds: 160), () {
      _tone(659, 0.1, vol: 0.2);
    });
    Future.delayed(const Duration(milliseconds: 240), () {
      _tone(880, 0.2, vol: 0.25);
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _tone(1175, 0.25, vol: 0.2);
    });
  }
}
