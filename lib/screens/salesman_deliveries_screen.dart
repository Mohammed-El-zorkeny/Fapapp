import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../utils/app_colors.dart';
import '../services/api_service.dart';
import 'salesman_delivery_detail_screen.dart';

class SalesmanDeliveriesScreen extends StatefulWidget {
  const SalesmanDeliveriesScreen({super.key});

  @override
  State<SalesmanDeliveriesScreen> createState() => _SalesmanDeliveriesScreenState();
}

class _SalesmanDeliveriesScreenState extends State<SalesmanDeliveriesScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  List<dynamic> _allInvoices = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchInvoices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchInvoices() async {
    setState(() => _isLoading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final response = await _apiService.getSalesmanInvoices(deliveryDate: dateStr);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response['success']) {
          _allInvoices = response['data'] ?? [];
        } else {
          _allInvoices = [];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'حدث خطأ في تحميل الفواتير', style: GoogleFonts.cairo()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
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

  List<dynamic> _filterInvoicesByTab(int tabIndex) {
    // Tab 0: Pending Assignment
    // Tab 1: Active (Assigned, Out for delivery)
    // Tab 2: Completed (Delivered, Rejected, Returned)
    final filteredByStatus = _allInvoices.where((inv) {
      final status = inv['deliveryStatus'] ?? '';
      if (tabIndex == 0) {
        return status == 'PENDING_ASSIGNMENT';
      } else if (tabIndex == 1) {
        return status == 'ASSIGNED' || status == 'OUT_FOR_DELIVERY';
      } else {
        return status != 'PENDING_ASSIGNMENT' && status != 'ASSIGNED' && status != 'OUT_FOR_DELIVERY';
      }
    }).toList();

    if (_searchQuery.isEmpty) return filteredByStatus;

    return filteredByStatus.where((inv) {
      final autoNum = (inv['autoNumber'] ?? '').toString().toLowerCase();
      final customer = (inv['customerName'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return autoNum.contains(query) || customer.contains(query);
    }).toList();
  }

  Color _getStatusColor(String status) {
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
        return AppColors.textDark;
    }
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
          'التسليمات الخاصة بي',
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
              // Date Filter & Search Header
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    // Date picker field
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  'تاريخ التسليم: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                            Icon(Icons.arrow_drop_down_rounded, color: AppColors.textLight, size: 24),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      style: GoogleFonts.cairo(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'البحث برقم الفاتورة أو اسم العميل...',
                        hintStyle: GoogleFonts.cairo(color: Colors.grey),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Tabs Bar
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textLight,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.normal, fontSize: 13),
                  tabs: const [
                    Tab(text: 'بانتظار التأكيد'),
                    Tab(text: 'تحت التوصيل'),
                    Tab(text: 'منتهية'),
                  ],
                ),
              ),
              // Tab View
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildInvoicesList(0),
                          _buildInvoicesList(1),
                          _buildInvoicesList(2),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoicesList(int tabIndex) {
    final list = _filterInvoicesByTab(tabIndex);

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'لا توجد فواتير لتسليمها في هذا التبويب',
              style: GoogleFonts.cairo(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final inv = list[index];
        final String autoNumber = inv['autoNumber'] ?? '';
        final String customer = inv['customerName'] ?? '';
        final int itemsCount = inv['itemsCount'] ?? 0;
        final String status = inv['deliveryStatus'] ?? '';
        final String statusAr = inv['deliveryStatusAr'] ?? status;
        final String? notes = inv['deliveryNotes'];

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SalesmanDeliveryDetailScreen(invoice: inv),
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
                  color: Colors.black.withOpacity(0.02),
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
                      'فاتورة: $autoNumber',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 15,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _getStatusColor(status).withOpacity(0.2), width: 0.5),
                      ),
                      child: Text(
                        statusAr,
                        style: GoogleFonts.cairo(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        customer,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.format_list_bulleted_rounded, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'عدد الأصناف: $itemsCount',
                      style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 13),
                    ),
                  ],
                ),
                if (notes != null && notes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade100, width: 0.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 14, color: Colors.orange.shade900),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ملاحظة: $notes',
                            style: GoogleFonts.cairo(
                              color: Colors.orange.shade900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ).animate().fadeIn(duration: 300.ms);
      },
    );
  }
}
