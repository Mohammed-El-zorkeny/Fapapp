import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utils/app_colors.dart';
import '../services/api_service.dart';
import 'location_edit_screen.dart';

class StockCountScreen extends StatefulWidget {
  const StockCountScreen({super.key});

  @override
  State<StockCountScreen> createState() => _StockCountScreenState();
}

class _StockCountScreenState extends State<StockCountScreen> {
  final ApiService _apiService = ApiService();

  // Controllers
  final TextEditingController _searchSessionController = TextEditingController();
  final TextEditingController _itemCodeController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // State Variables
  bool _isLoadingSessions = false;
  bool _isLoadingItem = false;
  bool _isSavingCount = false;
  bool _isLoadingDetails = false;
  bool _isScanning = false;

  List<dynamic> _sessions = [];
  List<dynamic> _countedItems = [];
  Map<String, dynamic>? _selectedSession;
  Map<String, dynamic>? _itemDetails;

  String? _errorMessage;
  String _countSearchQuery = '';

  List<dynamic> _availableLocations = [];
  bool _isLoadingLocations = false;
  String? _selectedLocationName;
  int? _selectedLocationId;

  @override
  void initState() {
    super.initState();
    _fetchSessions();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    setState(() => _isLoadingLocations = true);
    final response = await _apiService.getLocations(subStoreId: 1);
    if (mounted) {
      setState(() {
        _availableLocations = response['locations'] ?? [];
        _isLoadingLocations = false;
      });
    }
  }

  void _showLocationPicker() {
    if (_availableLocations.isEmpty && !_isLoadingLocations) {
      _fetchLocations();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationPickerSheet(
        locations: _availableLocations,
        isLoading: _isLoadingLocations,
      ),
    ).then((selectedValue) {
      if (selectedValue != null && mounted) {
        setState(() {
          _selectedLocationId = selectedValue['id'];
          _selectedLocationName = selectedValue['nameAr'];
          _locationController.text = selectedValue['nameAr'] ?? '';
        });
      }
    });
  }

