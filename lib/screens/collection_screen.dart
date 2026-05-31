import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_button.dart';
import '../services/api_service.dart';

class CollectionScreen extends StatefulWidget {
  final String? initialInvoiceNumber;
  final double? initialAmount;

  const CollectionScreen({
    super.key,
    this.initialInvoiceNumber,
    this.initialAmount,
  });

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  // ── invoice search ───────────────────────────────────────────
  final TextEditingController _invoiceNumberController = TextEditingController();
  Map<String, dynamic>? _selectedInvoice;
  bool _isFetchingInvoice = false;

  // ── payment form ─────────────────────────────────────────────
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  Map<String, dynamic>? _selectedBank;
  List<Map<String, dynamic>> _banks = [];
  bool _isFetchingBanks = false;
  List<Map<String, dynamic>> _payments = [];
  XFile? _proofImage;
  bool _isLoading = false;

  // ── computed ─────────────────────────────────────────────────
  double get _netToCollect {
    final sale = (_selectedInvoice?['finalValue'] as num?)?.toDouble() ?? 0;
    final ret = (_selectedInvoice?['returnTotal'] as num?)?.toDouble() ?? 0;
    return sale - ret;
  }

  double get _paymentsTotal =>
      _payments.fold(0.0, (s, p) => s + (p['amount'] as double));
  // ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fetchBanks();
    if (widget.initialInvoiceNumber != null &&
        widget.initialInvoiceNumber!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _invoiceNumberController.text = widget.initialInvoiceNumber!;
        _searchByAutoNumber(widget.initialInvoiceNumber!);
      });
    }
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchBanks() async {
    setState(() => _isFetchingBanks = true);
    final result = await _apiService.getBanks();
    if (mounted) {
      setState(() {
        _isFetchingBanks = false;
        if (result['success']) {
          _banks = List<Map<String, dynamic>>.from(
              (result['data'] as List).map((e) => Map<String, dynamic>.from(e)));
        }
      });
    }
  }

  Future<void> _searchByAutoNumber(String autoNumber) async {
    final trimmed = autoNumber.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _isFetchingInvoice = true;
      _selectedInvoice = null;
      _payments = [];
      _amountController.clear();
    });

    final result = await _apiService.getInvoiceByAutoNumber(trimmed);
    if (!mounted) return;

    if (result['success']) {
      final invoice = result['data'] as Map<String, dynamic>;
      setState(() {
        _isFetchingInvoice = false;
        _selectedInvoice = invoice;
        // use initialAmount if provided, otherwise compute from invoice
        final amount = (widget.initialAmount != null && widget.initialAmount! > 0)
            ? widget.initialAmount!
            : _netToCollectFromInvoice(invoice);
        if (amount > 0) {
          _amountController.text = amount.toStringAsFixed(2);
        }
      });
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

  double _netToCollectFromInvoice(Map<String, dynamic> inv) {
    final sale = (inv['finalValue'] as num?)?.toDouble() ?? 0;
    final ret = (inv['returnTotal'] as num?)?.toDouble() ?? 0;
    return sale - ret;
  }

  void _scanQRCode() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: MobileScanner(
          onDetect: (capture) {
            final code = capture.barcodes.firstOrNull?.rawValue;
            if (code != null) {
              Navigator.pop(context);
              _invoiceNumberController.text = code.trim();
              _searchByAutoNumber(code.trim());
            }
          },
        ),
      ),
    );
  }

  void _addPayment() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('أدخل مبلغاً صحيحاً')));
      return;
    }
    if (_selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('اختر البنك / طريقة التحصيل')));
      return;
    }
    setState(() {
      _payments.add({'amount': amount, 'bank': _selectedBank});
      _amountController.clear();
      _selectedBank = null;
    });
  }

  void _removePayment(int index) =>
      setState(() => _payments.removeAt(index));

  Future<void> _pickImage(ImageSource source) async {
    final img = await _picker.pickImage(
        source: source, maxWidth: 1920, maxHeight: 1080, imageQuality: 85);
    if (img != null) setState(() => _proofImage = img);
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('اختر مصدر الصورة',
                  style: GoogleFonts.cairo(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: Text('الكاميرا', style: GoogleFonts.cairo()),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: AppColors.primary),
                title: Text('المعرض', style: GoogleFonts.cairo()),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConfirmSheet() {
    if (_selectedInvoice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء البحث عن الفاتورة أولاً')));
      return;
    }
    if (_payments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أضف مبلغاً على الأقل للتحصيل')));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                Text('تأكيد التحصيل',
                    style: GoogleFonts.cairo(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                // ── summary ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _confirmRow('العميل',
                          _selectedInvoice!['customerName'] ?? '---',
                          Colors.blue.shade700),
                      const Divider(height: 14),
                      _confirmRow('الفاتورة',
                          _selectedInvoice!['autoNumber'] ?? '---',
                          AppColors.textDark),
                      const Divider(height: 14),
                      _confirmRow('إجمالي التحصيل',
                          '${_paymentsTotal.toStringAsFixed(2)} ج.م',
                          Colors.green.shade700,
                          bold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // ── notes ──
                Container(
                  decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300)),
                  child: TextField(
                    controller: _notesController,
                    style: GoogleFonts.cairo(fontSize: 14),
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'ملاحظات (اختياري)...',
                      hintStyle:
                          GoogleFonts.cairo(color: Colors.grey, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
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
                      Navigator.pop(context);
                      _submitCollection();
                    },
                    child: Text('تأكيد وحفظ التحصيل',
                        style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitCollection() async {
    setState(() => _isLoading = true);

    try {
      String? imageBase64;
      String? imageName;
      if (_proofImage != null) {
        final bytes = await _proofImage!.readAsBytes();
        imageBase64 = base64Encode(bytes);
        imageName = _proofImage!.name;
      }

      final customerId =
          int.tryParse(_selectedInvoice!['customerId']?.toString() ?? '0') ?? 0;
      final invoiceId =
          int.tryParse(_selectedInvoice!['id']?.toString() ?? '0') ?? 0;

      List<String> autoNumbers = [];
      bool allSuccess = true;
      String errorMsg = '';

      for (final p in _payments) {
        final result = await _apiService.createPayment(
          bankId: (p['bank']?['id'] as num?)?.toInt() ?? 0,
          customerId: customerId,
          invoiceId: invoiceId,
          value: p['amount'] as double,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          imageBase64: imageBase64,
          imageName: imageName,
        );

        if (result['success']) {
          final no = result['payment']?['autoNumber'];
          if (no != null) autoNumbers.add(no.toString());
        } else {
          allSuccess = false;
          errorMsg = result['message'] ?? 'فشل في التحصيل';
          break;
        }
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (allSuccess) {
        _showSuccessDialog(autoNumbers);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(errorMsg), backgroundColor: AppColors.error));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('حدث خطأ: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  void _showSuccessDialog(List<String> autoNumbers) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 80),
              const SizedBox(height: 16),
              Text('تم حفظ التحصيل بنجاح',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
              const SizedBox(height: 12),
              ...autoNumbers.map((no) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('رقم السند:',
                            style: GoogleFonts.cairo(
                                fontSize: 13, color: Colors.grey.shade600)),
                        Text(no,
                            style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                                fontSize: 14)),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: Text('حسناً',
                      style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
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
          title: Text('التحصيل',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('رقم فاتورة البيع'),
                    _buildSearchBar(),
                    if (_isFetchingInvoice)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (_selectedInvoice != null && !_isFetchingInvoice) ...[
                      const SizedBox(height: 16),
                      _buildInvoiceCard(),
                      const SizedBox(height: 24),
                      _buildSectionLabel('تفاصيل التحصيل'),
                      _buildPaymentForm(),
                      const SizedBox(height: 24),
                      _buildSectionLabel('صورة الإيصال'),
                      _buildImagePicker(),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
            if (_selectedInvoice != null && !_isFetchingInvoice)
              _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── widgets ──────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10, right: 2),
        child: Text(label,
            style: GoogleFonts.cairo(
                fontSize: 15,
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
                    color: Colors.black.withValues(alpha: 0.02),
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
                hintText: 'مثال: S-2026-0001',
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
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
                  color: AppColors.primary.withValues(alpha: 0.25),
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

  Widget _buildInvoiceCard() {
    final inv = _selectedInvoice!;
    final sale = (inv['finalValue'] as num?)?.toDouble() ?? 0;
    final ret = (inv['returnTotal'] as num?)?.toDouble() ?? 0;
    final net = sale - ret;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // ── header: invoice + date ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                // invoice badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    inv['autoNumber']?.toString() ?? '---',
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.primary),
                  ),
                ),
                const Spacer(),
                Icon(Icons.calendar_today_outlined,
                    size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(inv['invDate']?.toString() ?? '---',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          // ── customer ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.person_outline,
                      size: 22, color: Colors.blue.shade700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('العميل',
                          style: GoogleFonts.cairo(
                              fontSize: 11, color: Colors.grey.shade500)),
                      Text(
                        inv['customerName']?.toString() ?? '---',
                        style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── financial summary ──
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                    child: _finCell('إجمالي المبيعات',
                        '${sale.toStringAsFixed(2)} ج.م',
                        Colors.blue.shade700)),
                Container(
                    width: 1, height: 36, color: Colors.grey.shade300),
                Expanded(
                    child: _finCell('إجمالي المرتجعات',
                        '${ret.toStringAsFixed(2)} ج.م',
                        Colors.orange.shade700)),
                Container(
                    width: 1, height: 36, color: Colors.grey.shade300),
                Expanded(
                    child: _finCell('المفروض يتحصل',
                        '${net.toStringAsFixed(2)} ج.م',
                        Colors.green.shade700,
                        bold: true)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _finCell(String label, String value, Color color,
      {bool bold = false}) {
    return Column(
      children: [
        Text(label,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
                fontSize: 10, color: Colors.grey.shade500)),
        const SizedBox(height: 3),
        Text(value,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
                fontSize: bold ? 13 : 12,
                fontWeight: bold ? FontWeight.w900 : FontWeight.bold,
                color: color)),
      ],
    );
  }

  Widget _buildPaymentForm() {
    return Column(
      children: [
        // ── amount field ──
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child: TextField(
            controller: _amountController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.cairo(
                fontSize: 16, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'أدخل المبلغ',
              hintStyle:
                  GoogleFonts.cairo(color: Colors.grey, fontSize: 14),
              prefixIcon: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.payments_outlined,
                    color: AppColors.primary, size: 20),
              ),
              suffixText: 'ج.م',
              suffixStyle: GoogleFonts.cairo(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // ── bank dropdown ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Row(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.account_balance_outlined,
                    color: Colors.blue.shade700, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _isFetchingBanks
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Center(
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2))),
                      )
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<Map<String, dynamic>>(
                          isExpanded: true,
                          hint: Text('اختر البنك / طريقة التحصيل',
                              style: GoogleFonts.cairo(
                                  fontSize: 13, color: Colors.grey)),
                          value: _selectedBank,
                          style: GoogleFonts.cairo(
                              fontSize: 14, color: AppColors.textDark),
                          items: _banks.map((b) {
                            return DropdownMenuItem(
                              value: b,
                              child: Text(b['nameAr'] ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (v) =>
                              setState(() => _selectedBank = v),
                        ),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // ── add button ──
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            onPressed: _addPayment,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text('إضافة إلى قائمة التحصيل',
                style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
        ),
        // ── payment list ──
        if (_payments.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
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
            child: Column(
              children: [
                ..._payments.asMap().entries.map((e) {
                  final idx = e.key;
                  final p = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.payments_outlined,
                              size: 16, color: Colors.green.shade700),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '${(p['amount'] as double).toStringAsFixed(2)} ج.م',
                                  style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              Text(p['bank']?['nameAr'] ?? '',
                                  style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removePayment(idx),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.remove_circle_outline,
                              color: AppColors.error, size: 22),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('الإجمالي المدخل:',
                        style: GoogleFonts.cairo(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                    Text('${_paymentsTotal.toStringAsFixed(2)} ج.م',
                        style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        if (_proofImage != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FutureBuilder<Uint8List>(
              future: _proofImage!.readAsBytes(),
              builder: (_, snap) {
                if (snap.hasData) {
                  return Image.memory(snap.data!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover);
                }
                return const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()));
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
        InkWell(
          onTap: _showImageSourceSheet,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _proofImage == null ? Icons.add_a_photo : Icons.edit,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  _proofImage == null ? 'إضافة صورة الإيصال' : 'تغيير الصورة',
                  style: GoogleFonts.cairo(
                      color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── quick totals ──
            Row(
              children: [
                Expanded(
                    child: _miniTotal('المفروض يتحصل',
                        '${_netToCollect.toStringAsFixed(2)} ج.م',
                        Colors.grey.shade700)),
                Container(
                    width: 1, height: 32, color: Colors.grey.shade200,
                    margin: const EdgeInsets.symmetric(horizontal: 12)),
                Expanded(
                    child: _miniTotal('المدخل',
                        '${_paymentsTotal.toStringAsFixed(2)} ج.م',
                        _paymentsTotal >= _netToCollect && _netToCollect > 0
                            ? Colors.green.shade700
                            : AppColors.primary)),
              ],
            ),
            const SizedBox(height: 10),
            CustomButton(
              text: 'حفظ التحصيل',
              isLoading: _isLoading,
              onPressed: _showConfirmSheet,
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _miniTotal(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label,
            style:
                GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade500)),
        Text(value,
            style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: valueColor)),
      ],
    );
  }

  Widget _confirmRow(String label, String value, Color valueColor,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.cairo(
                fontSize: 13, color: Colors.grey.shade600)),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.end,
              style: GoogleFonts.cairo(
                  fontSize: bold ? 15 : 13,
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.w600,
                  color: valueColor)),
        ),
      ],
    );
  }
}

String formatMoney(double value) {
  return value.toStringAsFixed(2);
}
