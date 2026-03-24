import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../utils/app_colors.dart';
import '../services/api_service.dart';
import '../widgets/custom_button.dart';

class ItemCardScreen extends StatefulWidget {
  const ItemCardScreen({super.key});

  @override
  State<ItemCardScreen> createState() => _ItemCardScreenState();
}

class _ItemCardScreenState extends State<ItemCardScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _isScanning = false;
  Map<String, dynamic>? _itemInfo;
  List<dynamic> _transactions = [];
  String? _errorMessage;

  // Filters State
  late DateTime _startDate;
  late DateTime _endDate;
  int _storeId = 1;
  int _subStoreId = 1;
  String _storeName = 'المخزن';

  // Empty arrays, strictly from API
  List<dynamic> _stores = [];
  List<dynamic> _subStores = [];

  bool get _isFilterModified {
    final now = DateTime.now();
    final is1stMonth =
        _startDate.year == now.year &&
        _startDate.month == now.month &&
        _startDate.day == 1;
    final isToday =
        _endDate.year == now.year &&
        _endDate.month == now.month &&
        _endDate.day == now.day;
    return _storeId != 1 || _subStoreId != 1 || !is1stMonth || !isToday;
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;
    _loadStoresSilently();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStoresSilently() async {
    final storeRes = await _apiService.getStores();
    final subStoreRes = await _apiService.getSubStores(_storeId);

    if (mounted) {
      setState(() {
        if (storeRes['success'] == true && storeRes['data'] != null) {
          _stores = storeRes['data'];
          if (_stores.isNotEmpty) {
            final defStore = _stores.firstWhere(
              (s) => s['id'] == _storeId,
              orElse: () => _stores.first,
            );
            _storeName = defStore['nameAr'];
          }
        }
        if (subStoreRes['success'] == true && subStoreRes['data'] != null) {
          _subStores = subStoreRes['data'];
        }
      });
    }
  }

  Future<void> _fetchSubStoresForDropdown(
    int storeId,
    StateSetter setModalState,
  ) async {
    final subStoreRes = await _apiService.getSubStores(storeId);
    if (subStoreRes['success'] == true) {
      setModalState(() {
        _subStores = subStoreRes['data'];
        if (_subStores.isNotEmpty) {
          _subStoreId = _subStores.first['id'];
        }
      });
    }
  }

  Future<void> _fetchItemDetails([String? codeOverride]) async {
    final code = codeOverride ?? _searchController.text;
    if (code.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الرجاء إدخال كود الصنف', style: GoogleFonts.cairo()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _itemInfo = null;
      _transactions = [];
      if (codeOverride != null) _searchController.text = codeOverride;
    });

    final sDateStr = DateFormat('dd-MM-yyyy').format(_startDate);
    final eDateStr = DateFormat('dd-MM-yyyy').format(_endDate);

    final res = await _apiService.getItemCardStock(
      itemCode: code.trim(),
      storeId: _storeId,
      subStoreId: _subStoreId,
      startDate: sDateStr,
      endDate: eDateStr,
    );

    setState(() {
      _isLoading = false;
      if (res['success'] == true) {
        _itemInfo = res['itemInfo'];
        _transactions = res['transactions'] ?? [];
      } else {
        _errorMessage =
            res['message'] ?? 'فشل جلب تفاصيل الصنف بالمعطيات الحالية';
      }
    });
  }

  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  top: 20,
                  left: 20,
                  right: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'فلاتر البحث',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Dates Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildDatepickerTile('من تاريخ', _startDate, (
                            date,
                          ) {
                            if (date != null)
                              setModalState(() => _startDate = date);
                          }),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDatepickerTile('إلى تاريخ', _endDate, (
                            date,
                          ) {
                            if (date != null)
                              setModalState(() => _endDate = date);
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Store Dropdown
                    Text(
                      'المخزن',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _stores.isEmpty
                        ? const Center(child: LinearProgressIndicator())
                        : DropdownButtonFormField<int>(
                            value: _stores.any((s) => s['id'] == _storeId)
                                ? _storeId
                                : null,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            style: GoogleFonts.cairo(
                              color: AppColors.textDark,
                              fontSize: 14,
                            ),
                            items: _stores.map<DropdownMenuItem<int>>((s) {
                              return DropdownMenuItem<int>(
                                value: s['id'],
                                child: Text(s['nameAr']),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() {
                                  _storeId = val;
                                  _storeName = _stores.firstWhere(
                                    (s) => s['id'] == val,
                                  )['nameAr'];
                                });
                                _fetchSubStoresForDropdown(val, setModalState);
                              }
                            },
                          ),

                    const SizedBox(height: 16),

                    // Sub Store Dropdown
                    Text(
                      'المخزن الفرعي',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _subStores.isEmpty
                        ? const Center(child: LinearProgressIndicator())
                        : DropdownButtonFormField<int>(
                            value: _subStores.any((s) => s['id'] == _subStoreId)
                                ? _subStoreId
                                : null,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            style: GoogleFonts.cairo(
                              color: AppColors.textDark,
                              fontSize: 14,
                            ),
                            items: _subStores.map<DropdownMenuItem<int>>((s) {
                              return DropdownMenuItem<int>(
                                value: s['id'],
                                child: Text(s['nameAr']),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() {
                                  _subStoreId = val;
                                });
                              }
                            },
                          ),

                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'تطبيق الفلتر',
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {}); // Update color of icon
                        if (_searchController.text.isNotEmpty) {
                          _fetchItemDetails();
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDatepickerTile(
    String label,
    DateTime currentDate,
    Function(DateTime?) onPicked,
  ) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: currentDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) => Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(primary: AppColors.primary),
              textTheme: GoogleFonts.cairoTextTheme(),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            ),
          ),
        );
        onPicked(date);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppColors.textLight,
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  DateFormat('dd-MM-yyyy').format(currentDate),
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
                    'مسح الباركود',
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
                  final barcodes = capture.barcodes;
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
      if (_isScanning) setState(() => _isScanning = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          'كارت صنف المخزن',
          style: GoogleFonts.cairo(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // Top Search & Filter Bar
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'رقم الصنف (مثال: 6300)',
                                hintStyle: GoogleFonts.cairo(
                                  color: AppColors.textLight,
                                  fontSize: 14,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: AppColors.textLight,
                                  size: 20,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              onSubmitted: (val) => _fetchItemDetails(val),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.qr_code_scanner,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            onPressed: _openScanner,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _openFilterBottomSheet,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isFilterModified
                            ? AppColors.primary
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.filter_list_rounded,
                        color: _isFilterModified
                            ? Colors.white
                            : AppColors.textDark,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              child: SizedBox(
                height: 40,
                child: CustomButton(
                  text: 'عرض تقرير الكارت',
                  onPressed: () => _fetchItemDetails(),
                  isLoading: _isLoading,
                ),
              ),
            ),

            // Main Content Area
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _errorMessage != null
                  ? _buildErrorWidget()
                  : _itemInfo != null
                  ? _buildReportView()
                  : _buildEmptyState(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'أدخل الكود واضغط لعرض تقرير حركات الصنف',
            style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textLight),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 60,
            color: AppColors.error.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'حدث خطأ',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildReportView() {
    final String productName =
        _itemInfo!['productName'] ??
        _itemInfo!['itemNameAr'] ??
        _itemInfo!['itemName'] ??
        '';

    return Column(
      children: [
        // Compact Summary Card (Calm Colors)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Name and Code
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${_itemInfo!['itemCode']} - $productName',
                      style: GoogleFonts.cairo(
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_itemInfo!['groupName']} | ${_itemInfo!['itemSide']}',
                      style: GoogleFonts.cairo(
                        color: AppColors.textDark,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Balances Row Highly Compact (Calm green, red)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildBalanceItem(
                      'رصيد افتتاحي',
                      _itemInfo!['openingBalance'],
                      Colors.grey.shade700,
                    ),
                    Container(
                      width: 1,
                      height: 25,
                      color: Colors.grey.shade300,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    _buildBalanceItem(
                      'حركة فترة',
                      _itemInfo!['periodBalance'],
                      Colors.grey.shade700,
                    ),
                    Container(
                      width: 1,
                      height: 25,
                      color: Colors.grey.shade300,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    _buildBalanceItem(
                      'رصيد فعلي',
                      _itemInfo!['actualBalance'],
                      Colors.green.shade700,
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Settings Summary text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تفاصيل الحركات (${_transactions.length})',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                ),
              ),
              Text(
                _storeName,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),

        // Headers
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'التاريخ والنوع',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'وارد',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'منصرف',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'رصيد',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),

        // Transactions Dense List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: _transactions.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              final trx = _transactions[index];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                child: Row(
                  children: [
                    // Col 1: Date and Type
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${trx['transDate']}',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            '${trx['transType']}',
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: AppColors.textLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Col 2: In
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${trx['inQty']}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: trx['inQty'] > 0
                              ? Colors.green.shade700
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                    // Col 3: Out
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${trx['outQty']}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: trx['outQty'] > 0
                              ? Colors.red.shade700
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                    // Col 4: Balance
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${trx['balance']}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildBalanceItem(
    String label,
    dynamic value,
    Color valColor, {
    bool isBold = false,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey.shade600),
          ),
          Text(
            '$value',
            style: GoogleFonts.cairo(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
              color: valColor,
            ),
          ),
        ],
      ),
    );
  }
}
