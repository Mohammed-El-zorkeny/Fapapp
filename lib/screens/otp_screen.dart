import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../utils/app_colors.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/custom_button.dart';
import 'home_screen.dart';
import 'salesman_dashboard_screen.dart';
import 'manstock_dashboard_screen.dart';
import '../services/notification_service.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  final StreamController<ErrorAnimationType> _errorController =
      StreamController<ErrorAnimationType>();
  final _apiService = ApiService();
  bool _isLoading = false;
  Timer? _timer;
  int _start = 180;

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      _errorController.add(ErrorAnimationType.shake);
      return;
    }

    setState(() => _isLoading = true);

    final result = await _apiService.verifyOtp(
      widget.phoneNumber,
      _otpController.text,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      // Extract data from API response
      final responseData = result['data'] ?? result;

      // Save session token and user data
      final storage = StorageService();
      await storage.saveToken(
        responseData['token'] ??
            'auth_token_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Save user type - API uses 'userType'
      final userType =
          responseData['userType'] ?? responseData['type'] ?? 'CUSTOMER';
      await storage.saveUserType(userType);

      // Save user data
      await storage.saveUserData({
        'phoneNumber': widget.phoneNumber,
        'nameArabic':
            responseData['nameArabic'] ?? responseData['nameAr'] ?? 'مستخدم',
        'nameEnglish':
            responseData['nameEnglish'] ?? responseData['nameEn'] ?? 'User',
        'userId': responseData['userId'] ?? responseData['id'],
        'code': responseData['code'],
        'type': userType,
        'isVerified': true,
        'email': responseData['email'],
        'locationLink': responseData['locationLink'],
        'governorate': responseData['governorate'],
        'district': responseData['district'],
        'fullAddress': responseData['fullAddress'],
        'evaluation': responseData['evaluation'],
        'balance': responseData['balance'],
        'address': responseData['address'],
      });

      // Register for Push Notifications
      final userId = responseData['userId'] ?? responseData['id'];
      if (userId != null) {
        NotificationService().registerNotification(
          userId is int ? userId : int.parse(userId.toString()),
        );
      }

      if (!mounted) return;

      // Route based on user type
      Widget nextScreen;
      if (userType == 'SALESMAN') {
        nextScreen = const SalesmanDashboardScreen();
      } else if (userType == 'MANSTOCK') {
        nextScreen = const ManstockDashboardScreen();
      } else {
        nextScreen = const HomeScreen();
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
        (route) => false,
      );
    } else {
      if (!mounted) return;
      _errorController.add(ErrorAnimationType.shake);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    _start = 180;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0)
        setState(() => timer.cancel());
      else
        setState(() => _start--);
    });
  }

  String get timerText {
    int minutes = (_start / 60).floor();
    int seconds = _start % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _errorController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Enhanced Header with Floating Security Icons
                SizedBox(
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Floating Security Icons
                      _buildFloatingIcon(
                        Icons.verified_rounded,
                        top: 15,
                        left: 35,
                        delay: 0,
                      ),
                      _buildFloatingIcon(
                        Icons.lock_clock_rounded,
                        top: 25,
                        right: 30,
                        delay: 300,
                      ),
                      _buildFloatingIcon(
                        Icons.security_rounded,
                        bottom: 45,
                        left: 25,
                        delay: 600,
                      ),
                      _buildFloatingIcon(
                        Icons.vpn_key_rounded,
                        bottom: 35,
                        right: 40,
                        delay: 900,
                      ),

                      // Central Shield Icon with Gradient
                      Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0.1),
                                  AppColors.primaryLight.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryShadow,
                                    blurRadius: 25,
                                    spreadRadius: 3,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.shield_rounded,
                                  size: 35,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                          .animate()
                          .scale(curve: Curves.elasticOut, duration: 900.ms)
                          .then()
                          .shimmer(
                            duration: 2.5.seconds,
                            color: AppColors.primaryLight.withOpacity(0.3),
                          ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                      'التحقق من الرقم',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                        letterSpacing: 0.8,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 600.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 14),

                Text(
                      'تم إرسال الكود إلى',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textLight.withOpacity(0.8),
                        letterSpacing: 0.3,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 350.ms, duration: 600.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 6),

                Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.08),
                            AppColors.primaryLight.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.phone_android_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.phoneNumber.length >= 11
                                ? widget.phoneNumber.replaceRange(7, 11, '****')
                                : widget.phoneNumber,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 600.ms)
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                    ),

                const SizedBox(height: 50),

                PinCodeTextField(
                  appContext: context,
                  length: 6,
                  controller: _otpController,
                  animationType: AnimationType.fade,
                  autoFocus: true,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(15),
                    fieldHeight: 55,
                    fieldWidth: 50,
                    activeFillColor: Colors.white,
                    inactiveFillColor: Colors.grey.shade50,
                    selectedFillColor: Colors.white,
                    activeColor: AppColors.primary,
                    inactiveColor: Colors.grey.shade200,
                    selectedColor: AppColors.primary,
                    borderWidth: 1.5,
                  ),
                  enableActiveFill: true,
                  keyboardType: TextInputType.number,
                  onCompleted: (v) {},
                ).animate().slideX(begin: 0.1, duration: 500.ms),

                const SizedBox(height: 40),

                // Timer Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 18,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timerText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                TextButton(
                  onPressed: _start == 0 ? () => startTimer() : null,
                  child: Text(
                    'لم يصلك الكود؟ إعادة الإرسال',
                    style: TextStyle(
                      color: _start == 0 ? AppColors.primary : Colors.grey,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                CustomButton(
                  text: 'تأكيد الرمز',
                  onPressed: _verifyOtp,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 30),

                const Text(
                  'SECURE VERIFICATION SYSTEM',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingIcon(
    IconData icon, {
    double? top,
    double? left,
    double? right,
    double? bottom,
    required int delay,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child:
          Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(delay: delay.ms, duration: 700.ms)
              .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1))
              .then()
              .moveY(
                begin: 0,
                end: -10,
                duration: 2.2.seconds,
                curve: Curves.easeInOut,
              )
              .rotate(
                begin: -0.04,
                end: 0.04,
                duration: 2.8.seconds,
                curve: Curves.easeInOut,
              ),
    );
  }
}
