import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/price_list_model.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import 'report_details_screen.dart';
import 'secure_pdf_viewer.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ApiService _apiService = ApiService();
  List<PriceListModel> _priceLists = [];
  List<PriceListModel> _filteredPriceLists = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPriceLists();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPriceLists = _priceLists.where((list) {
        return list.nameAr.toLowerCase().contains(query) ||
            list.autoNumber.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _fetchPriceLists() async {
    setState(() => _isLoading = true);
    final result = await _apiService.getPriceLists();

    if (!mounted) return;

    if (result['success']) {
      final List data = result['data'];
      final lists = data.map((json) => PriceListModel.fromJson(json)).toList();
      setState(() {
        _priceLists = lists;
        _filteredPriceLists = lists;
        _isLoading = false;
      });
    } else {
      if (result['authError'] == true) {
        // Handle Logout if needed, for now just show error
        setState(() {
          _errorMessage = 'جلسة غير صالحة، يرجى تسجيل الدخول مرة أخرى';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showActionDialog(
    BuildContext context,
    PriceListModel list,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'اختر إجراء',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionBtn(
              context,
              'عرض الكشف',
              Icons.picture_as_pdf,
              () => _openSecurePdf(context, list),
            ),
            const SizedBox(height: 10),
            _buildActionBtn(
              context,
              'إنشاء طلب جديد',
              Icons.add_shopping_cart,
              () => _navigateToDetails(context, list),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  void _openSecurePdf(BuildContext context, PriceListModel list) {
    Navigator.pop(context); // Close Action Dialog

    if (list.priceListUrlPdf.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد ملف PDF متاح لهذا الكشف')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SecurePdfViewer(title: list.nameAr, filePath: list.priceListUrlPdf),
      ),
    );
  }

  void _navigateToDetails(BuildContext context, PriceListModel list) {
    Navigator.pop(context); // Close Dialog
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => ReportDetailsScreen(priceListId: list.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const SizedBox.shrink(),
        title: const Text(
          'الكشوفات',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _buildHeaderIcon(
              Icons.arrow_forward_ios,
              onTap: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'ابحث عن كشف...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),

            // Section Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'الكشوفات المتاحة',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Results
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : _filteredPriceLists.isEmpty
                  ? const Center(child: Text('لا توجد بيانات'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _filteredPriceLists.length,
                      itemBuilder: (context, index) {
                        return _buildReportCard(
                          context,
                          _filteredPriceLists[index],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, {Color? color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color?.withOpacity(0.05) ?? Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Icon(icon, color: color ?? AppColors.textDark, size: 20),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, PriceListModel list) {
    return GestureDetector(
      onTap: () => _showActionDialog(context, list),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.grey.shade50),
        ),
        child: Row(
          children: [
            // Logo Icon (New)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.description,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(width: 15),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    list.nameAr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    list.messageAr,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            // Leading
            Icon(
              Icons.arrow_back_ios_new,
              color: Colors.grey.shade300,
              size: 16,
            ),
          ],
        ),
      ),
    ).animate().fadeIn().moveX();
  }
}
