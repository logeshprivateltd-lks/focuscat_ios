// lib/services/pip_service.dart
// Picture-in-Picture (PiP) Floating Mode controller for iOS.
// Enables the animated companion to float above the iPhone Home Screen and other apps.

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PipService {
  PipService._();
  static final PipService instance = PipService._();
  factory PipService() => instance;

  static const MethodChannel _channel = MethodChannel('com.focuscat.pip');

  bool get isSupportedPlatform => !kIsWeb && Platform.isIOS;

  Future<bool> isPipSupported() async {
    if (!isSupportedPlatform) return false;
    try {
      final res = await _channel.invokeMethod<bool>('isPipSupported');
      return res ?? false;
    } catch (e) {
      debugPrint('[PipService] isPipSupported error: $e');
      return false;
    }
  }

  Future<bool> startPip() async {
    if (!isSupportedPlatform) {
      debugPrint('[PipService] PiP is only supported on iOS devices');
      return false;
    }
    try {
      final res = await _channel.invokeMethod<bool>('startPip');
      debugPrint('[PipService] startPip result: $res');
      return res ?? true;
    } catch (e) {
      debugPrint('[PipService] startPip error: $e');
      return false;
    }
  }

  Future<bool> stopPip() async {
    if (!isSupportedPlatform) return false;
    try {
      final res = await _channel.invokeMethod<bool>('stopPip');
      debugPrint('[PipService] stopPip result: $res');
      return res ?? true;
    } catch (e) {
      debugPrint('[PipService] stopPip error: $e');
      return false;
    }
  }
}
