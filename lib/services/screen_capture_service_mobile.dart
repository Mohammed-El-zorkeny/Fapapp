import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:screenshot_callback/screenshot_callback.dart';

ScreenshotCallback? _screenshotCallback;
StreamSubscription<dynamic>? _nativeScreenshotSubscription;
const EventChannel _nativeScreenshotChannel = EventChannel(
  'com.fapauto.parts/screenshot_events',
);

void initializeScreenshotCallback(void Function() onScreenshot) {
  disposeScreenshotCallback();

  if (defaultTargetPlatform == TargetPlatform.android) {
    _screenshotCallback = ScreenshotCallback();
    _screenshotCallback?.addListener(onScreenshot);

    _nativeScreenshotSubscription = _nativeScreenshotChannel
        .receiveBroadcastStream()
        .listen(
          (event) {
            debugPrint(
              '[ScreenshotTracking] Native Android screenshot event: $event',
            );
            onScreenshot();
          },
          onError: (Object error) {
            debugPrint(
              '[ScreenshotTracking] Native Android screenshot stream error: $error',
            );
          },
        );
  } else if (defaultTargetPlatform == TargetPlatform.iOS) {
    _nativeScreenshotSubscription = _nativeScreenshotChannel
        .receiveBroadcastStream()
        .listen(
          (event) {
            debugPrint(
              '[ScreenshotTracking] Native iOS screenshot attempt event: $event',
            );
            onScreenshot();
          },
          onError: (Object error) {
            debugPrint(
              '[ScreenshotTracking] Native iOS screenshot stream error: $error',
            );
          },
        );
  }
}

void disposeScreenshotCallback() {
  _screenshotCallback?.dispose();
  _screenshotCallback = null;
  _nativeScreenshotSubscription?.cancel();
  _nativeScreenshotSubscription = null;
}
