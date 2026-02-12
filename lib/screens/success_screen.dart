import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_colors.dart';
import 'login_screen.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 100),

                // Animated Checkmark Header
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Decorative star-like shapes from image
                      Positioned(
                        top: 0,
                        right: 20,
                        child: Icon(
                          Icons.auto_awesome,
                          color: AppColors.primaryLight.withOpacity(0.3),
                          size: 30,
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 10,
                        child: Icon(
                          Icons.auto_awesome_outlined,
                          color: AppColors.primaryLight.withOpacity(0.3),
                          size: 40,
                        ),
                      ),

                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 70,
                        ),
                      ).animate().scale(
                        curve: Curves.elasticOut,
                        duration: 800.ms,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                const Text(
                  'تم إنشاء حسابكم بنجاح',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                Text.rich(
                  const TextSpan(
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textLight,
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(text: 'وسيتم التواصل معكم قريباً\n'),
                      TextSpan(
                        text: 'لتفعيل حسابكم بنجاح',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 60),

                // Feature Grid
                Row(
                  children: [
                    _buildFeatureCard(Icons.verified_outlined, 'توثيق فوري'),
                    const SizedBox(width: 16),
                    _buildFeatureCard(
                      Icons.headset_mic_outlined,
                      'الدعم الفني',
                    ),
                  ],
                ),

                const Spacer(),

                // Back Button (Outlined in image)
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (c) => const LoginScreen()),
                      (route) => false,
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back, color: AppColors.primary),
                        SizedBox(width: 12),
                        Text(
                          'العودة لتسجيل الدخول',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
