// lib/services/widget_service.dart
// Service to update the iOS Home Screen Widget (FocusCatHomeScreenWidget).
// Developed for LKS.pvt.ltd company.

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

class WidgetService {
  WidgetService._();
  static final WidgetService instance = WidgetService._();
  factory WidgetService() => instance;

  static const String appGroupId = 'group.com.focuscat.ios';
  static const String iOSWidgetName = 'FocusCatHomeScreenWidget';
  static const MethodChannel _widgetChannel = MethodChannel('com.focuscat.widget');

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      if (!kIsWeb && Platform.isIOS) {
        await HomeWidget.setAppGroupId(appGroupId);
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('[WidgetService] init warning: $e');
    }
  }

  /// Sends full cat & focus state payload to the iOS Home Screen Widget.
  Future<bool> updateWidgetData({
    required String catPose,
    required String catEmoji,
    required String catMood,
    required String speechBubble,
    required bool isPatrolling,
    required int focusSecondsRemaining,
    DateTime? focusEndTime,
    required String targetAppOrDomain,
    int dailyFocusMinutes = 25,
    String company = 'LKS.pvt.ltd company',
  }) async {
    if (kIsWeb) return false;

    final double? endTimestamp = focusEndTime != null
        ? focusEndTime.millisecondsSinceEpoch / 1000.0
        : null;

    final payload = <String, dynamic>{
      'catPose': catPose,
      'catEmoji': catEmoji,
      'catMood': catMood,
      'speechBubble': speechBubble,
      'isPatrolling': isPatrolling,
      'focusSecondsRemaining': focusSecondsRemaining,
      'focusEndTime': endTimestamp ?? 0.0,
      'targetAppOrDomain': targetAppOrDomain,
      'dailyFocusMinutes': dailyFocusMinutes,
      'company': company,
    };

    bool updatedViaHomeWidget = false;
    try {
      await HomeWidget.saveWidgetData<String>('catPose', catPose);
      await HomeWidget.saveWidgetData<String>('catEmoji', catEmoji);
      await HomeWidget.saveWidgetData<String>('catMood', catMood);
      await HomeWidget.saveWidgetData<String>('speechBubble', speechBubble);
      await HomeWidget.saveWidgetData<bool>('isPatrolling', isPatrolling);
      await HomeWidget.saveWidgetData<int>('focusSecondsRemaining', focusSecondsRemaining);
      if (endTimestamp != null) {
        await HomeWidget.saveWidgetData<double>('focusEndTime', endTimestamp);
      } else {
        await HomeWidget.saveWidgetData<double>('focusEndTime', 0.0);
      }
      await HomeWidget.saveWidgetData<String>('targetAppOrDomain', targetAppOrDomain);
      await HomeWidget.saveWidgetData<int>('dailyFocusMinutes', dailyFocusMinutes);
      await HomeWidget.saveWidgetData<String>('company', company);

      await HomeWidget.updateWidget(
        name: iOSWidgetName,
        iOSName: iOSWidgetName,
      );
      updatedViaHomeWidget = true;
    } catch (e) {
      debugPrint('[WidgetService] HomeWidget update error: $e');
    }

    // Direct Native MethodChannel fallback
    try {
      if (Platform.isIOS) {
        await _widgetChannel.invokeMethod('updateWidgetData', payload);
      }
    } catch (e) {
      debugPrint('[WidgetService] MethodChannel update error: $e');
    }

    return updatedViaHomeWidget;
  }

  /// Request iOS WidgetKit to refresh all timelines.
  Future<void> reloadWidgets() async {
    if (kIsWeb) return;
    try {
      await HomeWidget.updateWidget(
        name: iOSWidgetName,
        iOSName: iOSWidgetName,
      );
    } catch (_) {}

    try {
      if (Platform.isIOS) {
        await _widgetChannel.invokeMethod('reloadWidgets');
      }
    } catch (_) {}
  }
}
