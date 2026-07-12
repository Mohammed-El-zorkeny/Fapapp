import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../services/api_service.dart';

class DeliveryInvoiceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> invoice;
  const DeliveryInvoiceDetailScreen({super.key, required this.invoice});

  @override
  State<DeliveryInvoiceDetailScreen> createState() => _DeliveryInvoiceDetailScreenState();
}

class _DeliveryInvoiceDetailScreenState extends State<DeliveryInvoiceDetailScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoadingDropdowns = false;
  bool _isLoadingItems = false;
  bool _isSavingGeneral = false;
  bool _isSavingItemReview = false;

  List<dynamic> _deliveryMen = [];
  List<dynamic> _items = [];
  int? _selectedSalesmanId;
  String _selectedStatus = 'PENDING_ASSIGNMENT';

  final List<Map<String, String>> _statusOptions = [
    {'code': 'PENDING_ASSIGNMENT', 'name': 'في انتظار التخصيص للمندوب'},
    {'code': 'ASSIGNED', 'name': 'تم تسليمها للمندوب'},
    {'code': 'OUT_FOR_DELIVERY', 'name': 'خرجت للتوصيل'},
    {'code': 'DELIVERED_FULL', 'name': 'تم التسليم بالكامل'},
    {'code': 'DELIVERED_PARTIAL', 'name': 'تسليم جزئي بمرتجع'},
    {'code': 'REJECTED', 'name': 'تم رفض الاستلام'},
    {'code': 'RETURNED', 'name': 'مرتجعة للمستودع'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedSalesmanId = widget.invoice['salesmanDeliveryId'];
    _selectedStatus = widget.invoice['deliveryStatus'] ?? 'PENDING_ASSIGNMENT';
    _notesController.text = widget.invoice['deliveryNotes'] ?? '';
    _fetchDeliveryMen();
    _fetchItems();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchDeliveryMen() async {
    setState(() => _isLoadingDropdowns = true);
    final response = await _apiService.getDeliveryMen();
    if (mounted) {
      setState(() {
        _isLoadingDropdowns = false;
        if (response['success']) {
          _deliveryMen = response['data'] ?? [];
        }
      });
    }
  }

  Future<void> _fetchItems() async {
    setState(() => _isLoadingItems = true);
    final response = await _apiService.getInvoiceDetails(widget.invoice['id']);
    if (mounted) {
      setState(() {
        _isLoadingItems = false;
        if (response['success']) {
          _items = response['data'] ?? [];
        } else {
          _showSnackBar(response['message'] ?? 'فشل في تحميل أصناف الفاتورة', isError: true);
        }
      });
    }
  }

  Future<void> _saveGeneralInfo() async {
    setState(() => _isSavingGeneral = true);
    final response = await _apiService.updateInvoiceDelivery(
      invoiceId: widget.invoice['id'],
      salesmanDeliveryId: _selectedSalesmanId,
      deliveryStatus: _selectedStatus,
      deliveryNotes: _notesController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSavingGeneral = false);
      if (response['success']) {
        _showSnackBar(response['message'] ?? 'تم حفظ البيانات بنجاح');
      } else {
        _showSnackBar(response['message'] ?? 'فشل في حفظ البيانات العامة', isError: true);
      }
    }
  }

  Future<void> _toggleItemReview(dynamic item) async {
    final int detailId = item['detailId'];
    final int currentReviewStatus = item['isDeliveryReviewed'] ?? 0;
    final int newReviewStatus = currentReviewStatus == 1 ? 0 : 1;

    setState(() => _isSavingItemReview = true);
    final response = await _apiService.updateItemReview(
      invoiceId: widget.invoice['id'],
      detailId: detailId,
      isReviewed: newReviewStatus,
      reviewAll: false,
    );

    if (mounted) {
      setState(() => _isSavingItemReview = false);
      if (response['success']) {
        setState(() {
          item['isDeliveryReviewed'] = newReviewStatus;
        });
        _showSnackBar(response['message'] ?? 'تم تحديث حالة المراجعة');
      } else {
        _showSnackBar(response['message'] ?? 'فشل في تحديث حالة المراجعة', isError: true);
      }
    }
  }

  Future<void> _reviewAllItems() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'تأكيد مراجعة الكل',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من تعليم جميع أصناف الفاتورة كمراجعة؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('تأكيد', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSavingItemReview = true);
    final response = await _apiService.updateItemReview(
      invoiceId: widget.invoice['id'],
      isReviewed: 1,
      reviewAll: true,
    );

    if (mounted) {
      setState(() => _isSavingItemReview = false);
      if (response['success']) {
        setState(() {
          for (var item in _items) {
            item['isDeliveryReviewed'] = 1;
          }
        });
        _showSnackBar(response['message'] ?? 'تمت مراجعة جميع الأصناف بنجاح');
      } else {
        _showSnackBar(response['message'] ?? 'فشل في مراجعة الكل', isError: true);
      }
    }
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
    final String autoNum = widget.invoice['autoNumber'] ?? '';
    final String custName = widget.invoice['customerName'] ?? 'عميل غير معروف';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: Text(
          'تفاصيل مراجعة الفاتورة',
          style: GoogleFonts.cairo(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: _isLoadingDropdowns && _deliveryMen.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Invoice Header Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'فاتورة مبيعات: $autoNum',
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'العميل: $custName',
                              style: GoogleFonts.cairo(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1, end: 0),

                      const SizedBox(height: 20),

                      // General Settings Form Card
                      Container(
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
                            Text(
                              'بيانات التسليم والمندوب',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textDark,
                              ),
                            ),
                            const Divider(height: 20),

                            // Salesman Dropdown
                            Text(
                              'مندوب التسليم المخصص',
                              style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textLight, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<int>(
                              value: _selectedSalesmanId,
                              style: GoogleFonts.cairo(color: AppColors.textDark, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'اختر المندوب من القائمة...',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: _deliveryMen.map<DropdownMenuItem<int>>((man) {
                                return DropdownMenuItem<int>(
                                  value: man['id'],
                                  child: Text(man['nameAr'] ?? ''),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedSalesmanId = val;
                                });
                              },
                            ),

                            const SizedBox(height: 16),

                            // Delivery Status Dropdown
                            Text(
                              'حالة التسليم للفاتورة',
                              style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textLight, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              style: GoogleFonts.cairo(color: AppColors.textDark, fontSize: 14),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: _statusOptions.map<DropdownMenuItem<String>>((opt) {
                                return DropdownMenuItem<String>(
                                  value: opt['code'],
                                  child: Text(opt['name'] ?? ''),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedStatus = val;
                                  });
                                }
                              },
                            ),

                            const SizedBox(height: 16),

                            // Notes Field
                            Text(
                              'ملاحظات التسليم',
                              style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textLight, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _notesController,
                              style: GoogleFonts.cairo(fontSize: 14),
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: 'اكتب أي ملاحظات تسليم هنا...',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isSavingGeneral ? null : _saveGeneralInfo,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isSavingGeneral
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text(
                                        'حفظ البيانات العامة',
                                        style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 250.ms),

                      const SizedBox(height: 24),

                      // Items Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'أصناف الفاتورة',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.textDark,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _isLoadingItems || _isSavingItemReview ? null : _reviewAllItems,
                            icon: const Icon(Icons.done_all, color: AppColors.primary),
                            label: Text(
                              'مراجعة الكل',
                              style: GoogleFonts.cairo(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Items List Card
                      _isLoadingItems
                          ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                          : Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade100),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
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
                                            'الصنف',
                                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textLight),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            'الاتجاه/الموقع',
                                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textLight),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            'الكمية',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textLight),
                                          ),
                                        ),
                                        const SizedBox(width: 48), // Space for action button
                                      ],
                                    ),
                                  ),

                                  // Table Rows list
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _items.length,
                                    separatorBuilder: (context, index) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final item = _items[index];
                                      final String itemCode = item['itemCode'] ?? '';
                                      final String itemName = item['itemNameAr'] ?? 'صنف غير معروف';
                                      final String location = item['locationName'] ?? item['location'] ?? 'غير محدد';
                                      final double qty = (item['qty'] ?? 0.0).toDouble();
                                      final bool isReviewed = item['isDeliveryReviewed'] == 1;

                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        child: Row(
                                          children: [
                                            // Item info
                                            Expanded(
                                              flex: 3,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    itemName,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.cairo(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                      color: AppColors.textDark,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'كود: $itemCode',
                                                    style: GoogleFonts.cairo(
                                                      fontSize: 11,
                                                      color: AppColors.textLight,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Location
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                location,
                                                style: GoogleFonts.cairo(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade800,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            // Quantity
                                            Expanded(
                                              flex: 1,
                                              child: Text(
                                                qty.toStringAsFixed(qty % 1 == 0 ? 0 : 2),
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.cairo(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textDark,
                                                ),
                                              ),
                                            ),
                                            // Action Button (Checkmark toggle)
                                            SizedBox(
                                              width: 48,
                                              child: IconButton(
                                                onPressed: _isSavingItemReview ? null : () => _toggleItemReview(item),
                                                icon: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: isReviewed ? Colors.green.shade50 : Colors.grey.shade100,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: isReviewed ? Colors.green.shade300 : Colors.grey.shade300,
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    Icons.check,
                                                    size: 18,
                                                    color: isReviewed ? Colors.green.shade700 : Colors.grey.shade400,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
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
