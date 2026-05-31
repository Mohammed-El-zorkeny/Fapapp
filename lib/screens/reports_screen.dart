import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/price_list_model.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/cart_provider.dart';
import '../utils/screenshot_protection_mixin.dart';
import 'cart_screen.dart';
import 'report_details_screen.dart';
import 'secure_pdf_viewer.dart';

class ReportsScreen extends StatefulWidget {
  final int? preselectedGroupId;
  final String? preselectedGroupName;

  const ReportsScreen({super.key, this.preselectedGroupId, this.preselectedGroupName});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with ScreenshotProtectionMixin {
  final ApiService _apiService = ApiService();
  List<PriceListModel> _priceLists = [];
  List<PriceListModel> _filteredPriceLists = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    initScreenshotProtection();
    _fetchPriceLists();
    _searchController.addListener(_onSearchChanged);
    // Auto-open first price list if brand was pre-selected
    if (widget.preselectedGroupId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryAutoOpenFirstList());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    disposeScreenshotProtection();
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

  void _tryAutoOpenFirstList() async {
    // Wait until lists are loaded, then open first list with group filter
    int attempts = 0;
    while (_isLoading && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 300));
      attempts++;
    }
    if (!mounted) return;
    if (_filteredPriceLists.isNotEmpty) {
      final first = _filteredPriceLists.first;
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportDetailsScreen(
              priceListId: first.id,
              priceListName: first.nameAr,
              preselectedGroupId: widget.preselectedGroupId,
            ),
          ),
        );
      }
    }
  }

  void _showActionSheet(BuildContext context, PriceListModel list) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 20),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.description_outlined, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(list.nameAr, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                            if (list.messageAr.isNotEmpty)
                              Text(list.messageAr, style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textLight), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // View PDF
                      _buildSheetAction(
                        icon: Icons.picture_as_pdf_outlined,
                        label: 'عرض الكشف',
                        subtitle: 'عرض ملف PDF للكشف',
                        color: AppColors.primary,
                        gradientColors: [AppColors.primary, const Color(0xFFFF6B6B)],
                        onTap: () {
                          Navigator.pop(context);
                          _openSecurePdf(context, list);
                        },
                      ),
                      const SizedBox(height: 12),
                      // Create Order
                      _buildSheetAction(
                        icon: Icons.add_shopping_cart_outlined,
                        label: 'إنشاء طلب جديد',
                        subtitle: 'إنشاء طلب من هذا الكشف',
                        color: const Color(0xFF00B894),
                        gradientColors: [const Color(0xFF00B894), const Color(0xFF55EFC4)],
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToDetails(context, list);
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetAction({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    Text(subtitle, style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textLight)),
                  ],
                ),
              ),
              Icon(Icons.arrow_back_ios_new, size: 14, color: color.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }

  void _openSecurePdf(BuildContext context, PriceListModel list) {
    if (list.priceListUrlPdf.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لا يوجد ملف PDF متاح لهذا الكشف', style: GoogleFonts.cairo())),
      );
      return;
    }

    Navigator.push(context, MaterialPageRoute(
      builder: (context) => SecurePdfViewer(title: list.nameAr, filePath: list.priceListUrlPdf),
    ));
  }

  void _navigateToDetails(BuildContext context, PriceListModel list) {
    Navigator.push(context, MaterialPageRoute(
      builder: (c) => ReportDetailsScreen(priceListId: list.id, priceListName: list.nameAr),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              // Custom AppBar
              _buildAppBar(),
              // Search
              if (_isSearchVisible) _buildSearchBar(),
              // Stats
              _buildStatsBar(),
              // List
              Expanded(child: _buildReportsList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return AnimatedBuilder(
      animation: CartProvider.instance,
      builder: (context, _) {
        final cartCount = CartProvider.instance.totalItemCount;
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: const Icon(Icons.arrow_forward_ios, color: AppColors.textDark, size: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text('الكشوفات', style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ),
              // Cart icon with badge
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
                child: Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cartCount > 0 ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(Icons.shopping_cart_rounded, color: cartCount > 0 ? Colors.white : AppColors.textDark, size: 22),
                      if (cartCount > 0)
                        Positioned(
                          top: -6,
                          left: -6,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary, width: 1.5),
                            ),
                            child: Text(
                              '$cartCount',
                              style: GoogleFonts.cairo(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Search
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isSearchVisible = !_isSearchVisible;
                    if (!_isSearchVisible) _searchController.clear();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isSearchVisible ? AppColors.primary.withOpacity(0.1) : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: _isSearchVisible ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Icon(
                    _isSearchVisible ? Icons.close : Icons.search,
                    color: _isSearchVisible ? AppColors.primary : AppColors.textDark,
                    size: 20,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.cairo(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'ابحث عن كشف بالاسم أو الرقم...',
                  hintStyle: GoogleFonts.cairo(fontSize: 13, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 14, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildStatsBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          Text(
            'الكشوفات المتاحة',
            style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textLight),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_filteredPriceLists.length} كشف',
              style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
        ],
      ).animate().fadeIn(delay: 150.ms),
    );
  }

  Widget _buildReportsList() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 4,
        itemBuilder: (c, i) => _buildShimmerCard(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: GoogleFonts.cairo(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _fetchPriceLists,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
                child: Text('إعادة المحاولة', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredPriceLists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('لا توجد كشوفات', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMedium)),
            const SizedBox(height: 6),
            Text('لا توجد بيانات متاحة حالياً', style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textLight)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchPriceLists,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filteredPriceLists.length,
        itemBuilder: (context, index) {
          return _buildReportCard(context, _filteredPriceLists[index], index);
        },
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: 140, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 8),
                Container(height: 10, width: 200, decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: Colors.grey.shade200);
  }

  Widget _buildReportCard(BuildContext context, PriceListModel list, int index) {
    // Alternate gradient colors for visual variety
    final List<List<Color>> cardGradients = [
      [const Color(0xFF6C5CE7), const Color(0xFFA29BFE)],
      [const Color(0xFF0984E3), const Color(0xFF74B9FF)],
      [const Color(0xFFE17055), const Color(0xFFFAB1A0)],
      [const Color(0xFF00B894), const Color(0xFF55EFC4)],
    ];
    final gradient = cardGradients[index % cardGradients.length];

    return GestureDetector(
      onTap: () => _showActionSheet(context, list),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
          ],
          border: Border.all(color: Colors.grey.shade50),
        ),
        child: Row(
          children: [
            // Gradient icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: gradient[0].withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: const Center(
                child: Icon(Icons.description_outlined, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    list.nameAr,
                    style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    list.messageAr.isNotEmpty ? list.messageAr : list.autoNumber,
                    style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Action arrow
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_back_ios_new, color: Colors.grey.shade400, size: 14),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms, duration: 300.ms).slideX(begin: 0.05, end: 0);
  }
}
