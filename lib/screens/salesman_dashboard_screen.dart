import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import 'collection_screen.dart';
import 'returns_screen.dart';
import 'notifications_screen.dart';
import 'login_screen.dart';
import 'package:intl/intl.dart' as intl;

class SalesmanDashboardScreen extends StatefulWidget {
  const SalesmanDashboardScreen({super.key});

  @override
  State<SalesmanDashboardScreen> createState() =>
      _SalesmanDashboardScreenState();
}

class _SalesmanDashboardScreenState extends State<SalesmanDashboardScreen> {
  String _userName = 'مندوب';
  int _selectedNavIndex = 0;
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  List<dynamic> _recentNotifications = [];
  bool _notificationsLoading = true;

  final List<_QuickAction> _quickActions = [
    _QuickAction('التحصيل', Icons.account_balance_wallet_outlined, const Color(0xFF00B894), const Color(0xFF55EFC4)),
    _QuickAction('المرتجعات', Icons.assignment_return_outlined, const Color(0xFFE17055), const Color(0xFFFAB1A0)),
    _QuickAction('التوصيل', Icons.local_shipping_outlined, const Color(0xFF0984E3), const Color(0xFF74B9FF)),
    _QuickAction('الإشعارات', Icons.notifications_active_outlined, const Color(0xFF6C5CE7), const Color(0xFFA29BFE)),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadRecentNotifications();
  }

  Future<void> _loadUserData() async {
    final name = await _storageService.getUserNameAr();
    if (name != null && mounted) {
      setState(() {
        _userName = name;
      });
    }
  }

  Future<void> _loadRecentNotifications() async {
    final response = await _apiService.getMyNotifications();
    if (mounted) {
      setState(() {
        _notificationsLoading = false;
        if (response['success']) {
          final allNotifications = response['data'] as List<dynamic>;
          _recentNotifications = allNotifications.take(3).toList();
        }
      });
    }
  }

