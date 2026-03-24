import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../utils/app_colors.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'secure_pdf_viewer.dart';
import 'order_tracking_screen.dart';

class InvoiceDetailsScreen extends StatefulWidget {
  final int invoiceId;
  final int? orderId;

  const InvoiceDetailsScreen({super.key, required this.invoiceId, this.orderId});

  @override
  State<InvoiceDetailsScreen> createState() => _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _invoiceDetails;
  bool _isLoading = true;
  String? _errorMessage;

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _loadInvoiceDetails();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoiceDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiService.getViewInvoiceDetails(widget.invoiceId);
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result['success']) {
            if (result['data'] != null &&
                result['data']['invoices'] != null &&
                (result['data']['invoices'] as List).isNotEmpty) {
              _invoiceDetails = result['data']['invoices'][0];
            } else {
              _errorMessage = 'لم يتم العثور على التفاصيل';
            }
          } else {
            _errorMessage = result['message'];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'حدث خطأ: $e';
        });
      }
    }
  }

  List<dynamic> get _filteredItems {
    final items = _invoiceDetails?['items'] as List<dynamic>? ?? [];
    if (_searchQuery.isEmpty) return items;
    return items.where((item) {
      final name = (item['itemName'] ?? '').toString().toLowerCase();
      final code = (item['itemCode'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || code.contains(query);
    }).toList();
  }

  Future<void> _openPdf() async {
    if (_invoiceDetails == null || _invoiceDetails!['urlPdf'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('رابط الملف غير متوفر', style: GoogleFonts.cairo())),
      );
      return;
    }
    
    final String url = _invoiceDetails!['urlPdf'];
    final String invoiceNumber = _invoiceDetails!['invoiceNumber']?.toString() ?? 'فاتورة';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SecurePdfViewer(
          title: 'فاتورة رقم $invoiceNumber',
          filePath: url,
        ),
      ),
    );
  }

  Future<void> _downloadPdf() async {
    if (_invoiceDetails == null || _invoiceDetails!['urlPdf'] == null) return;
    final String url = _invoiceDetails!['urlPdf'];
    final String invoiceNumber = _invoiceDetails!['invoiceNumber']?.toString() ?? 'invoice';

    setState(() => _isLoading = true);
    
    try {
      final dio = Dio();
      final token = await StorageService().getToken();
      
      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) dir = await getExternalStorageDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
      
      final String savePath = '${dir?.path}/Fap_Invoice_$invoiceNumber.pdf';
      
      await dio.download(
        url,
        savePath,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        onReceiveProgress: (received, total) {},
      );

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('تم تحميل الفاتورة بنجاح في: $savePath', style: GoogleFonts.cairo()),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء التحميل: $e', style: GoogleFonts.cairo())),
        );
      }
    }
  }

  Future<void> _callPhone() async {
    final String phoneNumber = '01002841600';
    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('لا يمكن فتح تطبيق الاتصال', style: GoogleFonts.cairo())),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء محاولة الاتصال', style: GoogleFonts.cairo())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'تفاصيل الفاتورة',
          style: GoogleFonts.cairo(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          if (_invoiceDetails != null && (_invoiceDetails!['items'] as List<dynamic>? ?? []).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isSearchVisible = !_isSearchVisible;
                    if (!_isSearchVisible) {
                      _searchController.clear();
                      _searchQuery = '';
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isSearchVisible ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isSearchVisible ? Icons.close : Icons.search,
                    color: _isSearchVisible ? AppColors.primary : AppColors.textDark,
                    size: 22,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _invoiceDetails != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: GoogleFonts.cairo(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInvoiceDetails,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text('إعادة المحاولة', style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_invoiceDetails == null) {
      return const SizedBox.shrink();
    }

    final invoiceNumber = _invoiceDetails!['invoiceNumber'] ?? '---';
    final invoiceDate = _invoiceDetails!['invoiceDate'] ?? '---';
    final deliveryDate = _invoiceDetails!['deliveryDate'];
    final total = _invoiceDetails!['invoiceTotal']?.toString() ?? '0';
    final allItems = _invoiceDetails!['items'] as List<dynamic>? ?? [];
    final items = _filteredItems;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          // Search bar
          if (_isSearchVisible)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              color: Colors.white,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: GoogleFonts.cairo(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'ابحث عن صنف بالاسم أو الكود...',
                          hintStyle: GoogleFonts.cairo(fontSize: 13, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 14, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.3, end: 0),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Details Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('رقم الفاتورة', style: GoogleFonts.cairo(color: Colors.grey, fontSize: 13)),
                            Text(invoiceNumber, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('تاريخ الفاتورة', style: GoogleFonts.cairo(color: Colors.grey, fontSize: 13)),
                            Text(invoiceDate, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('تاريخ التسليم', style: GoogleFonts.cairo(color: Colors.grey, fontSize: 13)),
                            Text(
                              deliveryDate == null || deliveryDate.toString().isEmpty ? 'لم يتم تاكيد تاريخ التسليم' : deliveryDate.toString(),
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: deliveryDate == null || deliveryDate.toString().isEmpty ? Colors.red : AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('الإجمالي', style: GoogleFonts.cairo(color: Colors.grey, fontSize: 14)),
                            Text('$total جنيه', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Items header with count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الأصناف (${allItems.length})',
                        style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (_searchQuery.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'نتائج: ${items.length}',
                            style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (items.isEmpty && _searchQuery.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('لا توجد نتائج لـ "$_searchQuery"', style: GoogleFonts.cairo(color: Colors.grey, fontSize: 14)),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _buildItemCard(item, index);
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, int index) {
    final itemName = item['itemName'] ?? '---';
    final qty = item['qty']?.toString() ?? '0';
    final finalValue = item['finalValue']?.toString() ?? '0';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('الكمية: $qty', style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12)),
                    Text('$finalValue جنيه', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 30).ms, duration: 200.ms);
  }

  Widget _buildBottomBar() {
    // Get orderId from either widget param or invoice data
    final int? orderId = widget.orderId ?? _invoiceDetails?['orderId'];
    final String invoiceNum = _invoiceDetails?['invoiceNumber']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tracking button
              if (orderId != null)
                Container(
                  width: double.infinity,
                  height: 46,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0984E3), Color(0xFF6C5CE7)],
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: const Color(0xFF0984E3).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (c) => OrderTrackingScreen(orderId: orderId, invoiceNumber: invoiceNum),
                        ));
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text('تتبع الطلب', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ),
              // Action buttons row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openPdf,
                      icon: const Icon(Icons.visibility, color: Colors.white, size: 18),
                      label: Text('عرض', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('تأكيد التحميل', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                              content: Text('هل تريد تحميل الفاتورة؟', style: GoogleFonts.cairo()),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _downloadPdf();
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                  child: Text('تحميل', style: GoogleFonts.cairo(color: Colors.white)),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.download, color: AppColors.primary, size: 18),
                      label: Text('تحميل', style: GoogleFonts.cairo(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      onPressed: _callPhone,
                      icon: const Icon(Icons.call, color: Colors.green),
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
}
