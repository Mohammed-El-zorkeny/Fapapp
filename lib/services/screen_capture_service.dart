import 'screenshot_tracking_service.dart';

/// Backward-compatible facade for older imports.
///
/// Screenshot tracking is now centralized in [ScreenshotTrackingService].
class ScreenCaptureService {
  ScreenCaptureService._();

  static final ScreenCaptureService instance = ScreenCaptureService._();

  Future<void> initialize() {
    return ScreenshotTrackingService.instance.initialize();
  }

  void setCurrentScreen(String screenName) {
    ScreenshotTrackingService.instance.setCurrentScreen(screenName);
  }

  void dispose() {
    ScreenshotTrackingService.instance.dispose();
  }
}
