import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../services/storage_service.dart';
import '../utils/user_session.dart';

import 'login_screen.dart';
import 'item_card_screen.dart';
import 'location_edit_screen.dart';
import 'purchase_deliveries_screen.dart';
import 'stock_count_screen.dart';
import 'user_profile_screen.dart';
import 'notifications_screen.dart';
import 'delivery_invoices_list_screen.dart';

class ManstockDashboardScreen extends StatefulWidget {
  const ManstockDashboardScreen({super.key});

  @override
  State<ManstockDashboardScreen> createState() =>
      _ManstockDashboardScreenState();
}

class _ManstockDashboardScreenState extends State<ManstockDashboardScreen> {
  String _userName = 'مسؤول المخزن';
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final storage = StorageService();
    final userData = await storage.getUserData();
    if (userData != null && mounted) {
      setState(() {
        _userName = userData['nameArabic'] ?? 'مسؤول المخزن';
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
      final storage = StorageService();
      await storage.clearAll();
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
          child: Column(
            children: [
              // Top Navbar
              _buildTopNavbar(),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Section
                      Text(
                        'مرحباً بك 👋',
                        style: GoogleFonts.cairo(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'اختر العملية المطلوبة',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: AppColors.textLight,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Main Cards (Rendered Dynamically Based on Permissions in 3 Columns)
                      ...(() {
                        final List<Widget> cards = [];

                        // 1. Stock Count (الجرد)
                        if (UserSession.instance.canStockCount) {
                          cards.add(
                            _buildSmallCard(
                              icon: Icons.inventory_2_rounded,
                              title: 'جرد الأصناف',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const StockCountScreen(),
                                  ),
                                );
                              },
                            ),
                          );
                        }

                        // 2. Item Card (كارت صنف)
                        if (UserSession.instance.canViewItemCard) {
                          cards.add(
                            _buildSmallCard(
                              icon: Icons.article_rounded,
                              title: 'كارت صنف',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ItemCardScreen(),
                                  ),
                                );
                              },
                            ),
                          );
                        }

                        // 3. Change Location (تعديل موقع)
                        if (UserSession.instance.canChangeLocation) {
                          cards.add(
                            _buildSmallCard(
                              icon: Icons.edit_location_alt_rounded,
                              title: 'تعديل موقع',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const LocationEditScreen(),
                                  ),
                                );
                              },
                            ),
                          );
                        }

                        // 4. Purchase Deliveries (استلام المشتريات)
                        if (UserSession.instance.canPurchaseDelivery) {
                          cards.add(
                            _buildSmallCard(
                              icon: Icons.local_shipping_rounded,
                              title: 'استلام المشتريات',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PurchaseDeliveriesScreen(),
                                  ),
                                );
                              },
                            ),
                          );
                        }

                        // 5. Return Deliveries (استلام المرتجعات)
                        if (UserSession.instance.canReturnDelivery) {
                          cards.add(
                            _buildSmallCard(
                              icon: Icons.assignment_return_rounded,
                              title: 'استلام المرتجعات',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'شاشة استلام المرتجعات قيد التطوير',
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }

                        // 6. Review Delivery Invoices (مراجعة فواتير تسليم)
                        if (UserSession.instance.canReviewDeliveryInvoices) {
                          cards.add(
                            _buildSmallCard(
                              icon: Icons.rate_review_rounded,
                              title: 'مراجعة الفواتير',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const DeliveryInvoicesListScreen(),
                                  ),
                                );
                              },
                            ),
                          );
                        }

                        // 7. My Account (حسابي)
                        cards.add(
                          _buildSmallCard(
                            icon: Icons.person_outline,
                            title: 'حسابي',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const UserProfileScreen(),
                                ),
                              );
                            },
                          ),
                        );

                        // 8. Logout (تسجيل الخروج)
                        cards.add(
                          _buildSmallCard(
                            icon: Icons.logout_rounded,
                            title: 'تسجيل الخروج',
                            onTap: _logout,
                          ),
                        );

                        // If no screens are authorized
                        if (cards.isEmpty) {
                          return [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.amber.shade300,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 64,
                                    color: Colors.amber.shade800,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'لا توجد صلاحيات نشطة',
                                    style: GoogleFonts.cairo(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'لا تملك صلاحية الوصول لأي من شاشات المخازن حالياً. يرجى مراجعة مدير النظام.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.cairo(
                                      fontSize: 14,
                                      color: Colors.amber.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ];
                        }

                        return [
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.95,
                            children: cards,
                          ),
                        ];
                      })(),
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

  Widget _buildTopNavbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // App Logo/Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          // User Name
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserProfileScreen(),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userName,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    'مسؤول مخزن',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Notifications Icon
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textDark,
                  size: 26,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _notificationCount > 9 ? '9+' : '$_notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 8),

          // Profile Icon
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.error,
              size: 26,
            ),
            onPressed: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildSmallCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child:
          Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 250.ms)
              .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
    );
  }
}
