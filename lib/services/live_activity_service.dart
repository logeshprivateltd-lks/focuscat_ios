// lib/services/live_activity_service.dart
// Manages iOS Dynamic Island & Lock Screen Live Activities via ActivityKit.

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:live_activities/live_activities.dart';

class LiveActivityService {
  LiveActivityService._();
  static final LiveActivityService instance = LiveActivityService._();
  factory LiveActivityService() => instance;

  final LiveActivities _liveActivities = LiveActivities();
  String? _currentActivityId;
  bool _isInitialized = false;

  bool get _isSupportedPlatform => !kIsWeb && Platform.isIOS;

  Future<void> init() async {
    if (_isInitialized || !_isSupportedPlatform) return;
    try {
      await _liveActivities.init(appGroupId: 'group.com.example.focuscatIos');
      _isInitialized = true;
      debugPrint('[LiveActivityService] Initialized successfully');
    } catch (e) {
      debugPrint('[LiveActivityService] init error: $e');
    }
  }

  Future<void> update({
    required String catPose,
    required String catEmoji,
    required String statusText,
    required String title,
    required int remainingSeconds,
    double? endTimeTimestamp,
    required bool isPatrolling,
    required String targetAppOrDomain,
  }) async {
    if (!_isSupportedPlatform) return;
    try {
      if (!_isInitialized) await init();

      final enabled = await _liveActivities.areActivitiesEnabled();
      if (!enabled) {
        debugPrint('[LiveActivityService] Live Activities not enabled on device');
        return;
      }

      final data = <String, dynamic>{
        'catPose': catPose,
        'catEmoji': catEmoji,
        'statusText': statusText,
        'title': title,
        'remainingSeconds': remainingSeconds,
        if (endTimeTimestamp != null) 'endTimeTimestamp': endTimeTimestamp,
        'isPatrolling': isPatrolling,
        'targetAppOrDomain': targetAppOrDomain,
      };

      const defaultActivityId = 'focuscat_main';
      if (_currentActivityId == null) {
        final id = await _liveActivities.createActivity(
          defaultActivityId,
          data,
          removeWhenAppIsKilled: false,
        );
        _currentActivityId = id ?? defaultActivityId;
        debugPrint('[LiveActivityService] Created activity: $_currentActivityId');
      } else {
        await _liveActivities.updateActivity(_currentActivityId!, data);
        debugPrint('[LiveActivityService] Updated activity: $_currentActivityId');
      }
    } catch (e) {
      debugPrint('[LiveActivityService] update error: $e');
    }
  }

  Future<void> endActivity() async {
    if (!_isSupportedPlatform || _currentActivityId == null) return;
    try {
      await _liveActivities.endActivity(_currentActivityId!);
      _currentActivityId = null;
      debugPrint('[LiveActivityService] Ended activity');
    } catch (e) {
      debugPrint('[LiveActivityService] endActivity error: $e');
    }
  }
}
