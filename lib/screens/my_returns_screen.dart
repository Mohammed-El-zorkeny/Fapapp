import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../services/api_service.dart';
import 'returns_screen.dart';
import 'return_invoice_details_screen.dart';

class MyReturnsScreen extends StatefulWidget {
  const MyReturnsScreen({super.key});

  @override
  State<MyReturnsScreen> createState() => _MyReturnsScreenState();
}

class _MyReturnsScreenState extends State<MyReturnsScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _returns = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 0;
  static const int _pageSize = 20;

  List<Map<String, dynamic>> get _pageItems {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _returns.length);
    return start >= _returns.length ? [] : _returns.sublist(start, end);
  }

  int get _totalPages =>
      _returns.isEmpty ? 1 : (_returns.length / _pageSize).ceil();

  @override
  void initState() {
    super.initState();
    _loadReturns();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadReturns() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 0;
    });
    final result = await _apiService.getMyReturnInvoices();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result['success']) {
        _returns = List<Map<String, dynamic>>.from(result['data']).reversed.toList();
      } else {
        _errorMessage = result['message'] ?? 'فشل في جلب المرتجعات';
      }
    });
  }

  Future<void> _openCreateReturn() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReturnsScreen()),
    );
    _loadReturns();
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
          title: Text(
            'المرتجعات',
            style: GoogleFonts.cairo(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 22),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
              onPressed: _loadReturns,
            ),
          ],
        ),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openCreateReturn,
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text(
            'إنشاء مرتجع',
            style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
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
              onPressed: _loadReturns,
              child: Text('إعادة المحاولة',
                  style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    if (_returns.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_return_outlined,
                size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('لا توجد مرتجعات بعد',
                style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('اضغط على "إنشاء مرتجع" لإضافة مرتجع جديد',
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
            onRefresh: _loadReturns,
            color: AppColors.primary,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              itemCount: _pageItems.length,
              itemBuilder: (_, i) => _buildReturnCard(_pageItems[i]),
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
                '${_returns.length} مرتجع',
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

  void _openDetails(Map<String, dynamic> ret) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReturnInvoiceDetailsScreen(returnInvoice: ret),
      ),
    );
  }

  Widget _buildReturnCard(Map<String, dynamic> ret) {
    final autoNumber = ret['autoNumber']?.toString() ?? '---';
    final customerName = ret['customerName']?.toString() ?? '---';
    final date = ret['invDate']?.toString() ?? '---';
    final finalValue = (ret['finalValue'] as num?)?.toDouble() ?? 0;
    final salesInvoiceNumber = ret['salesInvoiceNumber']?.toString();
    final salesFinalValue = (ret['salesFinalValue'] as num?)?.toDouble();

    return GestureDetector(
      onTap: () => _openDetails(ret),
      child: Container(
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
            // ── top row: return number + date ──
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.assignment_return_outlined,
                          size: 14, color: Colors.orange.shade700),
                      const SizedBox(width: 5),
                      Text(autoNumber,
                          style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.orange.shade800)),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(date,
                        style: GoogleFonts.cairo(
                            fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            // ── financial row ──
            Row(
              children: [
                // original invoice ref
                if (salesInvoiceNumber != null) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('فاتورة البيع',
                            style: GoogleFonts.cairo(
                                fontSize: 10, color: Colors.grey.shade500)),
                        Text(salesInvoiceNumber,
                            style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark)),
                        if (salesFinalValue != null)
                          Text('${salesFinalValue.toStringAsFixed(2)} ج.م',
                              style: GoogleFonts.cairo(
                                  fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 36, color: Colors.grey.shade200),
                  const SizedBox(width: 12),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('قيمة المرتجع',
                        style: GoogleFonts.cairo(
                            fontSize: 10, color: Colors.grey.shade500)),
                    Text(
                      '${finalValue.toStringAsFixed(2)} ج.م',
                      style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ), // Container
    ); // GestureDetector
  }
}
