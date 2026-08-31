import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utils/app_colors.dart';
import '../services/api_service.dart';

class DeliveryInvoiceDetailScreen extends StatefulWidget {
  final Map<dynamic, dynamic> invoice;
  const DeliveryInvoiceDetailScreen({super.key, required this.invoice});

  @override
  State<DeliveryInvoiceDetailScreen> createState() => _DeliveryInvoiceDetailScreenState();
}

class _DeliveryInvoiceDetailScreenState extends State<DeliveryInvoiceDetailScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoadingItems = false;
  bool _isScanning = false;

  List<Map<String, dynamic>> _items = [];
  String _searchQuery = '';

  late Map<String, dynamic> _invoiceData;

  @override
  void initState() {
    super.initState();
    _invoiceData = Map<String, dynamic>.from(widget.invoice);
    _fetchItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fetch items directly from /DeliveryReview/GetInvoiceDetails
  Future<void> _fetchItems() async {
    setState(() => _isLoadingItems = true);
    final int invoiceId = int.tryParse(_invoiceData['id']?.toString() ?? '0') ?? 0;
    final response = await _apiService.getInvoiceDetails(invoiceId);
    if (mounted) {
      setState(() {
        _isLoadingItems = false;
        if (response['success']) {
          final rawItems = response['data'] as List<dynamic>? ?? [];
          _items = rawItems.map((item) {
            final mapItem = Map<String, dynamic>.from(item as Map);
            final double currentQtyCounted = double.tryParse(mapItem['qtyCounted']?.toString() ?? '0') ?? 0.0;
            return {
              ...mapItem,
              'qtyCounted': currentQtyCounted,
            };
          }).toList();
        } else {
          _showSnackBar(response['message'] ?? 'فشل في تحميل أصناف الفاتورة', isError: true);
        }
      });
    }
  }

  Future<void> _updateItemCount(Map<String, dynamic> item, double newQty) async {
    if (newQty < 0) return;
    
    final int detailId = int.tryParse((item['detailId'] ?? item['id'] ?? 0).toString()) ?? 0;
    final int invoiceId = int.tryParse(_invoiceData['id']?.toString() ?? '0') ?? 0;
    
    print('🔍 [_updateItemCount] Calling SaveItemCount for invoiceId: $invoiceId, detailId: $detailId, newQty: $newQty');
    if (detailId == 0) {
      print('⚠️ [_updateItemCount] Warning: detailId is 0!');
      _showSnackBar('خطأ: معرّف بند الفاتورة غير معروف (detailId = 0)', isError: true);
      return;
    }

    final double oldQtyCounted = double.tryParse(item['qtyCounted']?.toString() ?? '0') ?? 0.0;

    // Optimistic local UI update
    setState(() {
      item['qtyCounted'] = newQty;
    });

    final response = await _apiService.saveInvoiceItemCount(
      invoiceId: invoiceId,
      detailId: detailId,
      qtyCounted: newQty,
    );

    if (mounted) {
      if (!response['success']) {
        print('❌ [_updateItemCount Failed] Error message: ${response['message']}');
        // Revert if API failed
        setState(() {
          item['qtyCounted'] = oldQtyCounted;
        });
        _showSnackBar(response['message'] ?? 'فشل حفظ الكمية', isError: true);
      } else {
        print('✅ [_updateItemCount Success] ${response['message']}');
        _showSnackBar('تم حفظ الكمية بنجاح (${newQty.toStringAsFixed(newQty % 1 == 0 ? 0 : 2)})');
      }
    }
  }

  void _showEditQtyDialog(Map<String, dynamic> item) {
    final double currentQtyCounted = double.tryParse(item['qtyCounted']?.toString() ?? '0') ?? 0.0;
    final double origQty = double.tryParse((item['qty'] ?? item['qtyInvoice'] ?? 0).toString()) ?? 0.0;
    final String locationDisplay = (item['locationName'] ?? item['itemSide'] ?? item['location'] ?? 'غير محدد').toString();
    
    final TextEditingController editQtyController = TextEditingController(
      text: currentQtyCounted > 0 
          ? currentQtyCounted.toStringAsFixed(currentQtyCounted % 1 == 0 ? 0 : 2)
          : '',
    );

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'إدخال الكمية',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (item['itemNameAr'] ?? item['itemName'] ?? '').toString(),
                style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 4),
              Text(
                'الكود: ${item['itemCode'] ?? ''} | الموقع/الاتجاه: $locationDisplay',
                style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textLight),
              ),
              if (origQty > 0) ...[
                const SizedBox(height: 2),
                Text(
                  'كمية الفاتورة المطلوبة: ${origQty.toStringAsFixed(origQty % 1 == 0 ? 0 : 2)}',
                  style: GoogleFonts.cairo(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: editQtyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'أدخل الكمية',
                  hintText: '0',
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
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final double? newQty = double.tryParse(editQtyController.text.trim());
                if (newQty == null || newQty < 0) {
                  _showSnackBar('الرجاء إدخال كمية صحيحة', isError: true);
                  return;
                }
                Navigator.pop(context);
                _updateItemCount(item, newQty);
              },
              child: Text('حفظ الكمية', style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _openBarcodeScanner() {
    setState(() => _isScanning = true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
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
                    'مسح الباركود لإدخال الكمية',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                      final String scannedCode = barcode.rawValue!.trim().toLowerCase();
                      Navigator.pop(context);
                      setState(() => _isScanning = false);

                      // Match scanned code in items
                      final itemMatch = _items.firstWhere(
                        (it) => (it['itemCode'] ?? '').toString().toLowerCase() == scannedCode,
                        orElse: () => {},
                      );

                      if (itemMatch.isNotEmpty) {
                        _showEditQtyDialog(itemMatch);
                      } else {
                        _showSnackBar('الصنف الممسوح ($scannedCode) غير موجود بهذه الفاتورة', isError: true);
                      }
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

  List<Map<String, dynamic>> get _filteredItems {
    if (_searchQuery.trim().isEmpty) return _items;
    final query = _searchQuery.trim().toLowerCase();
    return _items.where((item) {
      final name = (item['itemNameAr'] ?? item['itemName'] ?? '').toString().toLowerCase();
      final code = (item['itemCode'] ?? '').toString().toLowerCase();
      return name.contains(query) || code.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final String autoNum = (_invoiceData['autoNumber'] ?? '').toString();
    final String custName = (_invoiceData['customerName'] ?? 'عميل غير معروف').toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: Text(
          'أصناف الفاتورة والعد',
          style: GoogleFonts.cairo(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'فاتورة مبيعات: $autoNum',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'العميل: $custName',
                            style: GoogleFonts.cairo(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_items.length} صنف',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.05, end: 0),

                const SizedBox(height: 16),

                // Search & Barcode Scan Bar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: GoogleFonts.cairo(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'بحث باسم الصنف أو الباركود...',
                          prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _openBarcodeScanner,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.all(12),
                      ),
                      icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                      tooltip: 'مسح الباركود للعد',
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Items Table List (الكود | الاتجاه / الموقع اسم الصنف | الكمية)
                _isLoadingItems
                    ? const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.01),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Table Headers Row
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'الكود',
                                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textLight),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 6,
                                    child: Text(
                                      'الاتجاه / الموقع اسم الصنف',
                                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textLight),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'الكمية',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textLight),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Table Items List
                            _filteredItems.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      'لا توجد أصناف مطابقة للبحث',
                                      style: GoogleFonts.cairo(color: AppColors.textLight),
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _filteredItems.length,
                                    separatorBuilder: (context, index) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final item = _filteredItems[index];
                                      final String itemCode = (item['itemCode'] ?? '').toString();
                                      final String itemName = (item['itemNameAr'] ?? item['itemName'] ?? 'صنف غير معروف').toString();
                                      final String location = (item['locationName'] ?? item['itemSide'] ?? item['location'] ?? '').toString();
                                      final double qtyCounted = double.tryParse(item['qtyCounted']?.toString() ?? '0') ?? 0.0;

                                      return InkWell(
                                        onTap: () => _showEditQtyDialog(item),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                          color: index % 2 == 0 ? Colors.white : Colors.grey.shade50.withOpacity(0.5),
                                          child: Row(
                                            children: [
                                              // 1. Code (الكود)
                                              Expanded(
                                                flex: 3,
                                                child: Text(
                                                  itemCode,
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.textDark,
                                                  ),
                                                ),
                                              ),

                                              // 2. Location & Name (الاتجاه / الموقع اسم الصنف)
                                              Expanded(
                                                flex: 6,
                                                child: Row(
                                                  children: [
                                                    if (location.isNotEmpty) ...[
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                        decoration: BoxDecoration(
                                                          color: Colors.blue.shade50,
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          location,
                                                          style: GoogleFonts.cairo(
                                                            fontSize: 11,
                                                            color: Colors.blue.shade900,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                    ],
                                                    Expanded(
                                                      child: Text(
                                                        itemName,
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: GoogleFonts.cairo(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 13,
                                                          color: AppColors.textDark,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // 3. Counted Qty (الكمية)
                                              Expanded(
                                                flex: 3,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: qtyCounted > 0 ? Colors.green.shade50 : Colors.grey.shade100,
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(
                                                      color: qtyCounted > 0 ? Colors.green.shade300 : Colors.grey.shade300,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        qtyCounted.toStringAsFixed(qtyCounted % 1 == 0 ? 0 : 2),
                                                        style: GoogleFonts.cairo(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold,
                                                          color: qtyCounted > 0 ? Colors.green.shade800 : Colors.grey.shade700,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Icon(
                                                        Icons.edit,
                                                        size: 14,
                                                        color: qtyCounted > 0 ? Colors.green.shade700 : Colors.grey.shade500,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
