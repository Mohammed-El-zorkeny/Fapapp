import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utils/app_colors.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/custom_button.dart';
import 'collection_screen.dart';

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key});

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  int _salesmanId = 0;
  final TextEditingController _invoiceNumberController =
      TextEditingController();
  final TextEditingController _itemSearchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  Map<String, dynamic>? _selectedInvoice;
  List<Map<String, dynamic>> _invoiceItems = [];
  List<Map<String, dynamic>> _filteredInvoiceItems = [];
  bool _isLoading = false;
  bool _isFetchingInvoice = false;
  bool _isFetchingItems = false;
  String _itemSearchQuery = '';

  // ── computed totals ──────────────────────────────────────────
  double get _invoiceTotal =>
      (_selectedInvoice?['finalValue'] as num?)?.toDouble() ?? 0;

  double get _returnTotal => _invoiceItems.fold(0.0, (sum, item) {
        final returnQty = int.tryParse(item['controller'].text) ?? 0;
        return sum + _unitFinalValue(item) * returnQty;
      });

  double get _remainingTotal => _invoiceTotal - _returnTotal;

  double _unitFinalValue(Map<String, dynamic> item) {
    final soldQty = (item['qty'] as num?)?.toInt() ?? 1;
    final lineFinal = (item['finalValue'] as num?)?.toDouble() ?? 0;
    return soldQty > 0 ? lineFinal / soldQty : 0;
  }
  // ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _itemSearchController.addListener(_filterItems);
    _loadSalesmanId();
  }

  Future<void> _loadSalesmanId() async {
    final userData = await _storageService.getUserData();
    if (mounted && userData != null) {
      setState(() {
        _salesmanId = int.tryParse(userData['userId']?.toString() ?? '0') ?? 0;
      });
    }
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _itemSearchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _filterItems() {
    setState(() {
      _itemSearchQuery = _itemSearchController.text.toLowerCase();
      _filteredInvoiceItems = _itemSearchQuery.isEmpty
          ? List.from(_invoiceItems)
          : _invoiceItems.where((item) {
              final name = (item['nameAr'] ?? '').toString().toLowerCase();
              final code = (item['itemCode'] ?? '').toString().toLowerCase();
              return name.contains(_itemSearchQuery) ||
                  code.contains(_itemSearchQuery);
            }).toList();
    });
  }

  Future<void> _searchByAutoNumber(String autoNumber) async {
    final trimmed = autoNumber.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _isFetchingInvoice = true;
      _selectedInvoice = null;
      _invoiceItems = [];
      _filteredInvoiceItems = [];
      _itemSearchController.clear();
    });

    final result = await _apiService.getInvoiceByAutoNumber(trimmed);
    if (!mounted) return;

    if (result['success']) {
      final invoice = result['data'] as Map<String, dynamic>;
      setState(() {
        _isFetchingInvoice = false;
        _selectedInvoice = invoice;
      });
      final id = invoice['id'] is int
          ? invoice['id'] as int
          : int.tryParse(invoice['id'].toString()) ?? 0;
      _fetchInvoiceItems(id);
    } else {
      setState(() => _isFetchingInvoice = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message'] ?? 'لم يتم العثور على الفاتورة'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Future<void> _fetchInvoiceItems(int invoiceId) async {
    setState(() => _isFetchingItems = true);
    final result = await _apiService.getInvoiceItemsById(invoiceId);
    if (!mounted) return;
    setState(() {
      _isFetchingItems = false;
      if (result['success']) {
        _invoiceItems = (result['data'] as List).map((item) {
          return {
            ...Map<String, dynamic>.from(item),
            'controller': TextEditingController(text: '0'),
          };
        }).toList();
        _filterItems();
      } else {
        _invoiceItems = [];
        _filteredInvoiceItems = [];
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message'] ?? 'فشل في تحميل أصناف الفاتورة'),
          backgroundColor: AppColors.error,
        ));
      }
    });
  }

  void _scanQRCode() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: MobileScanner(
          onDetect: (capture) {
            final barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final code = barcodes.first.rawValue;
              if (code != null) {
                Navigator.pop(context);
                _invoiceNumberController.text = code.trim();
                _searchByAutoNumber(code.trim());
              }
            }
          },
        ),
      ),
    );
  }

  void _showConfirmBottomSheet() {
    if (_selectedInvoice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار الفاتورة أولاً')));
      return;
    }

    final hasReturns = _invoiceItems
        .any((item) => (int.tryParse(item['controller'].text) ?? 0) > 0);

    if (!hasReturns) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء إدخال الكميات المرتجعة')));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('ملاحظات (اختياري)',
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300)),
                  child: TextField(
                    controller: _notesController,
                    autofocus: false,
                    style: GoogleFonts.cairo(fontSize: 14),
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'أدخل ملاحظات المرتجع...',
                      hintStyle:
                          GoogleFonts.cairo(color: Colors.grey, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // ── ملخص سريع ──
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _miniSummary('المرتجع',
                          '${_returnTotal.toStringAsFixed(2)} ج.م',
                          Colors.orange.shade700),
                      Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey.shade300),
                      _miniSummary('المتبقي',
                          '${_remainingTotal.toStringAsFixed(2)} ج.م',
                          Colors.green.shade700),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // ── الأزرار ──
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _submitReturn(withPayment: false);
                        },
                        child: Text('عمل المرتجع',
                            style: GoogleFonts.cairo(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _submitReturn(withPayment: true);
                        },
                        child: Text('مرتجع + دفع المتبقي',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniSummary(String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
            style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
        Text(value,
            style: GoogleFonts.cairo(
                fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Future<void> _submitReturn({required bool withPayment}) async {
    final returns = _invoiceItems
        .where((item) => (int.tryParse(item['controller'].text) ?? 0) > 0)
        .map((item) => {
              'invoiceDtlId':
                  item['invoiceDtlId'] ?? item['invoice_dtl_id'] ?? 0,
              'qty': int.tryParse(item['controller'].text) ?? 0,
            })
        .toList();

    setState(() => _isLoading = true);
    final invoiceSalesId =
        int.tryParse(_selectedInvoice!['id']?.toString() ?? '0') ?? 0;

    final result = await _apiService.createReturnInvoice(
      invoiceSalesId: invoiceSalesId,
      salesmanId: _salesmanId,
      notes: _notesController.text,
      items: returns,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      _showSuccessDialog(
        result['return']?['autoNumber'] ?? '---',
        withPayment: withPayment,
        remainingAmount: _remainingTotal,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'فشل في إرسال المرتجع'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  void _showSuccessDialog(String autoNumber,
      {bool withPayment = false, double remainingAmount = 0}) {
    final salesInvoiceNumber =
        _selectedInvoice?['autoNumber']?.toString() ?? '';
    final outerContext = context;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 80),
              const SizedBox(height: 20),
              Text('تم إنشاء فاتورة المرتجع بنجاح',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
              const SizedBox(height: 15),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('رقم المرتجع: ',
                      style: GoogleFonts.cairo(
                          color: Colors.grey.shade700, fontSize: 14)),
                  Text(autoNumber,
                      style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 14)),
                ]),
              ),
              if (withPayment) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('المبلغ المتبقي للتحصيل:',
                          style: GoogleFonts.cairo(
                              fontSize: 13,
                              color: Colors.grey.shade700)),
                      Text('${remainingAmount.toStringAsFixed(2)} ج.م',
                          style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    if (withPayment) {
                      Navigator.pushReplacement(
                        outerContext,
                        MaterialPageRoute(
                          builder: (_) => CollectionScreen(
                            initialInvoiceNumber: salesInvoiceNumber,
                            initialAmount: remainingAmount,
                          ),
                        ),
                      );
                    } else {
                      Navigator.pop(outerContext);
                    }
                  },
                  child: Text(
                    withPayment ? 'الانتقال للتحصيل الآن' : 'حسناً',
                    style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (withPayment) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.pop(outerContext);
                  },
                  child: Text('لاحقاً',
                      style: GoogleFonts.cairo(
                          fontSize: 14, color: Colors.grey)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.textDark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: Text('المرتجعات',
              style: GoogleFonts.cairo(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 22)),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('رقم فاتورة البيع'),
                      _buildSearchBar(),
                      if (_isFetchingInvoice || _isFetchingItems)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 30),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      if (_selectedInvoice != null && !_isFetchingInvoice) ...[
                        const SizedBox(height: 16),
                        _buildInvoiceInfoCard(),
                      ],
                      if (_invoiceItems.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildItemSearchField(),
                        const SizedBox(height: 15),
                        _buildItemsList(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (_invoiceItems.isNotEmpty) _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  // ── widgets ──────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12, right: 4),
        child: Text(title,
            style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark)),
      );

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: TextField(
              controller: _invoiceNumberController,
              textInputAction: TextInputAction.search,
              onSubmitted: _searchByAutoNumber,
              style: GoogleFonts.cairo(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'مثال: S-2025-0001',
                hintStyle: GoogleFonts.cairo(color: Colors.grey, fontSize: 13),
                prefixIcon: const Icon(Icons.receipt_long_outlined,
                    color: AppColors.primary, size: 22),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search_rounded,
                      color: AppColors.primary),
                  onPressed: () =>
                      _searchByAutoNumber(_invoiceNumberController.text),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 16, horizontal: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 58,
          width: 58,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4))
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded,
                color: Colors.white, size: 26),
            onPressed: _scanQRCode,
          ),
        ),
      ],
    );
  }

  /// Invoice info in a 2-column grid
  Widget _buildInvoiceInfoCard() {
    final inv = _selectedInvoice!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _infoCell(Icons.receipt_long, 'رقم الفاتورة',
                    inv['autoNumber']?.toString() ?? '---'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoCell(Icons.person_outline, 'العميل',
                    inv['customerName']?.toString() ?? '---'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _infoCell(Icons.calendar_today_outlined, 'التاريخ',
                    inv['invDate']?.toString() ?? '---'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoCell(
                  Icons.monetization_on_outlined,
                  'الإجمالي',
                  '${inv['finalValue']?.toString() ?? '---'} ج.م',
                  valueColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoCell(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
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

  Widget _buildItemSearchField() => Container(
        height: 50,
        decoration: BoxDecoration(
            color: const Color(0xFFEDEDED),
            borderRadius: BorderRadius.circular(12)),
        child: TextField(
          controller: _itemSearchController,
          style: GoogleFonts.cairo(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'ابحث في أصناف الفاتورة...',
            hintStyle: GoogleFonts.cairo(color: Colors.grey, fontSize: 13),
            prefixIcon:
                const Icon(Icons.search, color: Colors.grey, size: 20),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
      );

  Widget _buildItemsList() {
    if (_filteredInvoiceItems.isEmpty && _itemSearchQuery.isNotEmpty) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('لا توجد نتائج بحث',
                  style:
                      GoogleFonts.cairo(color: AppColors.textLight))));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredInvoiceItems.length,
      itemBuilder: (_, i) => _buildItemCard(_filteredInvoiceItems[i]),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final soldQty = (item['qty'] as num?)?.toInt() ?? 0;
    final returnQty = int.tryParse(item['controller'].text) ?? 0;
    final unitPrice = _unitFinalValue(item);
    final returnAmount = unitPrice * returnQty;
    final side = item['itemSide']?.toString();

    return GestureDetector(
      onTap: () => _updateItemQty(item, soldQty),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: returnQty > 0
                ? Colors.orange.shade300
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: name + side badge ──
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item['nameAr'] ?? 'صنف بدون اسم',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textDark),
                    ),
                  ),
                  if (side != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: side.toUpperCase() == 'L'
                            ? Colors.red.shade50
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        side,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: side.toUpperCase() == 'L'
                              ? Colors.red
                              : Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              // ── Row 2: code + unit price ──
              Row(
                children: [
                  Text('#${item['itemCode'] ?? '---'}',
                      style: GoogleFonts.cairo(
                          fontSize: 11, color: Colors.grey)),
                  const SizedBox(width: 12),
                  Text(
                    'سعر الوحدة: ${unitPrice.toStringAsFixed(2)} ج.م',
                    style: GoogleFonts.cairo(
                        fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // ── Row 3: qty chips + return amount ──
              Row(
                children: [
                  _qtyChip('المباع', '$soldQty', Colors.blue.shade50,
                      Colors.blue.shade700),
                  const SizedBox(width: 8),
                  _qtyChip(
                    'المرتجع',
                    '$returnQty',
                    returnQty > 0
                        ? Colors.orange.shade50
                        : Colors.grey.shade100,
                    returnQty > 0
                        ? Colors.orange.shade700
                        : Colors.grey.shade600,
                  ),
                  const Spacer(),
                  if (returnQty > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${returnAmount.toStringAsFixed(2)} ج.م',
                        style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _qtyChip(
      String label, String value, Color bg, Color textColor) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(label,
              style:
                  GoogleFonts.cairo(fontSize: 9, color: Colors.grey)),
          Text(value,
              style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor)),
        ],
      ),
    );
  }

  void _updateItemQty(Map<String, dynamic> item, int soldQty) {
    int currentQty = int.tryParse(item['controller'].text) ?? 0;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)),
          title: Text('تعديل الكمية المرتجعة',
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center),
          content: StatefulBuilder(
            builder: (context, setDialogState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item['nameAr'] ?? '',
                    style: GoogleFonts.cairo(fontSize: 13),
                    textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text('الكمية المباعة: $soldQty',
                    style: GoogleFonts.cairo(
                        color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        if (currentQty > 0) {
                          setDialogState(() => currentQty--);
                        }
                      },
                      child: const Icon(Icons.remove_circle_outline,
                          color: Colors.red, size: 40),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 25),
                      child: Text('$currentQty',
                          style: GoogleFonts.cairo(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                    ),
                    InkWell(
                      onTap: () {
                        if (currentQty < soldQty) {
                          setDialogState(() => currentQty++);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'الكمية لا يمكن أن تتجاوز المباعة'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                      child: const Icon(Icons.add_circle_outline,
                          color: Colors.green, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء',
                  style: GoogleFonts.cairo(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                setState(
                    () => item['controller'].text = currentQty.toString());
                Navigator.pop(context);
              },
              child: Text('تأكيد',
                  style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    final activeReturns = _invoiceItems
        .where((i) => (int.tryParse(i['controller'].text) ?? 0) > 0)
        .length;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── financial summary ──
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _summaryRow('إجمالي المباع',
                      '${_invoiceTotal.toStringAsFixed(2)} ج.م',
                      Colors.blue.shade700),
                  const Divider(height: 10),
                  _summaryRow('إجمالي المرتجع',
                      '- ${_returnTotal.toStringAsFixed(2)} ج.م',
                      Colors.orange.shade700),
                  const Divider(height: 10),
                  _summaryRow(
                    'المبلغ المتبقي',
                    '${_remainingTotal.toStringAsFixed(2)} ج.م',
                    _remainingTotal < 0
                        ? AppColors.error
                        : Colors.green.shade700,
                    bold: true,
                  ),
                ],
              ),
            ),
            // ── submit row ──
            Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('أصناف مرتجعة',
                        style: GoogleFonts.cairo(
                            fontSize: 12, color: Colors.grey)),
                    Text('$activeReturns صنف',
                        style: GoogleFonts.cairo(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: CustomButton(
                    text: 'عمل المرتجع',
                    isLoading: _isLoading,
                    onPressed: _showConfirmBottomSheet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color valueColor,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.cairo(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight:
                    bold ? FontWeight.bold : FontWeight.normal)),
        Text(value,
            style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight:
                    bold ? FontWeight.bold : FontWeight.w600,
                color: valueColor)),
      ],
    );
  }
}
