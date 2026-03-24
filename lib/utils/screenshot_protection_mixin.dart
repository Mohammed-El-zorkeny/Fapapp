import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screenshot_callback/screenshot_callback.dart';

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
  ScreenshotCallback? _screenshotCallback;

  /// Initialize screenshot detection
  /// Call this in initState()
  void initScreenshotProtection() {
    if (kIsWeb) return; // Screenshot callback doesn't work on web

    try {
      _screenshotCallback = ScreenshotCallback();
      _screenshotCallback?.addListener(_onScreenshotDetected);
    } catch (e) {
      debugPrint("Screenshot protection init failed: $e");
    }
  }

  /// Called when a screenshot is detected
  void _onScreenshotDetected() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('⚠️ تحذير أمني'),
          content: const Text(
            'تم اكتشاف محاولة التقاط صورة للشاشة.\n'
            'هذا الإجراء مسجل ومخالف لسياسة الاستخدام.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('حسناً'),
            ),
          ],
        ),
      ),
    );

    // Log the screenshot attempt
    _logScreenshotAttempt();
  }

  /// Log screenshot attempt (can be extended to send to server)
  void _logScreenshotAttempt() {
    debugPrint("⚠️ Screenshot attempt detected at ${DateTime.now()}");
    // TODO: Send log to server if needed
    // Example:
    // final storageService = StorageService();
    // final userId = await storageService.getUserId();
    // await ApiService.logScreenshotAttempt(userId);
  }

  /// Dispose screenshot detection
  /// Call this in dispose()
  void disposeScreenshotProtection() {
    try {
      _screenshotCallback?.dispose();
    } catch (e) {
      debugPrint("Error disposing screenshot callback: $e");
    }
  }
}
