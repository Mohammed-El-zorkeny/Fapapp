import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import 'package:intl/intl.dart' as intl;
import 'order_view_screen.dart';
import 'report_details_screen.dart';
import 'reports_screen.dart';
import 'orders_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<dynamic> get _unreadNotifications => _notifications.where((n) => (n['isRead'] ?? n['IS_READ'] ?? 0) == 0).toList();
  List<dynamic> get _readNotifications => _notifications.where((n) => (n['isRead'] ?? n['IS_READ'] ?? 0) == 1).toList();

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final response = await _apiService.getMyNotifications();
    if (response['success']) {
      setState(() {
        _notifications = response['data'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'فشل تحميل الإشعارات', style: GoogleFonts.cairo())),
        );
      }
    }
  }

  Future<void> _markAsRead(int? id) async {
    final response = await _apiService.markNotificationAsRead(id);
    if (response['success']) {
      _loadNotifications();
    }
  }

  void _handleNotificationClick(Map<String, dynamic> notification) {
    if (notification['isRead'] == 0 || notification['IS_READ'] == 0) {
      _markAsRead(notification['id'] ?? notification['ID']);
    }

    String? screen = notification['screenName'] ?? notification['SCREEN_NAME'];
    var refId = notification['referenceId'] ?? notification['REFERENCE_ID'];

    if (screen == 'ORDER_VIEW' && refId != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => OrderViewScreen(orderId: int.parse(refId.toString()))));
    } else if (screen == 'REPORT_DETAILS' && refId != null) {
      String listName = notification['refName'] ?? notification['REF_NAME'] ?? 'تفاصيل الكشف';
      Navigator.push(context, MaterialPageRoute(builder: (context) => ReportDetailsScreen(priceListId: int.parse(refId.toString()), priceListName: listName)));
    } else if (screen == 'REPORTS') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportsScreen()));
    } else if (screen == 'ORDERS_WORK') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersScreen(initialIndex: 2)));
    } else if (screen == 'ORDERS_WAIT') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersScreen(initialIndex: 3)));
    }
  }

  String _formatTimeAgo(String dateStr) {
    try {
      DateTime dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'الآن';
      if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
      if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
      if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
      return intl.DateFormat('yyyy/MM/dd', 'en_US').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  IconData _getNotifIcon(String? screen) {
    if (screen == 'ORDER_VIEW' || screen == 'ORDERS_WORK' || screen == 'ORDERS_WAIT') return Icons.shopping_bag_outlined;
    if (screen == 'REPORT_DETAILS' || screen == 'REPORTS') return Icons.description_outlined;
    return Icons.notifications_outlined;
  }

  Color _getNotifColor(String? screen) {
    if (screen == 'ORDER_VIEW' || screen == 'ORDERS_WORK' || screen == 'ORDERS_WAIT') return const Color(0xFF0984E3);
    if (screen == 'REPORT_DETAILS' || screen == 'REPORTS') return const Color(0xFF6C5CE7);
    return AppColors.primary;
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
              // Custom AppBar
              _buildCustomAppBar(),
              // Stats Row
              _buildStatsRow(),
              // Tab Bar
              _buildTabBar(),
              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildNotificationList(_notifications),
                          _buildNotificationList(_unreadNotifications),
                          _buildNotificationList(_readNotifications),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: const Icon(Icons.arrow_forward_ios, color: AppColors.textDark, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'الإشعارات',
              style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
          ),
          if (_unreadNotifications.isNotEmpty)
            GestureDetector(
              onTap: () => _markAsRead(null),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Text('قراءة الكل', style: GoogleFonts.cairo(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          _buildStatChip('الكل', _notifications.length, AppColors.textDark, Colors.grey.shade100),
          const SizedBox(width: 8),
          _buildStatChip('غير مقروء', _unreadNotifications.length, AppColors.primary, AppColors.primary.withOpacity(0.08)),
          const SizedBox(width: 8),
          _buildStatChip('مقروء', _readNotifications.length, Colors.green, Colors.green.withOpacity(0.08)),
        ],
      ).animate().fadeIn(delay: 150.ms),
    );
  }

  Widget _buildStatChip(String label, int count, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textLight,
        labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 13),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'الكل'),
          Tab(text: 'غير مقروء'),
          Tab(text: 'مقروء'),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms);
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: 140, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 8),
                Container(height: 10, width: 220, decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: Colors.grey.shade200);
  }

  Widget _buildNotificationList(List<dynamic> notifications) {
    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final item = notifications[index] as Map<String, dynamic>;
          return _buildNotificationCard(item, index)
              .animate()
              .fadeIn(delay: (index * 40).ms, duration: 300.ms)
              .slideX(begin: 0.05, end: 0);
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item, int index) {
    final bool isRead = (item['isRead'] ?? item['IS_READ'] ?? 0) == 1;
    final String dateStr = item['createdAt'] ?? item['CREATED_AT'] ?? '';
    final String formattedTime = _formatTimeAgo(dateStr);
    final String? screen = item['screenName'] ?? item['SCREEN_NAME'];
    final IconData notifIcon = _getNotifIcon(screen);
    final Color notifColor = _getNotifColor(screen);

    return Dismissible(
      key: Key('notif_${item['id'] ?? item['ID'] ?? index}'),
      direction: isRead ? DismissDirection.none : DismissDirection.startToEnd,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.done_all, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text('تم القراءة', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
      onDismissed: (direction) {
        _markAsRead(item['id'] ?? item['ID']);
      },
      child: GestureDetector(
        onTap: () => _handleNotificationClick(item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRead ? Colors.grey.shade100 : notifColor.withOpacity(0.2),
              width: isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isRead ? Colors.black.withOpacity(0.02) : notifColor.withOpacity(0.06),
                blurRadius: isRead ? 8 : 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: isRead ? Colors.grey.shade50 : notifColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  isRead ? Icons.notifications_none : notifIcon,
                  color: isRead ? Colors.grey.shade400 : notifColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['title'] ?? item['TITLE'] ?? 'إشعار جديد',
                            style: GoogleFonts.cairo(
                              fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                              fontSize: 14,
                              color: isRead ? AppColors.textMedium : AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8, height: 8,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(color: notifColor, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['body'] ?? item['BODY'] ?? '',
                      style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 12, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(formattedTime, style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey.shade400)),
                        const Spacer(),
                        if (screen != null) ...[
                          Icon(Icons.arrow_back_ios_new, size: 10, color: notifColor.withOpacity(0.5)),
                          const SizedBox(width: 2),
                          Text('عرض', style: GoogleFonts.cairo(fontSize: 10, color: notifColor.withOpacity(0.7), fontWeight: FontWeight.w600)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_off_outlined, size: 56, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 20),
          Text('لا توجد إشعارات', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMedium)),
          const SizedBox(height: 8),
          Text('ستظهر الإشعارات الجديدة هنا', style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textLight)),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9));
  }
}
