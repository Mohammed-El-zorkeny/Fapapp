import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../utils/app_colors.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

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
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else {
      if (!mounted) return;
      _errorController.add(ErrorAnimationType.shake);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
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

                // Pixel-Perfect Header
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        size: 45,
                        color: AppColors.primary,
                      ),
                    ),
                  ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
                ),

                const SizedBox(height: 40),

                const Text(
                  'التحقق من الرقم',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'تم إرسال الكود إلى',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textLight.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.phoneNumber.length >= 11
                      ? widget.phoneNumber.replaceRange(7, 11, '****')
                      : widget.phoneNumber,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
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

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 8,
                      shadowColor: AppColors.primary.withOpacity(0.4),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'تأكيد الرمز',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
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
}
