import 'package:flutter/material.dart';
import '../services/screenshot_tracking_service.dart';

/// Mixin to add screenshot detection and warning to any screen
///
/// Usage:
/// ```dart
/// class MyScreen extends StatefulWidget { ... }
///
/// class _MyScreenState extends State<MyScreen> with ScreenshotProtectionMixin {
///   @override
///   void initState() {
///     super.initState();
///     initScreenshotProtection();
///   }
///
///   @override
///   void dispose() {
///     disposeScreenshotProtection();
///     super.dispose();
///   }
/// }
/// ```
mixin ScreenshotProtectionMixin<T extends StatefulWidget> on State<T> {
  /// Initialize screenshot detection
  /// Call this in initState()
  void initScreenshotProtection([String? screenName]) {
    if (screenName != null) {
      // We no longer register screenshot callbacks here.
      // ScreenCaptureService handles it globally.
      // We just use this mixin to set the current screen name if provided.
      ScreenshotTrackingService.instance.setCurrentScreen(screenName);
    }
  }

  /// Dispose screenshot detection
  /// Call this in dispose()
  void disposeScreenshotProtection() {
    // No-op
  }
}
