// lib/services/cat_sound_service.dart
// Sound manager and audio feedback for FocusCat interactions.

import 'package:flutter/services.dart';

class CatSoundService {
  CatSoundService._();
  static final CatSoundService instance = CatSoundService._();
  factory CatSoundService() => instance;

  bool soundEnabled = true;
  double volume = 0.8; // 0.0 to 1.0

  /// Play a cute cat purr audio/haptic pulse
  void playPurr() {
    if (!soundEnabled) return;
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
  }

  /// Play a playful meow chime
  void playMeow() {
    if (!soundEnabled) return;
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.alert);
  }

  /// Play a snappy swat / strike impact
  void playSwat() {
    if (!soundEnabled) return;
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);
  }

  /// Play a clear chime when a Pomodoro focus session finishes
  void playTimerChime() {
    if (!soundEnabled) return;
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
  }

  /// Play a refreshing water drop chime
  void playWaterDrop() {
    if (!soundEnabled) return;
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
  }

  /// Subtle UI click
  void playClick() {
    if (!soundEnabled) return;
    HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);
  }
}
