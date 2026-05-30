import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import 'reports_screen.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import 'user_profile_screen.dart';
import 'notifications_screen.dart';
import 'orders_screen.dart';
import 'statement_screen.dart';
import 'invoices_screen.dart';
import 'package:intl/intl.dart' as intl;
import 'order_view_screen.dart';
import 'report_details_screen.dart';
import 'ad_details_screen.dart';
import '../utils/user_session.dart';

class _QuickAction {
  final String title;
  final IconData icon;
  final Color color;
  final Color lightColor;
  _QuickAction(this.title, this.icon, this.color, this.lightColor);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'زائر';
  String? _locationLink;
  int _selectedNavIndex = 0;
  final ApiService _apiService = ApiService();
  List<dynamic> _recentNotifications = [];
  bool _notificationsLoading = true;



  // Advertisements
  List<Map<String, dynamic>> _ads = [];
  bool _adsLoading = true;
  List<Map<String, dynamic>> _cardAds = [];
  bool _cardAdsLoading = true;

  late List<_QuickAction> _quickActions;

  @override
  void initState() {
    super.initState();
    _initQuickActions();
    _loadUserData();
    _loadRecentNotifications();
    _loadAds();
    _loadCardAds();
  }

  void _initQuickActions() {
    _quickActions = [
      _QuickAction('الكشوفات', Icons.description_outlined, const Color(0xFF6C5CE7), const Color(0xFFA29BFE)),
      _QuickAction('الطلبات', Icons.shopping_bag_outlined, const Color(0xFF0984E3), const Color(0xFF74B9FF)),
    ];
    if (UserSession.instance.canViewPrices) {
      _quickActions.addAll([
        _QuickAction('كشف الحساب', Icons.account_balance_outlined, const Color(0xFFE17055), const Color(0xFFFAB1A0)),
        _QuickAction('الفواتير', Icons.receipt_long_outlined, const Color(0xFF00B894), const Color(0xFF55EFC4)),
      ]);
    }
  }

