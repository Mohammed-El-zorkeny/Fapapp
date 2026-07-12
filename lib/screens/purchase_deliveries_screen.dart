import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utils/app_colors.dart';
import '../services/api_service.dart';

class PurchaseDeliveriesScreen extends StatefulWidget {
  const PurchaseDeliveriesScreen({super.key});

  @override
  State<PurchaseDeliveriesScreen> createState() => _PurchaseDeliveriesScreenState();
}

class _PurchaseDeliveriesScreenState extends State<PurchaseDeliveriesScreen> {
  final ApiService _apiService = ApiService();
  
  // Controllers
  final TextEditingController _searchInvoiceController = TextEditingController();
  final TextEditingController _itemCodeController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();

  // State Variables
  bool _isLoadingInvoices = false;
  bool _isLoadingItem = false;
  bool _isSavingDelivery = false;
  bool _isLoadingMyDeliveries = false;
  bool _isScanning = false;

  List<dynamic> _invoices = [];
  List<dynamic> _myDeliveries = [];
  Map<String, dynamic>? _selectedInvoice;
  Map<String, dynamic>? _itemDetails;

  String? _errorMessage;
  String _deliverySearchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
    _fetchMyDeliveries();
  }

  @override
  void dispose() {
    _searchInvoiceController.dispose();
    _itemCodeController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  // API Calls
  Future<void> _fetchInvoices({String? autoNumber}) async {
    setState(() {
      _isLoadingInvoices = true;
      _errorMessage = null;
    });

    final response = await _apiService.getPurchaseInvoices(autoNumber: autoNumber);

    if (mounted) {
      setState(() {
        _isLoadingInvoices = false;
        if (response['success']) {
          _invoices = response['data'] ?? [];
        } else {
          _errorMessage = response['message'] ?? 'خطأ في جلب الفواتير';
        }
      });
    }
  }

  Future<void> _fetchMyDeliveries() async {
    setState(() {
      _isLoadingMyDeliveries = true;
    });

    final response = await _apiService.getMyDeliveries(
      invoiceId: _selectedInvoice?['id'],
    );

    if (mounted) {
      setState(() {
        _isLoadingMyDeliveries = false;
        if (response['success']) {
          _myDeliveries = response['data'] ?? [];
        }
      });
    }
  }

  Future<void> _fetchItemDetails(String code) async {
    if (code.trim().isEmpty) return;

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isLoadingItem = true;
      _itemDetails = null;
      _qtyController.clear();
      _itemCodeController.text = code;
    });

    final response = await _apiService.getInfoItem(code.trim());

    if (mounted) {
      setState(() {
        _isLoadingItem = false;
        if (response['success']) {
          _itemDetails = response['item'];
          _qtyController.text = '1'; // Default qty to 1
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'الصنف غير مسجل بالنظام',
                style: GoogleFonts.cairo(),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      });
    }
  }

  Future<void> _saveDelivery() async {
    if (_selectedInvoice == null || _itemDetails == null) return;

    final qtyStr = _qtyController.text.trim();
    if (qtyStr.isEmpty) {
      _showSnackBar('الرجاء إدخال الكمية المستلمة', isError: true);
      return;
    }

    final double? qty = double.tryParse(qtyStr);
    if (qty == null || qty <= 0) {
      _showSnackBar('الرجاء إدخال كمية صحيحة أكبر من صفر', isError: true);
      return;
    }

    setState(() {
      _isSavingDelivery = true;
    });

    final response = await _apiService.receivePurchaseItem(
      invoiceId: _selectedInvoice!['id'],
      itemCode: _itemDetails!['itemCode'],
      qtyReceived: qty,
    );

    if (mounted) {
      setState(() {
        _isSavingDelivery = false;
      });

      if (response['success']) {
        _showSnackBar(response['message'] ?? 'تم تسجيل الاستلام بنجاح');
        setState(() {
          _itemDetails = null;
          _itemCodeController.clear();
          _qtyController.clear();
        });
        _fetchMyDeliveries();
      } else {
        _showSnackBar(response['message'] ?? 'فشل في تسجيل الاستلام', isError: true);
      }
    }
  }

  // Scanning Modal
  void _openScanner() {
    setState(() => _isScanning = true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black87,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'مسح الكود أو الباركود',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => _isScanning = false);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      Navigator.pop(context);
                      setState(() => _isScanning = false);
                      _fetchItemDetails(barcode.rawValue!);
                      break;
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      if (_isScanning) {
        setState(() => _isScanning = false);
      }
    });
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.cairo()),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: Text(
          _selectedInvoice == null ? 'استلام المشتريات' : 'استلام أصناف الفاتورة',
          style: GoogleFonts.cairo(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: _selectedInvoice != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedInvoice = null;
                    _itemDetails = null;
                    _itemCodeController.clear();
                    _qtyController.clear();
                  });
                  _fetchMyDeliveries();
                },
              )
            : null,
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: _selectedInvoice == null ? _buildInvoiceListLayout() : _buildDeliveryFormLayout(),
        ),
      ),
    );
  }

  // Layout 1: Invoice Selection
  Widget _buildInvoiceListLayout() {
    return Column(
      children: [
        // Search Input Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: TextField(
            controller: _searchInvoiceController,
            style: GoogleFonts.cairo(),
            decoration: InputDecoration(
              hintText: 'البحث برقم فاتورة الشراء...',
              hintStyle: GoogleFonts.cairo(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  _searchInvoiceController.clear();
                  _fetchInvoices();
                },
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
            onSubmitted: (value) => _fetchInvoices(autoNumber: value),
          ),
        ),

        // Invoices List
        Expanded(
          child: _isLoadingInvoices
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _errorMessage != null
                  ? Center(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.cairo(color: AppColors.error, fontSize: 16),
                      ),
                    )
                  : _invoices.isEmpty
                      ? Center(
                          child: Text(
                            'لا توجد فواتير مشتريات متاحة',
                            style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _invoices.length,
                          itemBuilder: (context, index) {
                            final inv = _invoices[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shadowColor: AppColors.shadowLight,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedInvoice = inv;
                                  });
                                  _fetchMyDeliveries();
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.description_rounded,
                                          color: Colors.red,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              inv['autoNumber'] ?? 'غير معروف',
                                              style: GoogleFonts.cairo(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'تاريخ الفاتورة: ${inv['invDate'] ?? ''}',
                                              style: GoogleFonts.cairo(
                                                fontSize: 13,
                                                color: AppColors.textLight,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.grey,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0);
                          },
                        ),
        ),
      ],
    );
  }

  // Layout 2: Receive / Delivery Entry Form
  Widget _buildDeliveryFormLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected Invoice Summary Card
          // Selected Invoice Summary (Compact)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'فاتورة: ${_selectedInvoice!['autoNumber'] ?? ''}',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                  ),
                ),
                Text(
                  'تاريخ: ${_selectedInvoice!['invDate'] ?? ''}',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // QR / Barcode Search Input Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مسح أو إدخال كود الصنف',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _itemCodeController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.cairo(),
                        decoration: InputDecoration(
                          hintText: 'أدخل كود الصنف أو الباركود...',
                          hintStyle: GoogleFonts.cairo(color: Colors.grey, fontSize: 13),
                          prefixIcon: const Icon(Icons.qr_code_2_rounded, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                        onSubmitted: (value) => _fetchItemDetails(value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                        onPressed: _openScanner,
                      ),
                    ),
                  ],
                ),
                if (_isLoadingItem)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Item Details Card (visible only when itemDetails != null)
          if (_itemDetails != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.inventory_2_rounded, color: Colors.red, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _itemDetails!['nameAr'] ?? 'صنف غير مسمى',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildDetailRow('كود الصنف:', _itemDetails!['itemCode'] ?? ''),
                  _buildDetailRow('الاتجاه / الجانب:', _itemDetails!['itemSide'] ?? 'غير محدد'),
                  _buildDetailRow('موقع التخزين الحالي:', _itemDetails!['locationName'] ?? _itemDetails!['location'] ?? 'غير محدد'),
                  const SizedBox(height: 20),

                  // Qty Input
                  Text(
                    'الكمية المستلمة',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _qtyController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isSavingDelivery ? null : _saveDelivery,
                          child: _isSavingDelivery
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  'تأكيد استلام الصنف',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          // User's Recent Deliveries Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'آخر الاستلامات الخاصة بك',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.primary),
                onPressed: _fetchMyDeliveries,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Local Search bar for recent deliveries
          if (_myDeliveries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: TextField(
                style: GoogleFonts.cairo(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'البحث في الاستلامات بالكود أو الاسم...',
                  hintStyle: GoogleFonts.cairo(color: Colors.grey, fontSize: 12),
                  prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade100),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _deliverySearchQuery = val;
                  });
                },
              ),
            ),

          _isLoadingMyDeliveries
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ))
              : _myDeliveries.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Center(
                        child: Text(
                          'لم تقم بأي عمليات استلام اليوم بعد.',
                          style: GoogleFonts.cairo(color: AppColors.textLight),
                        ),
                      ),
                    )
                  : () {
                      final filtered = _myDeliveries.where((d) {
                        final code = (d['itemCode'] ?? '').toString().toLowerCase();
                        final name = (d['itemName'] ?? '').toString().toLowerCase();
                        final query = _deliverySearchQuery.toLowerCase();
                        return code.contains(query) || name.contains(query);
                      }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'لا توجد نتائج تطابق البحث',
                              style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 13),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final delivery = filtered[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Row(
                              children: [
                                // Item rich details wrapping on two lines
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: '[${delivery['itemCode'] ?? ''}] ',
                                              style: GoogleFonts.cairo(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey.shade700,
                                                fontSize: 12,
                                              ),
                                            ),
                                            TextSpan(
                                              text: '${delivery['itemName'] ?? ''} ',
                                              style: GoogleFonts.cairo(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                            if (delivery['itemSide'] != null && delivery['itemSide'].toString().isNotEmpty)
                                              TextSpan(
                                                text: '(${delivery['itemSide']}) ',
                                                style: GoogleFonts.cairo(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red,
                                                  fontSize: 12,
                                                ),
                                              ),
                                          ],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_rounded, size: 13, color: Colors.red),
                                          const SizedBox(width: 4),
                                          Text(
                                            'موقع: ${delivery['location'] ?? 'غير محدد'}',
                                            style: GoogleFonts.cairo(
                                              fontSize: 11,
                                              color: Colors.red.shade800,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'التاريخ: ${delivery['deliveryDate'] != null ? delivery['deliveryDate'].toString().split(' ').first : ''}',
                                            style: GoogleFonts.cairo(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Quantity and Edit button
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'ك: ${delivery['qtyReceived'] ?? 0}',
                                        style: GoogleFonts.cairo(
                                          color: Colors.green.shade800,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 18),
                                      onPressed: () => _showEditQtyDialog(delivery),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }(),
        ],
      ),
    );
  }

  void _showEditQtyDialog(Map<String, dynamic> delivery) {
    final TextEditingController editQtyController = TextEditingController(
      text: (delivery['qtyReceived'] ?? '0').toString(),
    );
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'تعديل الكمية المستلمة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                delivery['itemName'] ?? '',
                style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textLight),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: editQtyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'الكمية الجديدة',
                  labelStyle: GoogleFonts.cairo(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final double? newQty = double.tryParse(editQtyController.text);
                if (newQty == null || newQty <= 0) {
                  _showSnackBar('الرجاء إدخال كمية صحيحة', isError: true);
                  return;
                }
                Navigator.pop(context);
                
                setState(() {
                  _isLoadingMyDeliveries = true;
                });
                
                final response = await _apiService.updateDeliveryQty(
                  deliveryId: delivery['deliveryId'],
                  qtyReceived: newQty,
                );
                
                if (response['success']) {
                  _showSnackBar('تم تعديل الكمية بنجاح');
                } else {
                  _showSnackBar(response['message'] ?? 'فشل في تعديل الكمية', isError: true);
                }
                _fetchMyDeliveries();
              },
              child: Text('حفظ', style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 13)),
          Text(value, style: GoogleFonts.cairo(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
