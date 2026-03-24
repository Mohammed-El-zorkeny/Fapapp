import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_colors.dart';
import '../services/storage_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'salesman_dashboard_screen.dart';
import 'manstock_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // Check if user is already logged in
    final storage = StorageService();
    final token = await storage.getToken();
    final userType = await storage.getUserType();

    Widget nextScreen;
    if (token != null && token.isNotEmpty) {
      // User is logged in, route based on type
      if (userType == 'SALESMAN') {
        nextScreen = const SalesmanDashboardScreen();
      } else if (userType == 'MANSTOCK') {
        nextScreen = const ManstockDashboardScreen();
      } else {
        nextScreen = const HomeScreen();
      }
    } else {
      // User is not logged in, go to login
      nextScreen = const LoginScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Stack(
            children: [
              // Animated Background Circles
              Positioned(
                top: -100,
                right: -100,
                child:
                    Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          duration: 3.seconds,
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.2, 1.2),
                        ),
              ),
              Positioned(
                bottom: -80,
                left: -80,
                child:
                    Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          duration: 4.seconds,
                          begin: const Offset(1, 1),
                          end: const Offset(1.3, 1.3),
                        ),
              ),

              // Main Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Container with Glow
                    Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(45),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 40,
                                spreadRadius: 10,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/images/android-chrome-512x512.png',
                              width: 120,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.directions_car_rounded,
                                    size: 90,
                                    color: AppColors.primary,
                                  ),
                            ),
                          ),
                        )
                        .animate()
                        .scale(duration: 800.ms, curve: Curves.elasticOut)
                        .then()
                        .shimmer(
                          duration: 2.seconds,
                          color: Colors.white.withOpacity(0.5),
                        ),

                    const SizedBox(height: 50),

                    // App Name
                    const Text(
                          'FAP Auto',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 800.ms)
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: 12),

                    // Subtitle
                    const Text(
                          'Body Parts',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            letterSpacing: 4,
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 600.ms, duration: 800.ms)
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: 80),

                    // Loading Indicator
                    SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.9),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 1000.ms, duration: 600.ms)
                        .scale(begin: const Offset(0.5, 0.5)),
                  ],
                ),
              ),

              // Bottom Text
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Text(
                      'قطع غيار السيارات الأصلية',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 1,
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().fadeIn(delay: 1200.ms, duration: 800.ms),
                    const SizedBox(height: 8),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                        letterSpacing: 1,
                      ),
                    ).animate().fadeIn(delay: 1400.ms, duration: 800.ms),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