  Future<void> _loadUserData() async {
    final storage = StorageService();
    final name = await storage.getUserNameAr();
    final userData = await storage.getUserData();
    if (mounted) {
      setState(() {
        if (name != null) _userName = name;
        if (userData != null) {
          _locationLink = userData['locationLink'];
        }
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



  Future<void> _loadAds() async {
    final result = await _apiService.getAds(adType: 'FULL');
    if (mounted) {
      setState(() {
        _adsLoading = false;
        if (result['success']) {
          final all = List<Map<String, dynamic>>.from(result['data']);
          // آخر 3 إعلانات بس
          _ads = all.length > 3 ? all.sublist(all.length - 3) : all;
        }
      });
    }
  }

  Future<void> _loadCardAds() async {
    final result = await _apiService.getAds(adType: 'CARD');
    if (mounted) {
      setState(() {
        _cardAdsLoading = false;
        if (result['success']) {
          _cardAds = List<Map<String, dynamic>>.from(result['data']);
        }
      });
    }
  }

  void _navigateToAction(int index) {
    if (index >= _quickActions.length) return;
    String title = _quickActions[index].title;
    Widget screen;
    if (title == 'الكشوفات') {
      screen = const ReportsScreen();
    } else if (title == 'الطلبات') {
      screen = const OrdersScreen();
    } else if (title == 'كشف الحساب') {
      screen = const StatementScreen();
    } else if (title == 'الفواتير') {
      screen = const InvoicesScreen();
    } else {
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (c) => screen));
  }

  void _handleNotificationClick(Map<String, dynamic> notification) {
    String? screen = notification['screenName'] ?? notification['SCREEN_NAME'];
    var refId = notification['referenceId'] ?? notification['REFERENCE_ID'];

    if (screen == 'ORDER_VIEW' && refId != null) {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => OrderViewScreen(orderId: int.parse(refId.toString())),
      ));
    } else if (screen == 'REPORT_DETAILS' && refId != null) {
      String listName = notification['refName'] ?? notification['REF_NAME'] ?? 'تفاصيل الكشف';
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => ReportDetailsScreen(priceListId: int.parse(refId.toString()), priceListName: listName),
      ));
    } else if (screen == 'REPORTS') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportsScreen()));
    } else if (screen == 'ORDERS_WORK') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersScreen(initialIndex: 2)));
    } else if (screen == 'ORDERS_WAIT') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersScreen(initialIndex: 3)));
    } else {
      // Default: go to notifications screen
      Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
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
              
              // Warning Message for missing location
              if (_locationLink == null || _locationLink!.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تنبيه هام!',
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber.shade900),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'يرجى استكمال معلومات موقعك لضمان الخدمة والتتبع بشكل صحيح.',
                                  style: GoogleFonts.cairo(fontSize: 11, color: Colors.amber.shade800),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const UserProfileScreen())),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade500,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              minimumSize: Size.zero,
                            ),
                            child: Text('تعديل', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
                  ),
                ),
                
              // Quick Actions Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الخدمات',
                        style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms),
                ),
              ),
              // Quick Actions - 4 in a row
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


              // ─── Ads Section ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Text('الإعلانات', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                        ],
                      ),
                      if (_ads.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${_ads.length}', style: GoogleFonts.cairo(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ).animate().fadeIn(delay: 700.ms),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildAdsSection(),
              ),
              // ─── Product Cards (CARD Ads) ──────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF0984E3), Color(0xFF74B9FF)]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text('كل ما هو جديد', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      const Spacer(),
                      if (_cardAds.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0984E3).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${_cardAds.length}', style: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFF0984E3), fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ).animate().fadeIn(delay: 800.ms),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildCardAdsSection(),
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
          // Profile Avatar with gradient border
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const UserProfileScreen())),
            child: Container(
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
          ),
          const SizedBox(width: 14),
          // Welcome Text - simplified
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أهلا بعودتك 👋',
                  style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Text(
                  _userName,
                  style: GoogleFonts.cairo(color: AppColors.textDark, fontSize: 19, fontWeight: FontWeight.bold, height: 1.2),
                ),
              ],
            ),
          ),
          // Notification bell
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
          // Logo
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Image.asset('assets/images/android-chrome-512x512.png', width: 24),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
    );
  }



  Widget _buildAdsSection() {
    if (_adsLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: List.generate(2, (i) => Container(
            height: 90,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: Colors.grey.shade200)),
        ),
      );
    }

    if (_ads.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
          ),
          child: Row(
            children: [
              Icon(Icons.campaign_outlined, color: Colors.grey.shade300, size: 36),
              const SizedBox(width: 12),
              Text('لا توجد إعلانات حالياً', style: GoogleFonts.cairo(color: Colors.grey, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _ads.asMap().entries.map((entry) {
          final index = entry.key;
          final ad = entry.value;
          final title = ad['titleAr'] ?? ad['title'] ?? '';
          final body = (ad['descriptionAr'] ?? ad['body'] ?? ad['description'] ?? '').toString().replaceAll(RegExp(r'[#*\[\]\(\)\r\n]'), '');
          final adType = (ad['adType'] ?? '').toString();
          final date = ad['startDate'] ?? ad['date'] ?? ad['createdAt'] ?? '';
          final imageUrl = (ad['imageUrl'] ?? '').toString();
          final tagColor = _adTagColor(adType);

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AdDetailsScreen(ad: ad)),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: 90,
                    decoration: BoxDecoration(
                      color: tagColor,
                      borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  if (imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(imageUrl, width: 52, height: 52, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 52, height: 52,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: tagColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.campaign_rounded, color: tagColor, size: 22),
                          )),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: tagColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(_adTagIcon(adType), color: tagColor, size: 22),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (adType.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: tagColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                                  child: Text(_adTypeLabel(adType), style: GoogleFonts.cairo(fontSize: 9, color: tagColor, fontWeight: FontWeight.bold)),
                                ),
                              const Spacer(),
                              if (date.isNotEmpty)
                                Text(_formatAdDate(date), style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey.shade400)),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                          const SizedBox(height: 2),
                          Text(body, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Icon(Icons.arrow_back_ios_new, size: 13, color: Colors.grey.shade300),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (750 + index * 80).ms).slideX(begin: 0.05, end: 0),
          );
        }).toList(),
      ),
    );
  }

  Color _adTagColor(String adType) {
    if (adType == 'OFFER' || adType == 'DISCOUNT') return Colors.green;
    if (adType == 'ALERT' || adType == 'WARNING') return Colors.orange;
    if (adType == 'NEW') return const Color(0xFF0984E3);
    return AppColors.primary;
  }

  IconData _adTagIcon(String adType) {
    if (adType == 'OFFER' || adType == 'DISCOUNT') return Icons.local_offer_rounded;
    if (adType == 'ALERT' || adType == 'WARNING') return Icons.warning_amber_rounded;
    if (adType == 'NEW') return Icons.new_releases_rounded;
    return Icons.campaign_rounded;
  }

  String _adTypeLabel(String adType) {
    switch (adType) {
      case 'CARD': return 'إعلان';
      case 'OFFER': return 'عرض';
      case 'DISCOUNT': return 'خصم';
      case 'ALERT': return 'تنبيه';
      case 'NEW': return 'جديد';
      default: return adType;
    }
  }

  Widget _buildCardAdsSection() {
    if (_cardAdsLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: List.generate(2, (i) => Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: Colors.grey.shade200)),
        ),
      );
    }

    if (_cardAds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _cardAds.asMap().entries.map((entry) {
          final index = entry.key;
          final ad = entry.value;
          final title = ad['titleAr'] ?? ad['title'] ?? '';
          final body = (ad['descriptionAr'] ?? '').toString().replaceAll(RegExp(r'[#*\[\]\(\)\r\n]'), '');
          final imageUrls = (ad['imageUrl'] ?? '').toString().split(',').map((u) => u.trim()).where((u) => u.startsWith('http')).toList();
          final firstImage = imageUrls.isNotEmpty ? imageUrls.first : '';

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AdDetailsScreen(ad: ad)),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  // Product Image
                  if (firstImage.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
                      child: Image.network(firstImage, width: 100, height: 100, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 100, height: 100,
                            color: Colors.grey.shade100,
                            child: const Icon(Icons.image_outlined, color: Colors.grey, size: 32),
                          )),
                    )
                  else
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
                      ),
                      child: const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 32),
                    ),
                  const SizedBox(width: 14),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imageUrls.length > 1)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0984E3).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('${imageUrls.length} صور', style: GoogleFonts.cairo(fontSize: 9, color: const Color(0xFF0984E3), fontWeight: FontWeight.bold)),
                            ),
                          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                          const SizedBox(height: 4),
                          Text(body, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade500, height: 1.4)),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Icon(Icons.arrow_back_ios_new, size: 13, color: Colors.grey.shade300),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (850 + index * 80).ms).slideX(begin: 0.05, end: 0),
          );
        }).toList(),
      ),
    );
  }

  String _formatAdDate(String raw) {
    try {
      // Handle dd-MM-yyyy format
      if (raw.contains('-') && raw.length == 10) {
        final parts = raw.split('-');
        if (parts.length == 3 && parts[0].length == 2) {
          return '${parts[0]}/${parts[1]}/${parts[2]}';
        }
      }
      final dt = DateTime.parse(raw);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays == 0) return 'اليوم';
      if (diff.inDays == 1) return 'أمس';
      if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
      return '${dt.day}/${dt.month}';
    } catch (_) { return raw; }
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

            // Format date
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

            // Get icon based on screen name
            IconData notifIcon = Icons.notifications_outlined;
            Color notifColor = AppColors.primary;
            String? screen = item['screenName'] ?? item['SCREEN_NAME'];
            if (screen == 'ORDER_VIEW' || screen == 'ORDERS_WORK' || screen == 'ORDERS_WAIT') {
              notifIcon = Icons.shopping_bag_outlined;
              notifColor = const Color(0xFF0984E3);
            } else if (screen == 'REPORT_DETAILS' || screen == 'REPORTS') {
              notifIcon = Icons.description_outlined;
              notifColor = const Color(0xFF6C5CE7);
            }

            return Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _handleNotificationClick(item),
                    borderRadius: BorderRadius.circular(index == 0 && isLast ? 18 : index == 0 ? const BorderRadius.vertical(top: Radius.circular(18)).topLeft.x : isLast ? const BorderRadius.vertical(bottom: Radius.circular(18)).bottomLeft.x : 0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isRead ? Colors.grey.shade100 : notifColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(notifIcon, color: isRead ? Colors.grey : notifColor, size: 20),
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(formattedTime, style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey)),
                              if (!isRead) ...[
                                const SizedBox(height: 4),
                                Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                ),
                              ],
                            ],
                          ),
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
              Navigator.push(context, MaterialPageRoute(builder: (c) => const OrdersScreen()));
            } else if (index == 2) {
              Navigator.push(context, MaterialPageRoute(builder: (c) => const ReportsScreen()));
            } else if (index == 3) {
              if (UserSession.instance.canViewPrices) {
                Navigator.push(context, MaterialPageRoute(builder: (c) => const InvoicesScreen()));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (c) => const UserProfileScreen()));
              }
            } else if (index == 4) {
              Navigator.push(context, MaterialPageRoute(builder: (c) => const UserProfileScreen()));
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
            _buildNavItem(Icons.shopping_bag_outlined, 'طلباتي', 1),
            _buildNavItem(Icons.description_outlined, 'الكشوفات', 2),
            if (UserSession.instance.canViewPrices)
              _buildNavItem(Icons.receipt_long_outlined, 'فواتيري', 3),
            _buildNavItem(Icons.person_outline, 'حسابي', UserSession.instance.canViewPrices ? 4 : 3),
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
