import 'package:flutter/services.dart';

/// Simple haptic + system sound feedback.
/// No external audio packages needed.
class AudioService {
  void hit() {
    HapticFeedback.lightImpact();
  }

  void miss() {
    HapticFeedback.heavyImpact();
  }

  void win() {
    HapticFeedback.vibrate();
  }

  void tap() {
    HapticFeedback.selectionClick();
  }
}