  void _navigateToAction(int index) {
    Widget? screen;
    switch (index) {
      case 0:
        screen = const CollectionScreen();
        break;
      case 1:
        screen = const ReturnsScreen();
        break;
      case 2:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خدمة التوصيل ستكون متاحة قريباً',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: AppColors.primary,
          ),
        );
        return;
      case 3:
        screen = const NotificationsScreen();
        break;
    }
    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (c) => screen!));
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'تسجيل الخروج',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من تسجيل الخروج؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade900,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'تسجيل الخروج',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storageService.clearAll();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(child: _buildHeader()),

              // Quick Actions Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
                  child: Text(
                    'الخدمات السريعة',
                    style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark),
                  ),
                ).animate().fadeIn(delay: 200.ms),
              ),

              // Quick Actions Grid
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: List.generate(_quickActions.length, (index) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _buildQuickActionCard(index).animate().fadeIn(delay: (300 + index * 80).ms).scale(
                            begin: const Offset(0.85, 0.85),
                            end: const Offset(1, 1),
                            delay: (300 + index * 80).ms,
                            curve: Curves.easeOutBack,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              // Recent Notifications Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'آخر الأحداث',
                        style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (c) => const NotificationsScreen())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Text('عرض الكل',
                                  style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary)),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_back_ios_new,
                                  size: 10, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms),
                ),
              ),

              // Recent Notifications List
              SliverToBoxAdapter(
                child: _buildRecentNotifications(),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: const CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white,
                child: CircleAvatar(radius: 20, backgroundImage: AssetImage('assets/images/avatar.jpg')),
              ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أهلاً بك، مندوبنا المتميز 👋',
                  style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Text(
                  _userName,
                  style: GoogleFonts.cairo(color: AppColors.textDark, fontSize: 19, fontWeight: FontWeight.bold, height: 1.2),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const NotificationsScreen())),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none_rounded, color: AppColors.textDark, size: 22),
                  if (_recentNotifications.any((n) => (n['isRead'] ?? 0) == 0))
                    Positioned(
                      top: -2, right: -2,
                      child: Container(
                        width: 9, height: 9,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _logout,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
    );
  }

  Widget _buildQuickActionCard(int index) {
    final action = _quickActions[index];
    return GestureDetector(
      onTap: () => _navigateToAction(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: action.color.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(color: action.color.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [action.color, action.lightColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: action.color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Icon(action.icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              action.title,
              style: GoogleFonts.cairo(color: AppColors.textDark, fontSize: 11, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentNotifications() {
    if (_notificationsLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: List.generate(3, (i) => _buildNotificationShimmer()).toList(),
        ),
      );
    }

    if (_recentNotifications.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Column(
            children: [
              Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 10),
              Text('لا توجد إشعارات حالياً', style: GoogleFonts.cairo(color: Colors.grey, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: _recentNotifications.asMap().entries.map((entry) {
            final int index = entry.key;
            final item = entry.value as Map<String, dynamic>;
            final bool isRead = (item['isRead'] ?? item['IS_READ'] ?? 0) == 1;
            final bool isLast = index == _recentNotifications.length - 1;

            String dateStr = item['createdAt'] ?? item['CREATED_AT'] ?? '';
            String formattedTime = '';
            try {
              DateTime dt = DateTime.parse(dateStr);
              final now = DateTime.now();
              final diff = now.difference(dt);
              if (diff.inMinutes < 60) {
                formattedTime = 'منذ ${diff.inMinutes} دقيقة';
              } else if (diff.inHours < 24) {
                formattedTime = 'منذ ${diff.inHours} ساعة';
              } else if (diff.inDays < 7) {
                formattedTime = 'منذ ${diff.inDays} يوم';
              } else {
                formattedTime = intl.DateFormat('MM/dd', 'en_US').format(dt);
              }
            } catch (e) {
              formattedTime = dateStr;
            }

            return Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const NotificationsScreen())),
                    borderRadius: BorderRadius.circular(index == 0 && isLast ? 18 : index == 0 ? 18 : isLast ? 18 : 0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isRead ? Colors.grey.shade100 : AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.notifications_outlined, color: isRead ? Colors.grey : AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] ?? item['TITLE'] ?? 'إشعار جديد',
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['body'] ?? item['BODY'] ?? '',
                                  style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textLight),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(formattedTime, style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!isLast) Divider(height: 1, indent: 60, color: Colors.grey.shade100),
              ],
            );
          }).toList(),
        ),
      ).animate().fadeIn(delay: 650.ms),
    );
  }

  Widget _buildNotificationShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 12, width: 120, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 6),
                Container(height: 10, width: 200, decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: Colors.grey.shade200);
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          currentIndex: _selectedNavIndex,
          onTap: (index) {
            setState(() => _selectedNavIndex = index);
            if (index == 1) {
              Navigator.push(context, MaterialPageRoute(builder: (c) => const CollectionScreen()));
            } else if (index == 2) {
              Navigator.push(context, MaterialPageRoute(builder: (c) => const ReturnsScreen()));
            } else if (index == 3) {
              Navigator.push(context, MaterialPageRoute(builder: (c) => const NotificationsScreen()));
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey.shade400,
          showUnselectedLabels: true,
          elevation: 0,
          selectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w500, fontSize: 11),
          items: [
            _buildNavItem(Icons.grid_view_rounded, 'الرئيسية', 0),
            _buildNavItem(Icons.account_balance_wallet_outlined, 'التحصيل', 1),
            _buildNavItem(Icons.assignment_return_outlined, 'المرتجعات', 2),
            _buildNavItem(Icons.notifications_none_rounded, 'الإشعارات', 3),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _selectedNavIndex == index ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 22),
      ),
      label: label,
    );
  }
}

class _QuickAction {
  final String title;
  final IconData icon;
  final Color color;
  final Color lightColor;
  const _QuickAction(this.title, this.icon, this.color, this.lightColor);
}
