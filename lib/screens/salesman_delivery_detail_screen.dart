import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'delivery_map_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalesmanDeliveryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> invoice;

  const SalesmanDeliveryDetailScreen({super.key, required this.invoice});

  @override
  State<SalesmanDeliveryDetailScreen> createState() => _SalesmanDeliveryDetailScreenState();
}

class _SalesmanDeliveryDetailScreenState extends State<SalesmanDeliveryDetailScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  bool _isLoading = true;
  List<dynamic> _items = [];
  String _currentStatus = '';
  String _currentStatusAr = '';
  final TextEditingController _notesController = TextEditingController();
  int? _salesmanId;

  // Final statuses dropdown options
  final List<Map<String, String>> _finalStatuses = [
    {'code': 'DELIVERED_FULL', 'nameAr': 'تم التسليم بالكامل'},
    {'code': 'DELIVERED_PARTIAL', 'nameAr': 'تسليم جزئي بمرتجع'},
    {'code': 'REJECTED', 'nameAr': 'تم رفض الاستلام'},
    {'code': 'RETURNED', 'nameAr': 'مرتجعة للمستودع'},
  ];
  String? _selectedFinalStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.invoice['deliveryStatus'] ?? '';
    _currentStatusAr = widget.invoice['deliveryStatusAr'] ?? _currentStatus;
    _notesController.text = widget.invoice['deliveryNotes'] ?? '';
    _selectedFinalStatus = _finalStatuses[0]['code'];
    _loadSalesmanIdAndDetails();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSalesmanIdAndDetails() async {
    // 1. Get Salesman ID
    final userData = await _storageService.getUserData();
    if (userData != null) {
      _salesmanId = int.tryParse(userData['userId']?.toString() ?? '0');
    }
    if (_salesmanId == null || _salesmanId == 0) {
      _salesmanId = widget.invoice['salesmanDeliveryId'];
    }

    // 2. Fetch Details
    final response = await _apiService.getInvoiceDetails(widget.invoice['id']);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response['success']) {
          _items = response['data'] ?? [];
        }
      });
    }
  }

  Future<void> _acceptInvoice() async {
    setState(() => _isLoading = true);
    final response = await _apiService.updateInvoiceDelivery(
      invoiceId: widget.invoice['id'],
      salesmanDeliveryId: _salesmanId,
      deliveryStatus: 'ASSIGNED',
      deliveryNotes: _notesController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (response['success']) {
        setState(() {
          _currentStatus = 'ASSIGNED';
          _currentStatusAr = 'تم تسليمها للمندوب';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم استلام الفاتورة بنجاح', style: GoogleFonts.cairo()), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'فشل استلام الفاتورة', style: GoogleFonts.cairo()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _startDelivery() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('بدء التوصيل والخرائط', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text('سيتم فتح الخريطة من نقطة وقوفك إلى موقع العميل، هل أنت موافق؟', style: GoogleFonts.cairo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('موافق', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      // 1. Get current start location coordinates
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      // 2. Call startDeliveryJourney API
      final response = await _apiService.startDeliveryJourney(
        invoiceId: widget.invoice['id'],
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (response['success']) {
        // 3. Save starting states in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('start_time_${widget.invoice['id']}', DateTime.now().toIso8601String());
        await prefs.setDouble('distance_${widget.invoice['id']}', 0.0);
        await prefs.setDouble('last_lat_${widget.invoice['id']}', position.latitude);
        await prefs.setDouble('last_lng_${widget.invoice['id']}', position.longitude);

        setState(() {
          _isLoading = false;
          _currentStatus = 'OUT_FOR_DELIVERY';
          _currentStatusAr = 'خرجت للتوصيل';
        });

        // 4. Navigate to Map Screen
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeliveryMapScreen(
                invoiceId: widget.invoice['id'],
                customerName: widget.invoice['customerName'] ?? 'عميل',
                locationLink: widget.invoice['locationLink'] ?? '',
                governorateName: widget.invoice['governorateName'] ?? '',
                districtName: widget.invoice['districtName'] ?? '',
                fullAddress: widget.invoice['fullAddress'] ?? '',
              ),
            ),
          );
        }
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'فشل بدء رحلة التوصيل', style: GoogleFonts.cairo()), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الحصول على الموقع: $e', style: GoogleFonts.cairo()), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _updateFinalStatus() async {
    if (_selectedFinalStatus == null) return;
    
    setState(() => _isLoading = true);

    try {
      // 1. Get final location coordinates
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // 2. Retrieve starting details from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final startTimeStr = prefs.getString('start_time_${widget.invoice['id']}');
      final totalKm = prefs.getDouble('distance_${widget.invoice['id']}') ?? 0.0;

      double elapsedMinutes = 0;
      if (startTimeStr != null) {
        final startTime = DateTime.parse(startTimeStr);
        elapsedMinutes = DateTime.now().difference(startTime).inSeconds / 60.0; // Float precision minutes
      }

      // 3. Call endDeliveryJourney API
      final response = await _apiService.endDeliveryJourney(
        invoiceId: widget.invoice['id'],
        latitude: position.latitude,
        longitude: position.longitude,
        totalKm: totalKm,
        totalMinutes: elapsedMinutes,
        deliveryStatus: _selectedFinalStatus!,
        notes: _notesController.text,
      );

      // Clean up SharedPreferences keys
      await prefs.remove('start_time_${widget.invoice['id']}');
      await prefs.remove('distance_${widget.invoice['id']}');
      await prefs.remove('last_lat_${widget.invoice['id']}');
      await prefs.remove('last_lng_${widget.invoice['id']}');

      if (mounted) {
        setState(() => _isLoading = false);
        if (response['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم تحديث وإنهاء حالة الفاتورة بنجاح', style: GoogleFonts.cairo()), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'فشل تحديث وإنهاء حالة الفاتورة', style: GoogleFonts.cairo()), backgroundColor: AppColors.error),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في إنهاء الرحلة: $e', style: GoogleFonts.cairo()), backgroundColor: AppColors.error),
      );
    }
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
      default:
        return AppColors.textDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String autoNumber = widget.invoice['autoNumber'] ?? '';
    final String customer = widget.invoice['customerName'] ?? '';
    final String deliveryDate = widget.invoice['deliveryDate'] ?? '';
    final String gov = widget.invoice['governorateName'] ?? '';
    final String dist = widget.invoice['districtName'] ?? '';
    final String address = widget.invoice['fullAddress'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: Text(
          'تفاصيل فاتورة التسليم',
          style: GoogleFonts.cairo(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. General Invoice Info Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
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
                                          fontSize: 16,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(_currentStatus).withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: _getStatusColor(_currentStatus).withOpacity(0.2), width: 0.5),
                                        ),
                                        child: Text(
                                          _currentStatusAr,
                                          style: GoogleFonts.cairo(
                                            color: _getStatusColor(_currentStatus),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  _buildInfoRow(Icons.person_outline, 'العميل', customer),
                                  const SizedBox(height: 10),
                                  _buildInfoRow(Icons.calendar_today_rounded, 'تاريخ التسليم', deliveryDate),
                                  const SizedBox(height: 10),
                                  _buildInfoRow(Icons.location_on_outlined, 'الموقع والعنوان', 
                                    '${gov.isNotEmpty ? "$gov - " : ""}${dist.isNotEmpty ? "$dist - " : ""}${address.isNotEmpty ? address : "لا يوجد عنوان مسجل"}'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 2. Action section
                            if (_currentStatus == 'PENDING_ASSIGNMENT') ...[
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade800,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.check_circle_outline),
                                label: Text('استلام الفاتورة وتأكيدها', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15)),
                                onPressed: _acceptInvoice,
                              ),
                              const SizedBox(height: 16),
                            ] else if (_currentStatus == 'ASSIGNED') ...[
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.map_outlined),
                                label: Text('الذهاب إلى العميل (بدء التوصيل)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15)),
                                onPressed: _startDelivery,
                              ),
                              const SizedBox(height: 16),
                            ] else if (_currentStatus == 'OUT_FOR_DELIVERY') ...[
                              // Update to final state
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade100),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'تحديث حالة التسليم النهائية',
                                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14),
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      value: _selectedFinalStatus,
                                      style: GoogleFonts.cairo(color: AppColors.textDark, fontSize: 14),
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                      items: _finalStatuses.map((st) {
                                        return DropdownMenuItem<String>(
                                          value: st['code'],
                                          child: Text(st['nameAr']!, style: GoogleFonts.cairo()),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedFinalStatus = val;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _notesController,
                                      style: GoogleFonts.cairo(fontSize: 14),
                                      decoration: InputDecoration(
                                        hintText: 'أضف أي ملاحظات على التسليم هنا...',
                                        hintStyle: GoogleFonts.cairo(color: Colors.grey),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        contentPadding: const EdgeInsets.all(12),
                                      ),
                                      maxLines: 2,
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade800,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(double.infinity, 45),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: _updateFinalStatus,
                                      child: Text('حفظ وإغلاق الفاتورة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(height: 8),
                                    // Button to re-open map if needed
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(double.infinity, 45),
                                        side: BorderSide(color: AppColors.primary),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      icon: Icon(Icons.map_outlined, color: AppColors.primary),
                                      label: Text('عرض موقع العميل بالخريطة المدمجة', style: GoogleFonts.cairo(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => DeliveryMapScreen(
                                              invoiceId: widget.invoice['id'],
                                              customerName: customer,
                                              locationLink: widget.invoice['locationLink'] ?? '',
                                              governorateName: gov,
                                              districtName: dist,
                                              fullAddress: address,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // 3. Items List Title
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              child: Text(
                                'أصناف الفاتورة الجاري تسليمها',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                  fontSize: 15,
                                ),
                              ),
                            ),

                            // 4. Items Table
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade100),
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 24,
                                  headingRowHeight: 48,
                                  dataRowMaxHeight: 56,
                                  columns: [
                                    DataColumn(label: Text('الكود', style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('اسم الصنف', style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('الاتجاه', style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('الكمية', style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
                                  ],
                                  rows: _items.map((item) {
                                    final String code = item['itemCode'] ?? '';
                                    final String name = item['itemNameAr'] ?? '';
                                    final String side = item['itemSide'] ?? 'غير محدد';
                                    final double qty = double.tryParse(item['qty']?.toString() ?? '0') ?? 0;

                                    return DataRow(
                                      cells: [
                                        DataCell(Text(code, style: const TextStyle(fontSize: 13))),
                                        DataCell(SizedBox(
                                          width: 140,
                                          child: Text(
                                            name,
                                            style: GoogleFonts.cairo(fontSize: 12),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        )),
                                        DataCell(Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            side,
                                            style: GoogleFonts.cairo(fontSize: 11, color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                                          ),
                                        )),
                                        DataCell(Text(
                                          qty.toStringAsFixed(0),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        )),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.cairo(color: AppColors.textDark, fontSize: 13),
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
