import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'device_info_service.dart';
import 'notification_service.dart';
import 'screenshot_api_service.dart';
import 'storage_service.dart';
import '../screens/login_screen.dart';
import 'screen_capture_service_mobile.dart'
    if (dart.library.html) 'screen_capture_service_web.dart'
    as platform;

class ScreenshotTrackingService {
  ScreenshotTrackingService._() {
    routeObserver = ScreenshotRouteObserver(_setCurrentScreen);
  }

  static final ScreenshotTrackingService instance =
      ScreenshotTrackingService._();

  late final ScreenshotRouteObserver routeObserver;

  final ScreenshotApiService _apiService = ScreenshotApiService.instance;
  final DeviceInfoService _deviceInfoService = DeviceInfoService.instance;
  final StorageService _storageService = StorageService();
  final Duration _debounceDuration = const Duration(seconds: 2);
  static const int _maxScreenshots = 3;

  bool _initialized = false;
  bool _isSending = false;
  DateTime? _lastScreenshotDetectedAt;
  String _currentScreenName = 'UNKNOWN';

  String get currentScreenName => _currentScreenName;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) {
      debugPrint(
        '[ScreenshotTracking] Screenshot detection is not supported on web.',
      );
      return;
    }

    platform.initializeScreenshotCallback(_onScreenshotDetected);
    debugPrint('[ScreenshotTracking] Screenshot listener registered.');

    unawaited(_requestAndroidMediaPermissionIfNeeded());
  }

  void setCurrentScreen(String screenName) {
    _setCurrentScreen(screenName);
  }

  void dispose() {
    if (!kIsWeb) {
      platform.disposeScreenshotCallback();
    }
    _initialized = false;
  }

  void _setCurrentScreen(String screenName) {
    final normalized = _normalizeScreenName(screenName);
    if (normalized == _currentScreenName) return;

    _currentScreenName = normalized;
    debugPrint('[ScreenshotTracking] Current screen name: $_currentScreenName');
  }

  Future<void> _onScreenshotDetected() async {
    final now = DateTime.now();
    final lastDetectedAt = _lastScreenshotDetectedAt;
    if (lastDetectedAt != null &&
        now.difference(lastDetectedAt) < _debounceDuration) {
      debugPrint('[ScreenshotTracking] Duplicate screenshot event skipped.');
      return;
    }
    _lastScreenshotDetectedAt = now;

    if (_isSending) {
      debugPrint(
        '[ScreenshotTracking] Screenshot event skipped while a report is already in flight.',
      );
      return;
    }

    _isSending = true;
    try {
      debugPrint('[ScreenshotTracking] Screenshot detected.');
      debugPrint(
        '[ScreenshotTracking] Current screen name: $_currentScreenName',
      );

      final deviceInfo = await _deviceInfoService.getDeviceAppInfo();
      final payload = <String, dynamic>{
        'captureType': 'SCREENSHOT',
        'deviceType': deviceInfo.deviceType,
        'deviceModel': deviceInfo.deviceModel,
        'osVersion': deviceInfo.osVersion,
        'appVersion': deviceInfo.appVersion,
        'screenName': _currentScreenName,
      };

      debugPrint(
        '[ScreenshotTracking] Payload before sending: ${jsonEncode(payload)}',
      );

      final result = await _apiService.createUserScreenshot(payload);

      debugPrint(
        '[ScreenshotTracking] API response status: '
        '${result['statusCode'] ?? 'UNKNOWN'}, success: ${result['success']}',
      );
      if (result['success'] != true) {
        debugPrint(
          '[ScreenshotTracking] API error details: ${result['message'] ?? result}',
        );
      }

      // عدّ الـ screenshots وبلوك بعد 3
      final count = await _storageService.incrementScreenshotCount();
      debugPrint('[ScreenshotTracking] Screenshot count: $count / $_maxScreenshots');

      if (count >= _maxScreenshots) {
        debugPrint('[ScreenshotTracking] Limit reached — blocking account.');
        await _apiService.blockOwnAccountOnScreenshotAbuse();
        await _storageService.clearAll();
        NotificationService.navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (error, stackTrace) {
      debugPrint('[ScreenshotTracking] API error details: $error');
      debugPrint('$stackTrace');
    } finally {
      _isSending = false;
    }
  }

  Future<void> _requestAndroidMediaPermissionIfNeeded() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final photosStatus = await Permission.photos.request();
      debugPrint(
        '[ScreenshotTracking] Android photos permission: $photosStatus',
      );

      if (!photosStatus.isGranted) {
        final storageStatus = await Permission.storage.request();
        debugPrint(
          '[ScreenshotTracking] Android storage permission: $storageStatus',
        );
      }
    } catch (error) {
      debugPrint('[ScreenshotTracking] Permission request failed: $error');
    }
  }

  String _normalizeScreenName(String screenName) {
    final trimmed = screenName.trim();
    if (trimmed.isEmpty) return 'UNKNOWN';

    switch (trimmed) {
      case 'ReportsScreen':
      case 'ReportDetailsScreen':
        return 'PriceList';
      default:
        return trimmed
            .replaceFirst(RegExp(r'Screen$'), '')
            .replaceFirst(RegExp(r'Page$'), '');
    }
  }
}

