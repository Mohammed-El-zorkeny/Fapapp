import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_colors.dart';
import 'reports_screen.dart';
import '../services/storage_service.dart';
import 'user_profile_screen.dart';
import 'notifications_screen.dart';
import 'order_tracking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _userName = 'زائر';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final storage = StorageService();
    final name = await storage.getUserNameAr();
    if (name != null) {
      setState(() => _userName = name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: _selectedIndex == 3
              ? const UserProfileScreen()
              : Column(
                  children: [
                    // Custom AppBar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 15.0,
                      ),
                      child: Row(
                        children: [
                          // Profile Picture
                          const CircleAvatar(
                            radius: 25,
                            backgroundImage: NetworkImage(
                              'https://i.pravatar.cc/150?u=123',
                            ), // Placeholder for user image
                          ),
                          const SizedBox(width: 12),
                          // Welcome Text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'مرحباً بك',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _userName,
                                  style: const TextStyle(
                                    color: AppColors.textDark,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Notification Icon
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationsScreen(),
                              ),
                            ),
                            child: _buildTopIcon(
                              Icons.notifications_none_outlined,
                              badge: true,
                            ),
                          ),
                          const SizedBox(width: 15),
                          // Logo Icon
                          _buildTopIcon(
                            Icons.circle, // Placeholder for logo wrapper
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 24,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          children: [
                            // Dashboard Card
                            _buildDashboardCard(),

                            const SizedBox(height: 25),

                            // Grid Items
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              mainAxisSpacing: 15,
                              crossAxisSpacing: 15,
                              childAspectRatio: 1.1,
                              children: [
                                _buildMenuCard(
                                  Icons.description_outlined,
                                  'الكشوفات',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (c) => const ReportsScreen(),
                                    ),
                                  ),
                                ),
                                _buildMenuCard(
                                  Icons.confirmation_number_outlined,
                                  'الفواتير',
                                ),
                                _buildMenuCard(
                                  Icons.payment_outlined,
                                  'المدفوعات',
                                ),
                                _buildMenuCard(
                                  Icons.local_shipping_outlined,
                                  'الشحن',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (c) =>
                                          const OrderTrackingScreen(),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 25),

                            // Statistics Card
                            _buildStatsCard(),

                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTopIcon(
    IconData icon, {
    bool badge = false,
    Color? color,
    Widget? child,
  }) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade100),
          ),
          child:
              child ?? Icon(icon, color: color ?? AppColors.textDark, size: 24),
        ),
        if (badge)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDashboardCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'لوحة التحكم',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'نظرة عامة على نشاطك اليوم',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '1,250',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'إجمالي العمليات',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().scale(delay: 200.ms, curve: Curves.easeOutBack);
  }

  Widget _buildMenuCard(IconData icon, String title, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).moveY(begin: 10, end: 0);
  }

  Widget _buildStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'إحصائيات سريعة',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'آخر 7 أيام',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 50),
          // Chart Placeholder (Simplified x-axis as per image)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['س', 'ج', 'ح', 'ر', 'ث', 'ن', 'ح', 'ج']
                .map(
                  (e) => Text(
                    e,
                    style: TextStyle(
                      color: e == 'ن' ? AppColors.primary : Colors.grey,
                      fontWeight: e == 'ن'
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            label: 'طلباتي',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'المحفظة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}
