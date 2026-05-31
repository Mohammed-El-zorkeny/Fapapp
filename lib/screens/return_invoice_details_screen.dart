import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../services/api_service.dart';

class ReturnInvoiceDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> returnInvoice;

  const ReturnInvoiceDetailsScreen({super.key, required this.returnInvoice});

  @override
  State<ReturnInvoiceDetailsScreen> createState() =>
      _ReturnInvoiceDetailsScreenState();
}

class _ReturnInvoiceDetailsScreenState
    extends State<ReturnInvoiceDetailsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  List<Map<String, dynamic>> _allItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  // ── computed ─────────────────────────────────────────────────
  List<Map<String, dynamic>> get _soldItems =>
      _allItems.where((i) => _remainingSoldQty(i) > 0).toList();

  List<Map<String, dynamic>> get _returnedItems =>
      _allItems.where((i) => ((i['returnQty'] as num?)?.toInt() ?? 0) > 0).toList();

  int _remainingSoldQty(Map<String, dynamic> item) {
    final sold = (item['saleQty'] as num?)?.toInt() ?? 0;
    final returned = (item['returnQty'] as num?)?.toInt() ?? 0;
    return sold - returned;
  }

  double get _totalSale =>
      _allItems.fold(0.0, (s, i) => s + ((i['saleFinalValue'] as num?)?.toDouble() ?? 0));

  double get _totalReturn =>
      _allItems.fold(0.0, (s, i) => s + ((i['returnFinalValue'] as num?)?.toDouble() ?? 0));

  double get _collected => _totalSale - _totalReturn;
  // ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final returnId =
        int.tryParse(widget.returnInvoice['id']?.toString() ?? '0') ?? 0;
    final invoiceId =
        int.tryParse(widget.returnInvoice['salesInvoiceId']?.toString() ?? '0') ?? 0;

    final result = await _apiService.getReturnInvoiceItems(
      invoiceId: invoiceId,
      returnId: returnId,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result['success']) {
        _allItems = List<Map<String, dynamic>>.from(result['data']);
      } else {
        _errorMessage = result['message'] ?? 'فشل في جلب التفاصيل';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ret = widget.returnInvoice;
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
            ret['autoNumber']?.toString() ?? 'تفاصيل المرتجع',
            style: GoogleFonts.cairo(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── header: invoice info + financials ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  _buildInvoiceHeaderCard(ret),
                  const SizedBox(height: 10),
                  _buildFinancialSummary(),
                ],
              ),
            ),
            // ── sticky tab bar ──
            _buildTabBar(),
            // ── tab content ──
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? _buildError()
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildItemList(_allItems, 'all'),
                            _buildItemList(_soldItems, 'sold'),
                            _buildItemList(_returnedItems, 'returned'),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceHeaderCard(Map<String, dynamic> ret) {
    final autoNumber = ret['autoNumber']?.toString() ?? '---';
    final date = ret['invDate']?.toString() ?? '---';
    final customer = ret['customerName']?.toString() ?? '---';
    final salesNumber = ret['salesInvoiceNumber']?.toString();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _headerCell(
                      Icons.assignment_return_outlined, 'رقم المرتجع', autoNumber,
                      valueColor: Colors.orange.shade800)),
              const SizedBox(width: 10),
              Expanded(
                  child: _headerCell(
                      Icons.calendar_today_outlined, 'التاريخ', date)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _headerCell(
                      Icons.person_outline, 'العميل', customer)),
              if (salesNumber != null) ...[
                const SizedBox(width: 10),
                Expanded(
                    child: _headerCell(
                        Icons.receipt_long_outlined, 'فاتورة البيع', salesNumber)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerCell(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.cairo(
                        fontSize: 10, color: Colors.grey.shade500)),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: valueColor ?? AppColors.textDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Expanded(
              child: _summaryCell(
                  'إجمالي المباع',
                  '${_totalSale.toStringAsFixed(2)} ج.م',
                  Colors.blue.shade700)),
          _divider(),
          Expanded(
              child: _summaryCell(
                  'إجمالي المرتجع',
                  '${_totalReturn.toStringAsFixed(2)} ج.م',
                  Colors.orange.shade700)),
          _divider(),
          Expanded(
              child: _summaryCell(
                  'المحصل',
                  '${_collected.toStringAsFixed(2)} ج.م',
                  Colors.green.shade700,
                  bold: true)),
        ],
      ),
    );
  }

  Widget _summaryCell(String label, String value, Color color,
      {bool bold = false}) {
    return Column(
      children: [
        Text(label,
            style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey.shade500)),
        const SizedBox(height: 3),
        Text(value,
            style: GoogleFonts.cairo(
                fontSize: bold ? 13 : 12,
                fontWeight: bold ? FontWeight.w900 : FontWeight.bold,
                color: color)),
      ],
    );
  }

  Widget _divider() => Container(
      width: 1, height: 36, color: Colors.grey.shade200,
      margin: const EdgeInsets.symmetric(horizontal: 4));

  // ── Tab bar ───────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.grey.shade500,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelStyle:
            GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle:
            GoogleFonts.cairo(fontSize: 13),
        tabs: [
          Tab(
              text:
                  'الكل${_allItems.isNotEmpty ? ' (${_allItems.length})' : ''}'),
          Tab(
              text:
                  'المباع${_soldItems.isNotEmpty ? ' (${_soldItems.length})' : ''}'),
          Tab(
              text:
                  'المرتجع${_returnedItems.isNotEmpty ? ' (${_returnedItems.length})' : ''}'),
        ],
      ),
    );
  }

  // ── Item list ─────────────────────────────────────────────────

  Widget _buildItemList(List<Map<String, dynamic>> items, String type) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('لا توجد أصناف',
                style: GoogleFonts.cairo(
                    fontSize: 15, color: Colors.grey.shade400)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildItemCard(items[i], type),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, String type) {
    final nameAr = item['nameAr']?.toString() ?? 'صنف';
    final itemCode = item['itemCode']?.toString() ?? '---';
    final side = item['itemSide']?.toString();

    final saleQty = (item['saleQty'] as num?)?.toInt() ?? 0;
    final salePrice = (item['salePrice'] as num?)?.toDouble() ?? 0;
    final saleFinal = (item['saleFinalValue'] as num?)?.toDouble() ?? 0;

    final returnQty = (item['returnQty'] as num?)?.toInt() ?? 0;
    final returnFinal = (item['returnFinalValue'] as num?)?.toDouble() ?? 0;
    final remainingQty = saleQty - returnQty;

    final hasReturn = returnQty > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasReturn ? Colors.orange.shade200 : Colors.transparent,
          width: 1.2,
        ),
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
            // ── name + side ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(nameAr,
                      style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textDark)),
                ),
                if (side != null) ...[
                  const SizedBox(width: 8),
                  _sideBadge(side),
                ],
              ],
            ),
            const SizedBox(height: 3),
            Text('#$itemCode',
                style: GoogleFonts.cairo(
                    fontSize: 11, color: Colors.grey.shade500)),
            const SizedBox(height: 10),
            // ── sold row ──
            _detailRow(
              icon: Icons.sell_outlined,
              label: 'المباع',
              qty: saleQty,
              price: salePrice,
              total: saleFinal,
              color: Colors.blue.shade700,
              bgColor: Colors.blue.shade50,
            ),
            // ── returned row (if any) ──
            if (hasReturn) ...[
              const SizedBox(height: 6),
              _detailRow(
                icon: Icons.assignment_return_outlined,
                label: 'المرتجع',
                qty: returnQty,
                price: (item['returnPrice'] as num?)?.toDouble() ?? 0,
                total: returnFinal,
                color: Colors.orange.shade700,
                bgColor: Colors.orange.shade50,
              ),
            ],
            // ── remaining (in "all" tab only when there's a partial return) ──
            if (type == 'all' && hasReturn && remainingQty > 0) ...[
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 14, color: Colors.green.shade700),
                    const SizedBox(width: 6),
                    Text(
                      'المتبقي غير مرتجع: $remainingQty قطعة',
                      style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required int qty,
    required double price,
    required double total,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const Spacer(),
          _miniChip('$qty ×', color),
          const SizedBox(width: 6),
          _miniChip('${price.toStringAsFixed(2)} ج.م', Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            '= ${total.toStringAsFixed(2)} ج.م',
            style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color),
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String text, Color textColor) {
    return Text(text,
        style: GoogleFonts.cairo(fontSize: 11, color: textColor));
  }

  Widget _sideBadge(String side) {
    final isLeft = side.toUpperCase() == 'L';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isLeft ? Colors.red.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(side,
          style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isLeft ? Colors.red : Colors.blue)),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 60),
          const SizedBox(height: 12),
          Text(_errorMessage!,
              style:
                  GoogleFonts.cairo(color: AppColors.textLight, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: _loadItems,
            child:
                Text('إعادة المحاولة', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
