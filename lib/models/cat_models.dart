// lib/models/cat_models.dart
// All core data models and enums for FocusCat v2.0

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum CatPose { sit, walk, sleep, pat, greet, bored, angry, confront }

enum CatColorPalette {
  cream(
    fur: Color(0xFFF7F2E7),
    furShade: Color(0xFFE2DAC8),
    face: Color(0xFF2B2F3A),
    ear: Color(0xFFF4A7BB),
    blush: Color(0xFFF79BB0),
  ),
  white(
    fur: Color(0xFFFFFFFF),
    furShade: Color(0xFFE4E7EE),
    face: Color(0xFF2B2F3A),
    ear: Color(0xFFF4A7BB),
    blush: Color(0xFFF79BB0),
  ),
  black(
    fur: Color(0xFF2B2E36),
    furShade: Color(0xFF1E2027),
    face: Color(0xFFFFCE7A), // warm amber
    ear: Color(0xFFF2A6BD),
    blush: Color(0xFFE884A0),
  );

  final Color fur;
  final Color furShade;
  final Color face;
  final Color ear;
  final Color blush;

  // Aliases for compatibility
  Color get body => fur;
  Color get accent => furShade;
  Color get eye => face;

  const CatColorPalette({
    required this.fur,
    required this.furShade,
    required this.face,
    required this.ear,
    required this.blush,
  });
}

// ---------------------------------------------------------------------------
// CatNote
// ---------------------------------------------------------------------------

class CatNote {
  final String id;
  final String text;
  final DateTime createdAt;

  CatNote({required this.id, required this.text, required this.createdAt});

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CatNote.fromJson(Map<String, dynamic> json) => CatNote(
        id: json['id'] as String,
        text: json['text'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

// ---------------------------------------------------------------------------
// CatReminder
// ---------------------------------------------------------------------------

class CatReminder {
  final String id;
  final String title;
  final String timeLabel;
  final DateTime triggerAt;
  bool isTriggered;

  CatReminder({
    required this.id,
    required this.title,
    required this.timeLabel,
    DateTime? triggerAt,
    this.isTriggered = false,
  }) : triggerAt = triggerAt ?? DateTime.now().add(const Duration(minutes: 30));

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'timeLabel': timeLabel,
        'triggerAt': triggerAt.toIso8601String(),
        'isTriggered': isTriggered,
      };

  factory CatReminder.fromJson(Map<String, dynamic> json) => CatReminder(
        id: json['id'] as String,
        title: json['title'] as String,
        timeLabel: json['timeLabel'] as String,
        triggerAt: json['triggerAt'] != null
            ? DateTime.tryParse(json['triggerAt'] as String)
            : null,
        isTriggered: (json['isTriggered'] as bool?) ?? false,
      );

  CatReminder copyWith({
    String? id,
    String? title,
    String? timeLabel,
    DateTime? triggerAt,
    bool? isTriggered,
  }) =>
      CatReminder(
        id: id ?? this.id,
        title: title ?? this.title,
        timeLabel: timeLabel ?? this.timeLabel,
        triggerAt: triggerAt ?? this.triggerAt,
        isTriggered: isTriggered ?? this.isTriggered,
      );
}

// ---------------------------------------------------------------------------
// WatchedSiteRule
// ---------------------------------------------------------------------------

class WatchedSiteRule {
  final String domain;
  final int dailyMinutes;
  int secondsUsedToday;

  WatchedSiteRule({
    required this.domain,
    required this.dailyMinutes,
    this.secondsUsedToday = 0,
  });

  int get totalAllowedSeconds => dailyMinutes * 60;
  int get remainingSeconds =>
      (totalAllowedSeconds - secondsUsedToday).clamp(0, 86400);

  WatchedSiteRule copyWith({int? dailyMinutes, int? secondsUsedToday}) =>
      WatchedSiteRule(
        domain: domain,
        dailyMinutes: dailyMinutes ?? this.dailyMinutes,
        secondsUsedToday: secondsUsedToday ?? this.secondsUsedToday,
      );

  Map<String, dynamic> toJson() => {
        'domain': domain,
        'dailyMinutes': dailyMinutes,
        'secondsUsedToday': secondsUsedToday,
      };

  factory WatchedSiteRule.fromJson(Map<String, dynamic> json) =>
      WatchedSiteRule(
        domain: json['domain'] as String,
        dailyMinutes: json['dailyMinutes'] as int,
        secondsUsedToday: (json['secondsUsedToday'] as int?) ?? 0,
      );
}

// ---------------------------------------------------------------------------
// FocusBrowserTab
// ---------------------------------------------------------------------------

class FocusBrowserTab {
  final String id;
  String title;
  String url;

  FocusBrowserTab({
    required this.id,
    required this.title,
    required this.url,
  });
}

// ---------------------------------------------------------------------------
// ScreenTimeAppRule (Native iOS app targets like YouTube, Instagram)
// ---------------------------------------------------------------------------

class ScreenTimeAppRule {
  final String appName;
  final String bundleId;
  final String urlScheme;
  final String icon;
  int dailyMinutes;
  int secondsUsedToday;
  bool isBlocked;

  ScreenTimeAppRule({
    required this.appName,
    required this.bundleId,
    required this.urlScheme,
    required this.icon,
    required this.dailyMinutes,
    this.secondsUsedToday = 0,
    this.isBlocked = false,
  });

  int get totalAllowedSeconds => dailyMinutes * 60;
  int get remainingSeconds =>
      (totalAllowedSeconds - secondsUsedToday).clamp(0, 86400);

  Map<String, dynamic> toJson() => {
        'appName': appName,
        'bundleId': bundleId,
        'urlScheme': urlScheme,
        'icon': icon,
        'dailyMinutes': dailyMinutes,
        'secondsUsedToday': secondsUsedToday,
        'isBlocked': isBlocked,
      };

  factory ScreenTimeAppRule.fromJson(Map<String, dynamic> json) =>
      ScreenTimeAppRule(
        appName: json['appName'] as String,
        bundleId: json['bundleId'] as String,
        urlScheme: json['urlScheme'] as String,
        icon: (json['icon'] as String?) ?? '📱',
        dailyMinutes: json['dailyMinutes'] as int,
        secondsUsedToday: (json['secondsUsedToday'] as int?) ?? 0,
        isBlocked: (json['isBlocked'] as bool?) ?? false,
      );
}