class ScreenshotRouteObserver extends NavigatorObserver {
  ScreenshotRouteObserver(this._onScreenChanged);

  final void Function(String screenName) _onScreenChanged;
  final List<Route<dynamic>> _routeStack = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute<dynamic>) {
      _routeStack.add(route);
      _reportCurrentRoute(route);
    }
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routeStack.remove(route);
    _reportCurrentRoute(
      previousRoute is PageRoute<dynamic> ? previousRoute : _lastRouteOrNull(),
    );
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routeStack.remove(route);
    _reportCurrentRoute(_lastRouteOrNull() ?? previousRoute);
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) {
      final index = _routeStack.indexOf(oldRoute);
      if (index >= 0) {
        if (newRoute is PageRoute<dynamic>) {
          _routeStack[index] = newRoute;
        } else {
          _routeStack.removeAt(index);
        }
      } else if (newRoute is PageRoute<dynamic>) {
        _routeStack.add(newRoute);
      }
    } else if (newRoute is PageRoute<dynamic>) {
      _routeStack.add(newRoute);
    }

    _reportCurrentRoute(
      newRoute is PageRoute<dynamic> ? newRoute : _lastRouteOrNull(),
    );
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  void _reportCurrentRoute(Route<dynamic>? route) {
    if (route == null) {
      _onScreenChanged('UNKNOWN');
      return;
    }

    final explicitName = route.settings.name;
    if (explicitName != null &&
        explicitName.isNotEmpty &&
        explicitName != '/') {
      _onScreenChanged(explicitName);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final inferredName = _inferScreenName(route);
      _onScreenChanged(inferredName ?? explicitName ?? 'UNKNOWN');
    });
  }

  String? _inferScreenName(Route<dynamic> route) {
    if (route is! ModalRoute<dynamic>) return null;

    final context = route.subtreeContext;
    if (context == null || !context.mounted) return null;

    final rootElement = context as Element;
    final candidates = <String>[];

    void visit(Element element) {
      final widgetName = element.widget.runtimeType.toString();
      if (_isAppScreenWidgetName(widgetName)) {
        candidates.add(widgetName);
      }
      element.visitChildren(visit);
    }

    visit(rootElement);
    return candidates.isEmpty ? null : candidates.first;
  }

  bool _isAppScreenWidgetName(String widgetName) {
    if (widgetName.startsWith('_')) return false;
    return widgetName.endsWith('Screen') ||
        widgetName.endsWith('Page') ||
        widgetName.endsWith('Viewer') ||
        widgetName.endsWith('Dashboard');
  }

  Route<dynamic>? _lastRouteOrNull() {
    return _routeStack.isEmpty ? null : _routeStack.last;
  }
}
