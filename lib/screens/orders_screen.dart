import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../services/api_service.dart';
import 'order_edit_screen.dart';
import 'order_view_screen.dart';

class OrdersScreen extends StatefulWidget {
  final int initialIndex;
  const OrdersScreen({super.key, this.initialIndex = 0});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedTab = 0;

  final List<_TabItem> _tabs = const [
    _TabItem(label: 'جديد', statusFilter: 'NEW', icon: Icons.fiber_new_rounded),
    _TabItem(label: 'تم إرساله', statusFilter: 'SEND', icon: Icons.send_rounded),
    _TabItem(label: 'قيد العمل', statusFilter: 'WORK', icon: Icons.build_circle_outlined),
    _TabItem(label: 'انتظار الرد', statusFilter: 'WAIT', icon: Icons.pending_actions),
  ];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialIndex > 3 ? 0 : widget.initialIndex;
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await _apiService.getMyOrders();
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result['success']) {
            _orders = result['data'] ?? [];
          } else {
            _errorMessage = result['message'];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'حدث خطأ: $e';
        });
      }
    }
  }

  List<dynamic> _getFiltered(String statusFilter) {
    return _orders.where((order) {
      final statusCode = (order['statusCode'] ?? '').toString().toUpperCase();
      if (statusFilter == 'NEW') return statusCode == 'NEW';
      if (statusFilter == 'SEND') return statusCode == 'SEND';
      if (statusFilter == 'WORK') {
        return statusCode == 'WORK' ||
            statusCode == 'RECEIVED' ||
            statusCode == 'IN_PROGRESS' ||
            statusCode == 'PROCESSING';
      }
      if (statusFilter == 'WAIT') {
        return statusCode == 'WAIT' ||
            statusCode == 'PENDING' ||
            statusCode == 'SEND_TO_CLIENT';
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabSelector(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'طلباتي',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      '${_orders.length} طلب إجمالي',
                      style: GoogleFonts.cairo(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _loadOrders,
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final count = _getFiltered(_tabs[i].statusFilter).length;
          final isSelected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _tabs[i].icon,
                      size: 18,
                      color: isSelected ? Colors.white : AppColors.textLight,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _tabs[i].label,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textLight,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (count > 0) ...[
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.3)
                              : AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.primary,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'جاري تحميل الطلبات...',
              style: GoogleFonts.cairo(color: AppColors.textLight),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'تعذّر تحميل الطلبات',
                style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: AppColors.textLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadOrders,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  'إعادة المحاولة',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final tab = _tabs[_selectedTab];
    final filtered = _getFiltered(tab.statusFilter);

    if (filtered.isEmpty) {
      return _buildEmptyState(tab);
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: AppColors.primary,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return _buildOrderCard(filtered[index], index, tab.statusFilter)
                .animate()
                .fadeIn(delay: (index * 60).ms, duration: 350.ms)
                .slideY(begin: 0.12, end: 0);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(_TabItem tab) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(
                tab.icon,
                size: 52,
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'لا توجد طلبات',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'لا يوجد أي طلبات في قسم "${tab.label}" حالياً',
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(
    Map<String, dynamic> order,
    int index,
    String statusFilter,
  ) {
    final statusAr = order['statusAr'] ?? '---';
    final statusCode = (order['statusCode'] ?? statusFilter).toString().toUpperCase();
    final date = order['invDate'] ?? '---';
    final autoNumber = order['autoNumber'] ?? '---';

    String total = '---';
    if (statusCode == 'NEW' || statusCode == 'SEND' || statusCode == 'RECEIVED') {
      total = order['totalBefore'] != null
          ? order['totalBefore'].toString()
          : (order['finalValue'] != null ? '${order['finalValue']}' : '---');
    } else {
      total = order['finalValue'] != null ? '${order['finalValue']}' : '---';
    }

    final rawId = order['orderId'] ?? order['id'];
    int? orderId;
    if (rawId is int) {
      orderId = rawId;
    } else if (rawId is String) {
      orderId = int.tryParse(rawId);
    }

    final statusColor = _getStatusColor(statusCode);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.08),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            // Colored top accent line
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor, statusColor.withOpacity(0.4)],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),
              ),
            ),

            // Main card body
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                children: [
                  // Header row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 46,
                        width: 46,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              statusColor.withOpacity(0.15),
                              statusColor.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          color: statusColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              autoNumber,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 12,
                                  color: AppColors.textLight,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  date,
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              statusFilter == 'NEW' ? 'جديد' : statusAr,
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Work status info
                  if (statusFilter == 'WORK' || statusCode == 'RECEIVED') ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Colors.blue.shade600,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'تم استلام طلبكم بنجاح، ويجري حاليًا العمل على مراجعته. سيتم الرد خلال يومين.',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Total section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: statusFilter == 'WAIT' ||
                            statusCode == 'SEND_TO_CLIENT'
                        ? _buildWaitTotalUI(order)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'إجمالي الطلب',
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    total != '---' ? total : '0',
                                    style: GoogleFonts.cairo(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      'جنيه',
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: AppColors.textLight,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Action buttons
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FB),
                border: Border(
                  top: BorderSide(color: Color(0xFFEEEEEE)),
                ),
              ),
              child: _buildActionRow(statusFilter, statusCode, orderId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(String statusFilter, String statusCode, int? orderId) {
    if (statusFilter == 'NEW') {
      return Row(
        children: [
          Expanded(
            child: _actionButton(
              label: 'تعديل',
              icon: Icons.edit_outlined,
              isOutlined: true,
              onTap: () {
                if (orderId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderEditScreen(orderId: orderId),
                    ),
                  ).then((v) { if (v == true) _loadOrders(); });
                }
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _actionButton(
              label: 'إرسال للتخطيط',
              icon: Icons.send_rounded,
              onTap: () => _showSendToPlanningDialog(orderId),
            ),
          ),
        ],
      );
    } else if (statusFilter == 'WAIT' || statusCode == 'SEND_TO_CLIENT') {
      return Row(
        children: [
          Expanded(
            child: _actionButton(
              label: 'مشاهدة',
              icon: Icons.visibility_outlined,
              isOutlined: true,
              onTap: () {
                if (orderId != null) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderViewScreen(orderId: orderId),
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _actionButton(
              label: 'تأكيد الطلب',
              icon: Icons.check_circle_outline,
              color: Colors.green,
              onTap: () {
                if (orderId != null) _showConfirmOrderDialog(orderId);
              },
            ),
          ),
        ],
      );
    } else {
      return _actionButton(
        label: 'مشاهدة الطلب',
        icon: Icons.visibility_outlined,
        isOutlined: true,
        isFullWidth: true,
        onTap: () {
          if (orderId != null) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderViewScreen(orderId: orderId),
              ),
            );
          }
        },
      );
    }
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isOutlined = false,
    bool isFullWidth = false,
    Color? color,
  }) {
    final btnColor = color ?? AppColors.primary;
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textDark,
                side: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 17),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: btnColor,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 17, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showSendToPlanningDialog(int? orderId) {
    if (orderId == null) return;
    showDialog(
      context: context,
      builder: (context) => _buildDialog(
        icon: Icons.send_rounded,
        iconColor: AppColors.primary,
        title: 'إرسال للتخطيط',
        content: 'هل أنت متأكد من رغبتك في إرسال هذا الطلب إلى التخطيط؟\nلا يمكن التراجع عن هذه الخطوة.',
        confirmLabel: 'إرسال',
        confirmColor: AppColors.primary,
        onConfirm: () {
          Navigator.pop(context);
          _updateOrderStatus(orderId, 'SEND', 'تم إرسال الطلب');
        },
      ),
    );
  }

  void _showConfirmOrderDialog(int orderId) {
    showDialog(
      context: context,
      builder: (context) => _buildDialog(
        icon: Icons.check_circle_rounded,
        iconColor: Colors.green,
        title: 'تأكيد الطلب',
        content: 'هل أنت متأكد من رغبتك في تأكيد هذا الطلب؟',
        confirmLabel: 'تأكيد',
        confirmColor: Colors.green,
        onConfirm: () {
          Navigator.pop(context);
          _updateOrderStatus(orderId, 'ANSWERED_BY_CLIENT', 'تم تأكيد الطلب');
        },
      ),
    );
  }

  Widget _buildDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        titlePadding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: iconColor),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Text(
          content,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: AppColors.textLight,
            height: 1.6,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFDDDDDD)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'إلغاء',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      confirmLabel,
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitTotalUI(Map<String, dynamic> order) {
    final tBeforeStr = order['totalBefore']?.toString() ?? '-';
    final tAfterStr = order['totalAfter']?.toString() ?? '-';
    final tBefore = double.tryParse(tBeforeStr) ?? 0;
    final tAfter = double.tryParse(tAfterStr) ?? 0;
    final bool isMatch = tBefore > 0 && tBefore == tAfter;
    final bool isChanged = tBefore > 0 && tAfter < tBefore;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMatch)
          _statusBanner(
            'تم عمل طلبك بالكامل وجميع الكميات المطلوبة ✅',
            Colors.green,
          )
        else if (isChanged)
          _statusBanner(
            'تم تعديل بعض كميات أو أصناف هذا الطلب من قبل التخطيط ⚠️',
            Colors.orange,
          ),
        if (isMatch || isChanged) const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إجمالي الطلب',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      tBeforeStr,
                      style: GoogleFonts.cairo(
                        fontSize: isChanged ? 14 : 18,
                        fontWeight: FontWeight.bold,
                        color: isChanged ? Colors.grey : AppColors.textDark,
                        decoration: isChanged ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'ج',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (isChanged) ...[
              const Icon(
                Icons.arrow_back_rounded,
                color: Colors.blueGrey,
                size: 18,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'الإجمالي المعتمد',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        tAfterStr,
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'ج',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _statusBanner(String message, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        message,
        style: GoogleFonts.cairo(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }

  Future<void> _updateOrderStatus(
    int orderId,
    String status,
    String notes,
  ) async {
    setState(() => _isLoading = true);
    final result = await _apiService.updateOrderStatus(
      orderId: orderId,
      status: status,
      notes: notes,
    );
    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'تم التحديث بنجاح',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _loadOrders();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'فشل التحديث',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Color _getStatusColor(String code) {
    switch (code.toUpperCase()) {
      case 'NEW':
        return const Color(0xFFE21C34);
      case 'SEND':
        return const Color(0xFF2196F3);
      case 'RECEIVED':
      case 'WORK':
      case 'PROCESSING':
        return const Color(0xFFFF9800);
      case 'WAIT':
      case 'PENDING':
        return const Color(0xFF9C27B0);
      case 'INVOICE':
      case 'DELIVERED':
        return const Color(0xFF4CAF50);
      case 'CANCELLED':
        return Colors.grey;
      default:
        return AppColors.primary;
    }
  }
}

class _TabItem {
  final String label;
  final String statusFilter;
  final IconData icon;
  const _TabItem({
    required this.label,
    required this.statusFilter,
    required this.icon,
  });
}
