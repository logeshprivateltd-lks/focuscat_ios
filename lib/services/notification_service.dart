// lib/services/notification_service.dart
//
// Full iOS-grade local notification service for FocusCat v2.0.
//
// Capabilities:
//   • Permission request on first launch (iOS + Android 13+)
//   • Immediate "show" notifications (swat, snooze-end)
//   • Scheduled notifications via TZDateTime (timer, reminders)
//   • Repeating hourly water reminder
//   • Cancel by ID — so re-scheduling always replaces correctly
//   • Safe no-op if init hasn't completed (won't crash)

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

// ---------------------------------------------------------------------------
// Notification ID registry — keep every ID in one place to avoid collisions
// ---------------------------------------------------------------------------
abstract class _NId {
  static const int focusComplete = 1;
  static const int waterReminder = 2;
  static const int tabSwatted = 3;
  static const int snoozeEnded = 4;
  // Reminder notifications use IDs 100 … 199 (one per reminder slot)
  static const int reminderBase = 100;
}

// ---------------------------------------------------------------------------
// Re-usable NotificationDetails bundles
// ---------------------------------------------------------------------------
const _iosDetails = DarwinNotificationDetails(
  presentAlert: true,
  presentBadge: true,
  presentSound: true,
  presentBanner: true,
  presentList: true,
  interruptionLevel: InterruptionLevel.active,
);

const _iosTimeSensitiveDetails = DarwinNotificationDetails(
  presentAlert: true,
  presentBadge: true,
  presentSound: true,
  presentBanner: true,
  presentList: true,
  interruptionLevel: InterruptionLevel.timeSensitive,
);

const _androidDetails = AndroidNotificationDetails(
  'focuscat_main',
  'FocusCat Alerts',
  channelDescription: 'Focus timer, tab-swat, and hydration alerts',
  importance: Importance.high,
  priority: Priority.high,
  enableVibration: true,
);

const _notifDetails = NotificationDetails(
  iOS: _iosDetails,
  android: _androidDetails,
);

const _timeSensitiveNotifDetails = NotificationDetails(
  iOS: _iosTimeSensitiveDetails,
  android: _androidDetails,
);

