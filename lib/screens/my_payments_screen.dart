import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../services/api_service.dart';
import 'collection_screen.dart';
import 'notifications_screen.dart';

class MyPaymentsScreen extends StatefulWidget {
  const MyPaymentsScreen({super.key});

  @override
  State<MyPaymentsScreen> createState() => _MyPaymentsScreenState();
}

class _MyPaymentsScreenState extends State<MyPaymentsScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 0;
  static const int _pageSize = 20;

  List<Map<String, dynamic>> get _pageItems {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _payments.length);
    return start >= _payments.length ? [] : _payments.sublist(start, end);
  }

  int get _totalPages =>
      _payments.isEmpty ? 1 : (_payments.length / _pageSize).ceil();

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 0;
    });
    final result = await _apiService.getMyPayments();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result['success']) {
        _payments = List<Map<String, dynamic>>.from(result['data']).reversed.toList();
      } else {
        _errorMessage = result['message'] ?? 'فشل في جلب التحصيلات';
      }
    });
  }

  Future<void> _openAddPayment() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CollectionScreen()),
    );
    _loadPayments();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.textDark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: Text('التحصيلات',
              style: GoogleFonts.cairo(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 22)),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: AppColors.primary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                );
              },
            ),
            IconButton(
              icon:
                  const Icon(Icons.refresh_rounded, color: AppColors.primary),
              onPressed: _loadPayments,
            ),
          ],
        ),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAddPayment,
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text('إضافة دفعة',
              style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 64),
            const SizedBox(height: 16),
            Text(_errorMessage!,
                style: GoogleFonts.cairo(
                    color: AppColors.textLight, fontSize: 15)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: _loadPayments,
              child: Text('إعادة المحاولة',
                  style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    if (_payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('لا توجد تحصيلات بعد',
                style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('اضغط على "إضافة دفعة" لتسجيل تحصيل جديد',
                style: GoogleFonts.cairo(
                    fontSize: 13, color: Colors.grey.shade400)),
          ],
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadPayments,
            color: AppColors.primary,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              itemCount: _pageItems.length,
              itemBuilder: (_, i) => _buildPaymentCard(_pageItems[i]),
            ),
          ),
        ),
        if (_totalPages > 1) _buildPagination(),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _pageBtn('التالي', _currentPage < _totalPages - 1,
              Icons.arrow_back_ios_new_rounded, () {
            setState(() => _currentPage++);
            _scrollController.animateTo(0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut);
          }),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_currentPage + 1} / $_totalPages',
                style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark),
              ),
              Text(
                '${_payments.length} تحصيل',
                style: GoogleFonts.cairo(
                    fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          _pageBtn('السابق', _currentPage > 0,
              Icons.arrow_forward_ios_rounded, () {
            setState(() => _currentPage--);
            _scrollController.animateTo(0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut);
          }),
        ],
      ),
    );
  }

  Widget _pageBtn(
      String label, bool enabled, IconData icon, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: enabled ? onTap : null,
      style: TextButton.styleFrom(
        foregroundColor:
            enabled ? AppColors.primary : Colors.grey.shade400,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      icon: Icon(icon, size: 14),
      label: Text(label,
          style: GoogleFonts.cairo(
              fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> p) {
    final autoNumber = p['autoNumber']?.toString() ?? '---';
    final date = p['transDate']?.toString() ?? '---';
    final customerName = p['customerName']?.toString() ?? '---';
    final bankName = p['bankName']?.toString() ?? '---';
    final value = (p['paymentValue'] as num?)?.toDouble() ?? 0;
    final invoiceNumber = p['invoiceNumber']?.toString();
    final notes = p['notes']?.toString();
    final transType = p['transTypeName']?.toString() ?? 'سند قبض';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── top row: payment number + date + type ──
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_outlined,
                          size: 13, color: Colors.green.shade700),
                      const SizedBox(width: 5),
                      Text(autoNumber,
                          style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.green.shade800)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(transType,
                      style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
                const Spacer(),
                Row(children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(date,
                      style: GoogleFonts.cairo(
                          fontSize: 11, color: Colors.grey.shade500)),
                ]),
              ],
            ),
            const SizedBox(height: 10),
            // ── customer ──
            Row(
              children: [
                Icon(Icons.person_outline,
                    size: 15, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // ── bank ──
            Row(
              children: [
                Icon(Icons.account_balance_outlined,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(bankName,
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            // ── bottom row: invoice ref + amount ──
            Row(
              children: [
                if (invoiceNumber != null) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('الفاتورة',
                            style: GoogleFonts.cairo(
                                fontSize: 10, color: Colors.grey.shade500)),
                        Text(invoiceNumber,
                            style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark)),
                      ],
                    ),
                  ),
                  Container(
                      width: 1,
                      height: 32,
                      color: Colors.grey.shade200,
                      margin: const EdgeInsets.symmetric(horizontal: 10)),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('المبلغ المحصل',
                        style: GoogleFonts.cairo(
                            fontSize: 10, color: Colors.grey.shade500)),
                    Text('${value.toStringAsFixed(2)} ج.م',
                        style: GoogleFonts.cairo(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700)),
                  ],
                ),
              ],
            ),
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.notes_outlined,
                      size: 13, color: Colors.grey.shade400),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(notes,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
