// lib/services/persistence_service.dart
// Handles all SharedPreferences read/write for FocusCat settings, cat physics, and preferences.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cat_models.dart';

class PersistenceService {
  static const _keyUserName = 'focuscat.userName';
  static const _keyCatColor = 'focuscat.catColor';
  static const _keyNotes = 'focuscat.notes';
  static const _keyReminders = 'focuscat.reminders';
  static const _keyCatScale = 'focuscat.catScale';
  static const _keyAnimSpeed = 'focuscat.animSpeed';
  static const _keyWanderEnabled = 'focuscat.wanderEnabled';
  static const _keyFollowFinger = 'focuscat.followFinger';
  static const _keyDozeOffBetweenWanders = 'focuscat.dozeOffBetweenWanders';
  static const _keyTypeAlongEnabled = 'focuscat.typeAlongEnabled';
  static const _keyIsMoodLocked = 'focuscat.isMoodLocked';
  static const _keyLockedPose = 'focuscat.lockedPose';
  static const _keySoundEnabled = 'focuscat.soundEnabled';
  static const _keySoundVolume = 'focuscat.soundVolume';
  static const _keyScreenTimeApps = 'focuscat.screenTimeApps';

  Future<Map<String, dynamic>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString(_keyUserName) ?? 'Friend';
    final savedColor = prefs.getString(_keyCatColor) ?? 'cream';
    final catColor = CatColorPalette.values.firstWhere(
      (c) => c.name == savedColor,
      orElse: () => CatColorPalette.cream,
    );

    final notesRaw = prefs.getStringList(_keyNotes) ?? [];
    final notes = notesRaw
        .map((s) => CatNote.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();

    final remRaw = prefs.getStringList(_keyReminders) ?? [];
    final reminders = remRaw
        .map((s) =>
            CatReminder.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();

    final catScale = prefs.getDouble(_keyCatScale) ?? 0.85;
    final animSpeed = prefs.getDouble(_keyAnimSpeed) ?? 0.80;
    final wanderEnabled = prefs.getBool(_keyWanderEnabled) ?? true;
    final followFinger = prefs.getBool(_keyFollowFinger) ?? false;
    final dozeOffBetweenWanders =
        prefs.getBool(_keyDozeOffBetweenWanders) ?? true;
    final typeAlongEnabled = prefs.getBool(_keyTypeAlongEnabled) ?? false;
    final isMoodLocked = prefs.getBool(_keyIsMoodLocked) ?? false;
    final lockedPoseName = prefs.getString(_keyLockedPose) ?? 'sit';
    final lockedPose = CatPose.values.firstWhere(
      (p) => p.name == lockedPoseName,
      orElse: () => CatPose.sit,
    );
    final soundEnabled = prefs.getBool(_keySoundEnabled) ?? true;
    final soundVolume = prefs.getDouble(_keySoundVolume) ?? 0.8;

    final screenTimeRaw = prefs.getStringList(_keyScreenTimeApps) ?? [];
    List<ScreenTimeAppRule> screenTimeApps = [];
    if (screenTimeRaw.isNotEmpty) {
      screenTimeApps = screenTimeRaw
          .map((s) =>
              ScreenTimeAppRule.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
    }

    return {
      'userName': userName,
      'catColor': catColor,
      'notes': notes,
      'reminders': reminders,
      'catScale': catScale,
      'animSpeed': animSpeed,
      'wanderEnabled': wanderEnabled,
      'followFinger': followFinger,
      'dozeOffBetweenWanders': dozeOffBetweenWanders,
      'typeAlongEnabled': typeAlongEnabled,
      'isMoodLocked': isMoodLocked,
      'lockedPose': lockedPose,
      'soundEnabled': soundEnabled,
      'soundVolume': soundVolume,
      'screenTimeApps': screenTimeApps,
    };
  }

  Future<void> saveAll({
    required String userName,
    required CatColorPalette catColor,
    required List<CatNote> notes,
    required List<CatReminder> reminders,
    double? catScale,
    double? animSpeed,
    bool? wanderEnabled,
    bool? followFinger,
    bool? dozeOffBetweenWanders,
    bool? typeAlongEnabled,
    bool? isMoodLocked,
    CatPose? lockedPose,
    bool? soundEnabled,
    double? soundVolume,
    List<ScreenTimeAppRule>? screenTimeApps,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, userName);
    await prefs.setString(_keyCatColor, catColor.name);
    await prefs.setStringList(
      _keyNotes,
      notes.map((n) => jsonEncode(n.toJson())).toList(),
    );
    await prefs.setStringList(
      _keyReminders,
      reminders.map((r) => jsonEncode(r.toJson())).toList(),
    );

    if (catScale != null) await prefs.setDouble(_keyCatScale, catScale);
    if (animSpeed != null) await prefs.setDouble(_keyAnimSpeed, animSpeed);
    if (wanderEnabled != null) {
      await prefs.setBool(_keyWanderEnabled, wanderEnabled);
    }
    if (followFinger != null) {
      await prefs.setBool(_keyFollowFinger, followFinger);
    }
    if (dozeOffBetweenWanders != null) {
      await prefs.setBool(_keyDozeOffBetweenWanders, dozeOffBetweenWanders);
    }
    if (typeAlongEnabled != null) {
      await prefs.setBool(_keyTypeAlongEnabled, typeAlongEnabled);
    }
    if (isMoodLocked != null) {
      await prefs.setBool(_keyIsMoodLocked, isMoodLocked);
    }
    if (lockedPose != null) {
      await prefs.setString(_keyLockedPose, lockedPose.name);
    }
    if (soundEnabled != null) {
      await prefs.setBool(_keySoundEnabled, soundEnabled);
    }
    if (soundVolume != null) {
      await prefs.setDouble(_keySoundVolume, soundVolume);
    }
    if (screenTimeApps != null) {
      await prefs.setStringList(
        _keyScreenTimeApps,
        screenTimeApps.map((a) => jsonEncode(a.toJson())).toList(),
      );
    }
  }
}