// ---------------------------------------------------------------------------
// NotificationService — singleton
// ---------------------------------------------------------------------------
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();
  factory NotificationService() => instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  int _reminderIdCounter = _NId.reminderBase;

  // -------------------------------------------------------------------------
  // init() — call once from CatViewModel.init()
  // -------------------------------------------------------------------------
  Future<void> init() async {
    if (_initialized) return;

    // 1. Initialize timezone database (needed for scheduled notifications)
    tz_data.initializeTimeZones();
    // Use the local timezone for scheduling
    try {
      final localTz = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(localTz));
    } catch (_) {
      // Fallback: UTC is fine — relative offsets still work
    }

    // 2. Configure platform settings
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // We ask explicitly below
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      iOS: iosInit,
      android: androidInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;

    // 3. Request permissions after initialize() so the dialog appears cleanly
    await _requestPermissions();
  }

  // -------------------------------------------------------------------------
  // Permission request
  // -------------------------------------------------------------------------
  Future<void> _requestPermissions() async {
    // iOS
    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Android 13+
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
    }
  }

  // -------------------------------------------------------------------------
  // Notification tap handler (foreground + background)
  // -------------------------------------------------------------------------
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('[NotificationService] Tapped id=${response.id} '
        'payload=${response.payload}');
    // Future: route to specific screen based on payload
  }

  // =========================================================================
  // PUBLIC API
  // =========================================================================

  // -------------------------------------------------------------------------
  // 1. Immediate notifications (fire right now)
  // -------------------------------------------------------------------------

  Future<void> showFocusComplete() => _safeShow(
        id: _NId.focusComplete,
        title: '🐾 FocusCat — Session Complete!',
        body: 'Great work! Take a break and drink some water 💧',
        payload: 'focus_complete',
      );

  Future<void> showTabSwatted(String domain) => _safeShow(
        id: _NId.tabSwatted,
        title: '😼 FocusCat — Tab Swatted!',
        body: '$domain has been closed. Back to focus!',
        payload: 'tab_swatted',
      );

  Future<void> showSnoozeEnded() => _safeShow(
        id: _NId.snoozeEnded,
        title: '👀 FocusCat — Back on Patrol',
        body: 'Snooze finished. FocusCat is watching your tabs again.',
        payload: 'snooze_ended',
      );

  // -------------------------------------------------------------------------
  // 2. Scheduled focus timer notification
  //    Fires exactly [durationSeconds] from now — survives backgrounding.
  // -------------------------------------------------------------------------
  Future<void> scheduleFocusTimer(int durationSeconds) async {
    if (!_initialized) return;

    // Cancel any existing timer notification first
    await _plugin.cancel(_NId.focusComplete);

    final fireAt = tz.TZDateTime.now(tz.local)
        .add(Duration(seconds: durationSeconds));

    await _safeSchedule(
      id: _NId.focusComplete,
      title: '🍅 FocusCat — Focus Session Done!',
      body:
          'You crushed it! Take a 5-minute break and drink some water 💧',
      scheduledDate: fireAt,
      details: _timeSensitiveNotifDetails,
      payload: 'focus_complete',
    );

    debugPrint('[NotificationService] Focus timer scheduled for $fireAt '
        '(${durationSeconds}s from now)');
  }

  /// Cancel the scheduled focus-timer notification (e.g. user resets it).
  Future<void> cancelFocusTimer() async {
    await _plugin.cancel(_NId.focusComplete);
  }

  // -------------------------------------------------------------------------
  // 3. Scheduled reminder notification
  //    Attempts to parse a human time string ("5pm", "14:30", "in 2 hours").
  //    Falls back to +30 minutes if parsing fails.
  //    Returns the resolved DateTime so the UI can confirm it.
  // -------------------------------------------------------------------------
  Future<DateTime> scheduleReminder({
    required String title,
    required String rawTimeString,
  }) async {
    if (!_initialized) return DateTime.now().add(const Duration(minutes: 30));

    final id = _reminderIdCounter;
    // Cycle through 100 IDs so we never collide
    _reminderIdCounter =
        _NId.reminderBase + ((_reminderIdCounter - _NId.reminderBase + 1) % 100);

    final fireAt = _parseTimeString(rawTimeString);
    final tzFireAt = tz.TZDateTime.from(fireAt, tz.local);

    await _safeSchedule(
      id: id,
      title: '⏰ FocusCat Reminder',
      body: title,
      scheduledDate: tzFireAt,
      payload: 'reminder_$id',
    );

    debugPrint('[NotificationService] Reminder "$title" scheduled for $fireAt');
    return fireAt;
  }

  // -------------------------------------------------------------------------
  // 4. Hourly water reminder — repeating
  //    Call once from init (or a settings toggle). Safe to call multiple times
  //    because we cancel-and-replace using the fixed ID.
  // -------------------------------------------------------------------------
  Future<void> startHourlyWaterReminder() async {
    if (!_initialized) return;

    // Cancel any existing before re-registering
    await _plugin.cancel(_NId.waterReminder);

    await _plugin.periodicallyShow(
      _NId.waterReminder,
      '💧 FocusCat — Hydration Check',
      'Your cat insists you drink water right now. No exceptions. 🐾',
      RepeatInterval.hourly,
      _notifDetails,
      androidScheduleMode: AndroidScheduleMode.inexact,
      payload: 'water_reminder',
    );

    debugPrint('[NotificationService] Hourly water reminder started.');
  }

  Future<void> stopHourlyWaterReminder() async {
    await _plugin.cancel(_NId.waterReminder);
    debugPrint('[NotificationService] Hourly water reminder stopped.');
  }

  // -------------------------------------------------------------------------
  // 5. Cancel all
  // -------------------------------------------------------------------------
  Future<void> cancelAll() async => _plugin.cancelAll();

  // =========================================================================
  // PRIVATE HELPERS
  // =========================================================================

  Future<void> _safeShow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) return;
    try {
      await _plugin.show(id, title, body, _notifDetails, payload: payload);
    } catch (e) {
      debugPrint('[NotificationService] show() failed: $e');
    }
  }

  Future<void> _safeSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    NotificationDetails? details,
    String? payload,
  }) async {
    if (!_initialized) return;
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details ?? _notifDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[NotificationService] zonedSchedule() failed: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Time string parser
  // Understands: "5pm", "17:00", "5:30pm", "in 2 hours", "in 45 minutes"
  // Returns the next upcoming DateTime matching the description.
  // -------------------------------------------------------------------------
  DateTime _parseTimeString(String raw) {
    final now = DateTime.now();
    final s = raw.toLowerCase().trim();

    // "in X hours" / "in X minutes"
    final relMatch =
        RegExp(r'in\s+(\d+)\s*(hour|minute|min|hr)').firstMatch(s);
    if (relMatch != null) {
      final n = int.parse(relMatch.group(1)!);
      final unit = relMatch.group(2)!;
      if (unit.startsWith('h')) return now.add(Duration(hours: n));
      return now.add(Duration(minutes: n));
    }

    // "HH:MM am/pm" or "H am/pm" or "HH:MM"
    final clockMatch = RegExp(
            r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
            caseSensitive: false)
        .firstMatch(s);
    if (clockMatch != null) {
      int hour = int.parse(clockMatch.group(1)!);
      final minute =
          clockMatch.group(2) != null ? int.parse(clockMatch.group(2)!) : 0;
      final ampm = clockMatch.group(3);
      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;

      var candidate =
          DateTime(now.year, now.month, now.day, hour, minute);
      // If the time has already passed today, schedule for tomorrow
      if (candidate.isBefore(now)) {
        candidate = candidate.add(const Duration(days: 1));
      }
      return candidate;
    }

    // Fallback: 30 minutes from now
    return now.add(const Duration(minutes: 30));
  }
}
