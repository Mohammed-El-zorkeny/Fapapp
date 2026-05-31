import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../utils/app_colors.dart';
import '../services/admin_mock_service.dart';

class AdminRepDeliveriesScreen extends StatefulWidget {
  final int repId;
  final String repName;
  final DateTime startDate;
  final DateTime endDate;

  const AdminRepDeliveriesScreen({
    super.key,
    required this.repId,
    required this.repName,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<AdminRepDeliveriesScreen> createState() =>
      _AdminRepDeliveriesScreenState();
}

class _AdminRepDeliveriesScreenState extends State<AdminRepDeliveriesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _invoices = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _invoices = AdminMockService.getDeliveryInvoices(
        repId: widget.repId,
        startDate: widget.startDate,
        endDate: widget.endDate,
      );
      _isLoading = false;
    });
  }

  Color _getStatusColor(int statusCode) {
    switch (statusCode) {
      case 0:
        return Colors.grey.shade600;
      case 1:
        return const Color(0xFFE17055);
      case 2:
        return const Color(0xFF0984E3);
      case 3:
        return const Color(0xFF6C5CE7);
      case 4:
        return const Color(0xFF00B894);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(int statusCode) {
    switch (statusCode) {
      case 0:
        return Icons.inventory_2_rounded;
      case 1:
        return Icons.receipt_long_rounded;
      case 2:
        return Icons.local_shipping_rounded;
      case 3:
        return Icons.location_on_rounded;
      case 4:
        return Icons.check_circle_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = intl.DateFormat('yyyy/MM/dd', 'en_US');
    final moneyFmt = intl.NumberFormat('#,###', 'en_US');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              _buildHeader(dateFmt),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : _invoices.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          itemCount: _invoices.length,
                          itemBuilder: (context, index) {
                            return _buildDeliveryCard(
                              _invoices[index],
                              index,
                              moneyFmt,
                              dateFmt,
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(intl.DateFormat formatter) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.repName,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  'تسليمات: ${formatter.format(widget.startDate)}',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0984E3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_invoices.length} فواتير',
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0984E3),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildDeliveryCard(
    Map<String, dynamic> inv,
    int index,
    intl.NumberFormat moneyFmt,
    intl.DateFormat dateFmt,
  ) {
    String dateStr = '';
    try {
      dateStr = dateFmt.format(DateTime.parse(inv['date']));
    } catch (_) {
      dateStr = inv['date'].toString();
    }

    final amount = (inv['amount'] as num).toDouble();
    final statusCode = inv['statusCode'] as int;
    final statusText = AdminMockService.getDeliveryStatusText(statusCode);
    final statusColor = _getStatusColor(statusCode);
    final statusIcon = _getStatusIcon(statusCode);

    return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inv['customerName'],
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 12,
                                color: AppColors.textLight,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  inv['address'],
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: Colors.grey.shade200,
                indent: 16,
                endIndent: 16,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'رقم الفاتورة',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: AppColors.textLight,
                          ),
                        ),
                        Text(
                          inv['invoiceNo'],
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'القيمة',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: AppColors.textLight,
                          ),
                        ),
                        Text(
                          '${moneyFmt.format(amount.truncate())} ج.م',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      dateStr,
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: statusColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: (300 + index * 50).ms)
        .slideY(begin: 0.03, end: 0);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'لا توجد تسليمات لهذا المندوب في هذا اليوم',
            style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}
