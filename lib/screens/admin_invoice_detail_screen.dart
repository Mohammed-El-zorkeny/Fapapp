import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../utils/app_colors.dart';
import '../services/admin_mock_service.dart';

class AdminInvoiceDetailScreen extends StatefulWidget {
  final String invoiceNo;

  const AdminInvoiceDetailScreen({super.key, required this.invoiceNo});

  @override
  State<AdminInvoiceDetailScreen> createState() =>
      _AdminInvoiceDetailScreenState();
}

class _AdminInvoiceDetailScreenState extends State<AdminInvoiceDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _invoiceData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _invoiceData = AdminMockService.getInvoiceDetail(
        invoiceNo: widget.invoiceNo,
      );
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_invoiceData == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: const Center(child: Text('عفواً، لم يتم العثور على الفاتورة')),
      );
    }

    final dateFmt = intl.DateFormat('yyyy/MM/dd', 'en_US');
    final moneyFmt = intl.NumberFormat('#,###', 'en_US');

    final items = _invoiceData!['items'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeaderSection(_invoiceData!, dateFmt, moneyFmt),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Text(
                  'الأصناف في الفاتورة المرتجعة',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildItemCard(items[index], index, moneyFmt),
                  childCount: items.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        'التفاصيل - ${widget.invoiceNo}',
        style: GoogleFonts.cairo(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: AppColors.textDark,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textDark,
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildHeaderSection(
    Map<String, dynamic> data,
    intl.DateFormat dateFmt,
    intl.NumberFormat moneyFmt,
  ) {
    String dateStr = '';
    try {
      dateStr = dateFmt.format(DateTime.parse(data['date']));
    } catch (_) {
      dateStr = data['date'].toString();
    }

    final totalAmount = (data['totalAmount'] as num).toDouble();
    final returnAmount = (data['returnAmount'] as num).toDouble();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE17055).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFFE17055),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'العميل',
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: AppColors.textLight,
                      ),
                    ),
                    Text(
                      data['customerName'],
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoColumn('رقم الفاتورة', data['invoiceNo']),
              _buildInfoColumn('التاريخ', dateStr),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoColumn(
                'إجمالي الفاتورة',
                '${moneyFmt.format(totalAmount.truncate())} ج.م',
                isMoney: true,
              ),
              _buildInfoColumn(
                'قيمة المرتجع',
                '${moneyFmt.format(returnAmount.truncate())} ج.م',
                isMoney: true,
                isHighlight: true,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildInfoColumn(
    String label,
    String value, {
    bool isMoney = false,
    bool isHighlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textLight),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: isMoney ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: isHighlight ? const Color(0xFFE17055) : AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(
    Map<String, dynamic> item,
    int index,
    intl.NumberFormat moneyFmt,
  ) {
    final unitPrice = (item['unitPrice'] as num).toDouble();
    final isWard = item['direction'] == 'وارد';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item['productName'],
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isWard
                      ? const Color(0xFF00B894).withOpacity(0.1)
                      : const Color(0xFFE17055).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item['direction'],
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isWard
                        ? const Color(0xFF00B894)
                        : const Color(0xFFE17055),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'الكود: ${item['productCode']}',
            style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textLight),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سعر الوحدة',
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: AppColors.textLight,
                      ),
                    ),
                    Text(
                      '${moneyFmt.format(unitPrice.truncate())} ج.م',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'الكمية المرتجعة',
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: AppColors.textLight,
                      ),
                    ),
                    Text(
                      '${item['returnQty']} ${item['returnQty'] == 1 ? 'قطعة' : 'قطع'}',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE17055),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (400 + index * 80).ms).slideX(begin: 0.05, end: 0);
  }
}
