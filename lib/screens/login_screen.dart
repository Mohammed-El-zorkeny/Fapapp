import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_colors.dart';
import '../services/api_service.dart';
import '../widgets/custom_button.dart';
import 'register_screen.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  final _apiService = ApiService();

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final result = await _apiService.requestOtp(_phoneController.text);

      setState(() => _isLoading = false);

      if (result['success']) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpScreen(phoneNumber: _phoneController.text),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),

                          // Header with Floating Icons & Plain Logo
                          SizedBox(
                            height: 200,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                _buildFloatingIcon(
                                  Icons.security_rounded,
                                  top: 10,
                                  left: 30,
                                  delay: 0,
                                  color: AppColors.primary,
                                ),
                                _buildFloatingIcon(
                                  Icons.verified_user_rounded,
                                  top: 20,
                                  right: 25,
                                  delay: 400,
                                  color: AppColors.primaryLight,
                                ),
                                _buildFloatingIcon(
                                  Icons.lock_rounded,
                                  bottom: 40,
                                  left: 20,
                                  delay: 800,
                                  color: AppColors.primaryDark,
                                ),
                                _buildFloatingIcon(
                                  Icons.fingerprint_rounded,
                                  bottom: 20,
                                  right: 35,
                                  delay: 1200,
                                  color: AppColors.primary,
                                ),

                                // Plain Logo inside without red background
                                Center(
                                  child: Image.asset(
                                    'assets/images/android-chrome-512x512.png',
                                    width: 120,
                                  ),
                                ).animate().scale(
                                  duration: 800.ms,
                                  curve: Curves.elasticOut,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          const Text(
                                'مرحباً بك',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                  letterSpacing: 1,
                                ),
                              )
                              .animate()
                              .fadeIn(delay: 200.ms, duration: 600.ms)
                              .slideY(begin: 0.3, end: 0),

                          const SizedBox(height: 8),

                          Text(
                                'سجل دخولك للمتابعة',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textLight,
                                  letterSpacing: 0.5,
                                ),
                              )
                              .animate()
                              .fadeIn(delay: 400.ms, duration: 600.ms)
                              .slideY(begin: 0.3, end: 0),

                          const SizedBox(height: 40),

                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'رقم الهاتف',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.shadowLight,
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    style: const TextStyle(fontSize: 18),
                                    decoration: InputDecoration(
                                      hintText: '01275002379',
                                      filled: true,
                                      fillColor: Colors.white,
                                      suffixIcon: const Icon(
                                        Icons.phone_in_talk_outlined,
                                        color: AppColors.primary,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 18,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide(
                                          color: AppColors.border,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 30),

                                CustomButton(
                                  text: 'تسجيل الدخول',
                                  onPressed: _handleLogin,
                                  isLoading: _isLoading,
                                ),

                                const SizedBox(height: 24),

                                Center(
                                  child: GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (c) => const RegisterScreen(),
                                      ),
                                    ),
                                    child: const Text(
                                      'إنشاء حساب جديد',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // Powered By Logo at Bottom
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20, top: 30),
                            child: Column(
                              children: [
                                Text(
                                  'Powered By',
                                  style: TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Image.asset(
                                  'assets/images/Logowhite-removebg-preview.png',
                                  height: 35,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
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
    required Color color,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child:
          Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 26),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(delay: delay.ms, duration: 800.ms)
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1))
              .then()
              .moveY(
                begin: 0,
                end: -12,
                duration: 2.5.seconds,
                curve: Curves.easeInOut,
              )
              .rotate(
                begin: -0.05,
                end: 0.05,
                duration: 3.seconds,
                curve: Curves.easeInOut,
              ),
    );
  }
}
