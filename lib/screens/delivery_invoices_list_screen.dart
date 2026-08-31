import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../utils/app_colors.dart';
import '../services/api_service.dart';
import 'delivery_invoice_detail_screen.dart';

class DeliveryInvoicesListScreen extends StatefulWidget {
  const DeliveryInvoicesListScreen({super.key});

  @override
  State<DeliveryInvoicesListScreen> createState() => _DeliveryInvoicesListScreenState();
}

class _DeliveryInvoicesListScreenState extends State<DeliveryInvoicesListScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<dynamic> _invoices = [];
  List<dynamic> _filteredInvoices = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchInvoices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final response = await _apiService.getInvoicesByDate(deliveryDate: dateStr);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response['success']) {
          _invoices = response['data'] ?? [];
          _filterInvoices();
        } else {
          _errorMessage = response['message'] ?? 'فشل في تحميل الفواتير';
        }
      });
    }
  }

  void _onSearchChanged() {
    _filterInvoices();
  }

  void _filterInvoices() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredInvoices = List.from(_invoices);
      } else {
        _filteredInvoices = _invoices.where((inv) {
          final autoNum = (inv['autoNumber'] ?? '').toString().toLowerCase();
          final custName = (inv['customerName'] ?? '').toString().toLowerCase();
          return autoNum.contains(query) || custName.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchInvoices();
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'PENDING_ASSIGNMENT':
        return Colors.orange.shade800;
      case 'ASSIGNED':
        return Colors.blue.shade800;
      case 'OUT_FOR_DELIVERY':
        return Colors.purple.shade800;
      case 'DELIVERED_FULL':
        return Colors.green.shade800;
      case 'DELIVERED_PARTIAL':
        return Colors.teal.shade800;
      case 'REJECTED':
        return Colors.red.shade800;
      case 'RETURNED':
        return Colors.grey.shade800;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusBgColor(String? status) {
    switch (status) {
      case 'PENDING_ASSIGNMENT':
        return Colors.orange.shade50;
      case 'ASSIGNED':
        return Colors.blue.shade50;
      case 'OUT_FOR_DELIVERY':
        return Colors.purple.shade50;
      case 'DELIVERED_FULL':
        return Colors.green.shade50;
      case 'DELIVERED_PARTIAL':
        return Colors.teal.shade50;
      case 'REJECTED':
        return Colors.red.shade50;
      case 'RETURNED':
        return Colors.grey.shade100;
      default:
        return Colors.grey.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yyyy/MM/dd').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: Text(
          'مراجعة فواتير التسليم',
          style: GoogleFonts.cairo(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              // Header Filter Section
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    // Date Selector Row
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                                const SizedBox(width: 12),
                                Text(
                                  'تاريخ التسليم: $formattedDate',
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Search Field
                    TextField(
                      controller: _searchController,
                      style: GoogleFonts.cairo(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'ابحث برقم الفاتورة أو اسم العميل...',
                        hintStyle: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: AppColors.textLight),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.background,
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
                    ),
                  ],
                ),
              ),

              // Invoices List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline_rounded, size: 60, color: Colors.red.shade700),
                                  const SizedBox(height: 16),
                                  Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.cairo(fontSize: 16, color: Colors.red.shade900),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _fetchInvoices,
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                    child: Text('إعادة المحاولة', style: GoogleFonts.cairo(color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _filteredInvoices.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.inventory_rounded, size: 60, color: Colors.grey.shade400),
                                    const SizedBox(height: 16),
                                    Text(
                                      'لا توجد فواتير تسليم في هذا التاريخ',
                                      style: GoogleFonts.cairo(fontSize: 16, color: AppColors.textLight),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _fetchInvoices,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _filteredInvoices.length,
                                  itemBuilder: (context, index) {
                                    final inv = _filteredInvoices[index];
                                    final String autoNum = inv['autoNumber'] ?? '';
                                    final String custName = inv['customerName'] ?? 'عميل غير معروف';
                                    final int itemsCount = inv['itemsCount'] ?? 0;
                                    final String status = inv['deliveryStatus'] ?? 'PENDING_ASSIGNMENT';
                                    final String statusAr = inv['deliveryStatusAr'] ?? 'قيد التعيين';
                                    final String? salesman = inv['salesmanName'];

                                    return InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => DeliveryInvoiceDetailScreen(invoice: Map<String, dynamic>.from(inv)),

                                          ),
                                        ).then((value) {
                                          _fetchInvoices();
                                        });
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.03),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                          border: Border.all(color: Colors.grey.shade100),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'فاتورة: $autoNum',
                                                  style: GoogleFonts.cairo(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: AppColors.textDark,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusBgColor(status),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
                                                  ),
                                                  child: Text(
                                                    statusAr,
                                                    style: GoogleFonts.cairo(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: _getStatusColor(status),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'العميل: $custName',
                                              style: GoogleFonts.cairo(
                                                fontSize: 14,
                                                color: AppColors.textDark.withOpacity(0.8),
                                              ),
                                            ),
                                            const Divider(height: 20, thickness: 0.5),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.widgets_outlined, size: 18, color: Colors.grey.shade600),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'عدد الأصناف: $itemsCount',
                                                      style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade700),
                                                    ),
                                                  ],
                                                ),
                                                if (salesman != null && salesman.isNotEmpty)
                                                  Row(
                                                    children: [
                                                      Icon(Icons.person_pin_circle_outlined, size: 18, color: AppColors.primary.withOpacity(0.7)),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        'المندوب: $salesman',
                                                        style: GoogleFonts.cairo(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                                                      ),
                                                    ],
                                                  )
                                                else
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.person_pin_circle_outlined, size: 18, color: Colors.red),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        'لم يتم تعيين مندوب',
                                                        style: GoogleFonts.cairo(fontSize: 13, color: Colors.red, fontWeight: FontWeight.w600),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0);
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
