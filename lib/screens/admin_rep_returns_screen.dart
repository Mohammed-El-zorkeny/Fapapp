import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../utils/app_colors.dart';
import '../services/admin_mock_service.dart';
import 'admin_invoice_detail_screen.dart';

class AdminRepReturnsScreen extends StatefulWidget {
  final int repId;
  final String repName;
  final DateTime startDate;
  final DateTime endDate;

  const AdminRepReturnsScreen({
    super.key,
    required this.repId,
    required this.repName,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<AdminRepReturnsScreen> createState() => _AdminRepReturnsScreenState();
}

class _AdminRepReturnsScreenState extends State<AdminRepReturnsScreen> {
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
      _invoices = AdminMockService.getReturnInvoices(
        repId: widget.repId,
        startDate: widget.startDate,
        endDate: widget.endDate,
      );
      _isLoading = false;
    });
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
                            return _buildInvoiceCard(
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
                  'مرتجعات: ${formatter.format(widget.startDate)} → ${formatter.format(widget.endDate)}',
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
              color: const Color(0xFFE17055).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_invoices.length} فاتورة',
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFE17055),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildInvoiceCard(
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

    final totalAmount = (inv['totalAmount'] as num).toDouble();
    final returnAmount = (inv['returnAmount'] as num).toDouble();
    final returnPercent = totalAmount > 0
        ? (returnAmount / totalAmount * 100).toInt()
        : 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AdminInvoiceDetailScreen(invoiceNo: inv['invoiceNo']),
          ),
        );
      },
      child: Container(
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE17055).withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long_rounded,
                    color: Color(0xFFE17055),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    inv['invoiceNo'],
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFE17055),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dateStr,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'اسم العميل',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: AppColors.textLight,
                              ),
                            ),
                            Text(
                              inv['customerName'],
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'إجمالي الفاتورة',
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  color: AppColors.textLight,
                                ),
                              ),
                              Text(
                                '${moneyFmt.format(totalAmount.truncate())} ج.م',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey.shade200,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'قيمة المرتجع',
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  color: AppColors.textLight,
                                ),
                              ),
                              Text(
                                '${moneyFmt.format(returnAmount.truncate())} ج.م',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFE17055),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey.shade200,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'نسبة المرتجع',
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  color: AppColors.textLight,
                                ),
                              ),
                              Text(
                                '$returnPercent%',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: returnPercent > 50
                                      ? AppColors.error
                                      : const Color(0xFFFF9800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'اضغط لعرض تفاصيل الفاتورة',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (300 + index * 60).ms).slideY(begin: 0.03, end: 0);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'لا توجد فواتير مرتجعة لهذا المندوب',
            style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}
