import 'package:flutter/services.dart';
import 'audio_interface.dart';

PlatformAudio createAudio() => NativeAudio();

class NativeAudio implements PlatformAudio {
  @override
  void hit() => HapticFeedback.lightImpact();

  @override
  void miss() => HapticFeedback.heavyImpact();

  @override
  void win() => HapticFeedback.vibrate();

  @override
  void tap() => HapticFeedback.selectionClick();

  @override
  void streak() => HapticFeedback.mediumImpact();

  @override
  void chaosCard() => HapticFeedback.vibrate();

  @override
  void timerTick() => HapticFeedback.selectionClick();

  @override
  void timerEnd() => HapticFeedback.heavyImpact();

  @override
  void rouletteSpin() => HapticFeedback.selectionClick();

  @override
  void bigScore() => HapticFeedback.vibrate();
}
