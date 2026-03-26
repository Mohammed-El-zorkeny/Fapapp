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
      final responseData = result['data'] ?? result;

      final storage = StorageService();
      await storage.saveToken(
        responseData['token'] ??
            'auth_token_${DateTime.now().millisecondsSinceEpoch}',
      );

      final userType =
          responseData['userType'] ?? responseData['type'] ?? 'CUSTOMER';
      await storage.saveUserType(userType);

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

      final userId = responseData['userId'] ?? responseData['id'];
      if (userId != null) {
        NotificationService().registerNotification(
          userId is int ? userId : int.parse(userId.toString()),
        );
      }

      if (!mounted) return;

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
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              // ── Back Button Row ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.textDark,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // ── Top Section: Icon + Text ──
                      Column(
                        children: [
                          // Compact shield icon
                          Container(
                                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withOpacity(0.12),
                                      AppColors.primaryLight.withOpacity(0.06),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryShadow,
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    width: isSmallScreen ? 42 : 54,
                                    height: isSmallScreen ? 42 : 54,
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.shield_rounded,
                                      size: isSmallScreen ? 28 : 34,
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

                          SizedBox(height: isSmallScreen ? 14 : 20),

                          // Title
                          Text(
                            'التحقق من الرقم',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 24 : 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                              letterSpacing: 0.5,
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 200.ms, duration: 600.ms)
                              .slideY(begin: 0.2, end: 0),

                          SizedBox(height: isSmallScreen ? 6 : 10),

                          Text(
                            'تم إرسال الكود إلى',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textLight.withOpacity(0.8),
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 350.ms, duration: 600.ms),

                          const SizedBox(height: 8),

                          // Phone Number Pill
                          Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withOpacity(0.08),
                                      AppColors.primaryLight.withOpacity(0.04),
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
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.phoneNumber.length >= 11
                                          ? widget.phoneNumber.replaceRange(
                                              7, 11, '****')
                                          : widget.phoneNumber,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                        letterSpacing: 1.0,
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
                        ],
                      ),

                      // ── Middle Section: OTP Input ──
                      Column(
                        children: [
                          PinCodeTextField(
                            appContext: context,
                            length: 6,
                            controller: _otpController,
                            animationType: AnimationType.fade,
                            autoFocus: true,
                            errorAnimationController: _errorController,
                            pinTheme: PinTheme(
                              shape: PinCodeFieldShape.box,
                              borderRadius: BorderRadius.circular(14),
                              fieldHeight: isSmallScreen ? 48 : 54,
                              fieldWidth: isSmallScreen ? 44 : 50,
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
                        ],
                      ),

                      // ── Bottom Section: Timer + Resend + Button ──
                      Column(
                        children: [
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
                                  size: 16,
                                  color: AppColors.textLight,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  timerText,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Resend
                          TextButton(
                            onPressed: _start == 0 ? () => startTimer() : null,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 32),
                            ),
                            child: Text(
                              'لم يصلك الكود؟ إعادة الإرسال',
                              style: TextStyle(
                                fontSize: 13,
                                color: _start == 0
                                    ? AppColors.primary
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),

                          SizedBox(height: isSmallScreen ? 12 : 20),

                          // Confirm Button
                          CustomButton(
                            text: 'تأكيد الرمز',
                            onPressed: _verifyOtp,
                            isLoading: _isLoading,
                          ),

                          SizedBox(height: isSmallScreen ? 8 : 14),

                          const Text(
                            'SECURE VERIFICATION SYSTEM',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
