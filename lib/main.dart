import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'utils/app_colors.dart';
import 'utils/font_size_provider.dart';
import 'services/notification_service.dart';
import 'services/screenshot_tracking_service.dart';
import 'services/storage_service.dart';
import 'utils/user_session.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final screenName = message.data['screenName'] ?? '';
  if (screenName == 'FORCE_LOGOUT') {
    await StorageService().clearAll();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up background messaging
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Notification Service
  await NotificationService().initialize();

  // Load persisted font scale
  await FontSizeProvider.instance.load();

  // Initialize Screenshot Detection
  await ScreenshotTrackingService.instance.initialize();

  // Load User Session
  await UserSession.instance.load();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSessionValidity();
    }
  }

  Future<void> _checkSessionValidity() async {
    final token = await StorageService().getToken();
    if (token == null) {
      NotificationService.navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: FontSizeProvider.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Fap Auto Parts',
          navigatorKey: NotificationService.navigatorKey,
          navigatorObservers: [
            ScreenshotTrackingService.instance.routeObserver,
          ],
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            // Apply global font scale
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(FontSizeProvider.instance.scale),
              ),
              child: child!,
            );
          },
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.background,
            primaryColor: AppColors.primary,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
            textTheme: GoogleFonts.cairoTextTheme(Theme.of(context).textTheme),
          ),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
          locale: const Locale('ar', 'EG'),
          home: const SplashScreen(),
        );
      },
    );
  }
}