  @override
  void dispose() {
    _searchSessionController.dispose();
    _itemCodeController.dispose();
    _qtyController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // API Calls
  Future<void> _fetchSessions() async {
    setState(() {
      _isLoadingSessions = true;
      _errorMessage = null;
    });

    final response = await _apiService.getActiveCountSessions();

    if (mounted) {
      setState(() {
        _isLoadingSessions = false;
        if (response['success']) {
          _sessions = response['data'] ?? [];
        } else {
          _errorMessage = response['message'] ?? 'خطأ في جلب جلسات الجرد';
        }
      });
    }
  }

  Future<void> _fetchCountedItems() async {
    if (_selectedSession == null) return;

    setState(() {
      _isLoadingDetails = true;
    });

    final response = await _apiService.getCountSessionDetails(
      masterId: _selectedSession!['id'],
    );

    if (mounted) {
      setState(() {
        _isLoadingDetails = false;
        if (response['success']) {
          _countedItems = response['data'] ?? [];
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
      _locationController.clear();
      _selectedLocationName = null;
      _selectedLocationId = null;
      _notesController.clear();
      _itemCodeController.text = code;
    });

    final response = await _apiService.getInfoItem(code.trim());

    if (mounted) {
      setState(() {
        _isLoadingItem = false;
        if (response['success']) {
          _itemDetails = response['item'];
          _qtyController.text = '1'; // Default qty to 1
          final String currentLoc = _itemDetails!['locationName'] ?? _itemDetails!['location'] ?? '';
          _locationController.text = currentLoc;
          if (currentLoc.isNotEmpty && _availableLocations.isNotEmpty) {
            final match = _availableLocations.firstWhere(
              (loc) => loc['nameAr'].toString().trim() == currentLoc.trim(),
              orElse: () => null,
            );
            if (match != null) {
              _selectedLocationId = match['id'];
              _selectedLocationName = match['nameAr'];
            } else {
              _selectedLocationId = null;
              _selectedLocationName = currentLoc;
            }
          } else {
            _selectedLocationId = null;
            _selectedLocationName = null;
          }
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

  Future<void> _saveCountEntry() async {
    if (_selectedSession == null || _itemDetails == null) return;

    final qtyStr = _qtyController.text.trim();
    final notes = _notesController.text.trim();

    if (qtyStr.isEmpty) {
      _showSnackBar('الرجاء إدخال الكمية المجرودة', isError: true);
      return;
    }

    final double? qty = double.tryParse(qtyStr);
    if (qty == null || qty < 0) {
      _showSnackBar('الرجاء إدخال كمية صحيحة', isError: true);
      return;
    }

    if (_selectedLocationId == null) {
      _showSnackBar('الرجاء اختيار موقع التخزين أولاً', isError: true);
      return;
    }

    setState(() {
      _isSavingCount = true;
    });

    final response = await _apiService.saveCountDetail(
      masterId: _selectedSession!['id'],
      itemCode: _itemDetails!['itemCode'],
      qtyCounted: qty,
      location: _selectedLocationId.toString(),
      notes: notes,
    );

    if (mounted) {
      setState(() {
        _isSavingCount = false;
      });

      if (response['success']) {
        _showSnackBar(response['message'] ?? 'تم تسجيل الصنف المجرود بنجاح');
        setState(() {
          _itemDetails = null;
          _itemCodeController.clear();
          _qtyController.clear();
          _locationController.clear();
          _selectedLocationName = null;
          _selectedLocationId = null;
          _notesController.clear();
        });
        _fetchCountedItems();
      } else {
        _showSnackBar(response['message'] ?? 'فشل في تسجيل الصنف المجرود', isError: true);
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

  void _showEditQtyDialog(Map<String, dynamic> detail) {
    final TextEditingController editQtyController = TextEditingController(
      text: (detail['qtyCounted'] ?? '0').toString(),
    );
    final TextEditingController editNotesController = TextEditingController(
      text: detail['notes'] ?? '',
    );
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'تعديل الصنف المجرود',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail['itemName'] ?? '',
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
                  labelText: 'الكمية المجرودة الجديدة',
                  labelStyle: GoogleFonts.cairo(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: editNotesController,
                style: GoogleFonts.cairo(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'ملاحظات',
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
                if (newQty == null || newQty < 0) {
                  _showSnackBar('الرجاء إدخال كمية صحيحة', isError: true);
                  return;
                }
                Navigator.pop(context);

                setState(() {
                  _isLoadingDetails = true;
                });

                final response = await _apiService.updateCountQty(
                  detailId: detail['detailId'],
                  qtyCounted: newQty,
                  notes: editNotesController.text.trim(),
                );

                if (response['success']) {
                  _showSnackBar('تم تعديل الجرد بنجاح');
                } else {
                  _showSnackBar(response['message'] ?? 'فشل في تعديل الجرد', isError: true);
                }
                _fetchCountedItems();
              },
              child: Text('حفظ', style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
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
          _selectedSession == null ? 'جرد الأصناف' : 'جرد الأصناف',
          style: GoogleFonts.cairo(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: _selectedSession != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedSession = null;
                    _itemDetails = null;
                    _itemCodeController.clear();
                    _qtyController.clear();
                    _locationController.clear();
                    _notesController.clear();
                  });
                  _fetchSessions();
                },
              )
            : null,
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: _selectedSession == null ? _buildSessionListLayout() : _buildCountFormLayout(),
        ),
      ),
    );
  }

  // Layout 1: Session Selection
  Widget _buildSessionListLayout() {
    // Filter sessions locally if user typed in search bar
    final searchQuery = _searchSessionController.text.trim().toLowerCase();
    final filteredSessions = _sessions.where((s) {
      final code = (s['autoNumber'] ?? '').toString().toLowerCase();
      final desc = (s['description'] ?? '').toString().toLowerCase();
      return code.contains(searchQuery) || desc.contains(searchQuery);
    }).toList();

    return Column(
      children: [
        // Search Input Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: TextField(
            controller: _searchSessionController,
            style: GoogleFonts.cairo(),
            decoration: InputDecoration(
              hintText: 'البحث برقم الجرد...',
              hintStyle: GoogleFonts.cairo(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  _searchSessionController.clear();
                  setState(() {});
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
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),

        // Sessions List
        Expanded(
          child: _isLoadingSessions
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _errorMessage != null
                  ? Center(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.cairo(color: AppColors.error, fontSize: 16),
                      ),
                    )
                  : filteredSessions.isEmpty
                      ? Center(
                          child: Text(
                            'لا توجد جلسات جرد مفتوحة حالياً',
                            style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredSessions.length,
                          itemBuilder: (context, index) {
                            final session = filteredSessions[index];
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
                                    _selectedSession = session;
                                  });
                                  _fetchCountedItems();
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
                                          Icons.fact_check_rounded,
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
                                              session['autoNumber'] ?? 'جلسة جرد',
                                              style: GoogleFonts.cairo(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                            if (session['description'] != null && session['description'].toString().isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                session['description'],
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.cairo(
                                                  fontSize: 13,
                                                  color: AppColors.textLight,
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 4),
                                            Text(
                                              'تاريخ الجرد: ${session['countDate'] ?? ''}',
                                              style: GoogleFonts.cairo(
                                                fontSize: 11,
                                                color: Colors.grey,
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

  // Layout 2: Count Entry Form
  Widget _buildCountFormLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected Session Summary (Compact red banner)
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
                Expanded(
                  child: Text(
                    'جرد: ${_selectedSession!['autoNumber'] ?? ''}',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
                  ),
                ),
                Text(
                  'تاريخ: ${_selectedSession!['countDate'] ?? ''}',
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
                  'مسح أو إدخال كود الصنف للجرد',
                  style: GoogleFonts.cairo(
                    fontSize: 15,
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

          // Item Details Card & Count Inputs (visible only when itemDetails != null)
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
                  _buildDetailRow('مجموعة الصنف:', _itemDetails!['groupName'] ?? 'غير محدد'),

                  const SizedBox(height: 16),

                  // Location Input (Select List / Dropdown Picker Sheet)
                  Text(
                    'موقع التخزين المجرود فيه الصنف',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _showLocationPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedLocationName ?? 'اختر موقع للتخزين...',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: _selectedLocationName != null ? AppColors.textDark : Colors.grey,
                              fontWeight: _selectedLocationName != null ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          _isLoadingLocations
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                )
                              : const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Count Qty & Notes
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الكمية المجرودة',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _qtyController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ملاحظات الجرد (اختياري)',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _notesController,
                              style: GoogleFonts.cairo(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'اكتب أي ملاحظات هنا...',
                                hintStyle: GoogleFonts.cairo(color: Colors.grey, fontSize: 12),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isSavingCount ? null : _saveCountEntry,
                      child: _isSavingCount
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'تأكيد حفظ جرد الصنف',
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
            ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          // Counted Items Section (Bottom Logs)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'أصناف قمت بجردها في هذه الجلسة',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.primary),
                onPressed: _fetchCountedItems,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Search bar for counted items
          if (_countedItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: TextField(
                style: GoogleFonts.cairo(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'البحث في جردك بالكود أو الاسم...',
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
                    _countSearchQuery = val;
                  });
                },
              ),
            ),

          _isLoadingDetails
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ))
              : _countedItems.isEmpty
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
                          'لم تقم بجرد أي صنف في هذه الجلسة بعد.',
                          style: GoogleFonts.cairo(color: AppColors.textLight),
                        ),
                      ),
                    )
                  : () {
                      final filtered = _countedItems.where((d) {
                        final code = (d['itemCode'] ?? '').toString().toLowerCase();
                        final name = (d['itemName'] ?? '').toString().toLowerCase();
                        final query = _countSearchQuery.toLowerCase();
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
                          final countLog = filtered[index];
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
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Rich text [code] name (side)
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: '[${countLog['itemCode'] ?? ''}] ',
                                              style: GoogleFonts.cairo(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey.shade700,
                                                fontSize: 12,
                                              ),
                                            ),
                                            TextSpan(
                                              text: '${countLog['itemName'] ?? ''} ',
                                              style: GoogleFonts.cairo(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                            if (countLog['itemSide'] != null && countLog['itemSide'].toString().isNotEmpty)
                                              TextSpan(
                                                text: '(${countLog['itemSide']}) ',
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
                                            'موقع: ${countLog['location'] ?? 'غير محدد'}',
                                            style: GoogleFonts.cairo(
                                              fontSize: 11,
                                              color: Colors.red.shade800,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          if (countLog['notes'] != null && countLog['notes'].toString().isNotEmpty) ...[
                                            const Icon(Icons.note_alt_outlined, size: 13, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                countLog['notes'],
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.cairo(
                                                  fontSize: 11,
                                                  color: AppColors.textLight,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Quantity badge and Edit button
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'ك: ${countLog['qtyCounted'] ?? 0}',
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
                                      onPressed: () => _showEditQtyDialog(countLog),
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
