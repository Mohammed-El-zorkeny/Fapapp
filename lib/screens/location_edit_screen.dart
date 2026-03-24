import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_button.dart';
import '../services/api_service.dart';

class LocationEditScreen extends StatefulWidget {
  const LocationEditScreen({super.key});

  @override
  State<LocationEditScreen> createState() => _LocationEditScreenState();
}

class _LocationEditScreenState extends State<LocationEditScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoadingItem = false;
  bool _isSavingLocation = false;
  bool _isScanning = false;
  Map<String, dynamic>? _itemDetails;
  String? _errorMessage;

  List<dynamic> _availableLocations = [];
  bool _isLoadingLocations = false;

  int? _selectedNewLocationId;
  String? _selectedNewLocationName;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocations() async {
    setState(() => _isLoadingLocations = true);
    final response = await _apiService.getLocations(subStoreId: 1);
    if (response['success']) {
      setState(() {
        _availableLocations = response['locations'] ?? [];
        _isLoadingLocations = false;
      });
    } else {
      setState(() {
        _isLoadingLocations = false;
      });
    }
  }

  Future<void> _fetchItemDetails(String code) async {
    if (code.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'الرجاء إدخال كود الصنف أو مسحه بالباركود',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isLoadingItem = true;
      _errorMessage = null;
      _itemDetails = null;
      _selectedNewLocationId = null;
      _selectedNewLocationName = null;
      _searchController.text = code;
    });

    final response = await _apiService.getInfoItem(code.trim());

    if (response['success']) {
      setState(() {
        _itemDetails = response['item'];
        _isLoadingItem = false;
      });
    } else {
      setState(() {
        _isLoadingItem = false;
        _errorMessage = response['message'] ?? 'حدث خطأ أثناء جلب تفاصيل الصنف';
      });
    }
  }

  Future<void> _saveNewLocation() async {
    if (_selectedNewLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'الرجاء اختيار الموقع الجديد أولاً',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSavingLocation = true);

    final response = await _apiService.updateLocations(
      _itemDetails!['itemCode'],
      _selectedNewLocationId!,
    );

    if (response['success']) {
      setState(() {
        _isSavingLocation = false;
        _itemDetails!['locationName'] =
            response['locationName'] ?? _selectedNewLocationName;
        _selectedNewLocationId = null;
        _selectedNewLocationName = null;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 80,
                ),
                const SizedBox(height: 16),
                Text(
                  'نجاح',
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  response['message'] ??
                      'تم تعديل اللوكيشن الخاص بالصنف بنجاح.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 16),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'حسناً',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      setState(() => _isSavingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message'] ?? 'حدث خطأ أثناء حفظ الموقع',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
      if (selectedValue != null) {
        setState(() {
          _selectedNewLocationId = selectedValue['id'];
          _selectedNewLocationName = selectedValue['nameAr'];
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'تعديل موقع صنف',
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
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Input & Scanner
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowLight,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'أدخل كود الصنف واستعرض...',
                          hintStyle: GoogleFonts.cairo(
                            color: AppColors.textLight,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.primary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onSubmitted: (val) => _fetchItemDetails(val),
                      ),
                    ),
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.grey.shade300,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.qr_code_scanner,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      onPressed: _openScanner,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              CustomButton(
                text: 'بحث',
                onPressed: () => _fetchItemDetails(_searchController.text),
                isLoading: _isLoadingItem,
              ),

              const SizedBox(height: 30),

              // Content Area
              Expanded(
                child: _isLoadingItem
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : _errorMessage != null
                    ? _buildErrorWidget()
                    : _itemDetails != null
                    ? _buildItemEditCard()
                    : _buildEmptyState(),
              ),
            ],
          ),
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
            Icons.edit_location_alt_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'قم بالبحث عن صنف لتعديل اللوكيشن الخاص به',
            style: GoogleFonts.cairo(fontSize: 16, color: AppColors.textLight),
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
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'حدث خطأ',
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildItemEditCard() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Item Info Minimal
            Text(
              _itemDetails!['nameAr'] ?? 'بدون اسم',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'كود: ${_itemDetails!['itemCode']}  |  ${_itemDetails!['groupName'] ?? ''}',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppColors.textLight,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Simple Arrow Flow from Old to New
            Row(
              children: [
                // Old Location
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade300, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'الموقع القديم',
                          style: GoogleFonts.cairo(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _itemDetails!['locationName'] ?? 'غير محدد',
                          style: GoogleFonts.cairo(
                            color: Colors.red.shade900,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                // Arrow pointing Left (RTL Flow) -> Old to New
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child:
                      Icon(
                            Icons
                                .keyboard_double_arrow_left_rounded, // Assuming RTL Old is right, New is left.
                            color: Colors.grey.shade400,
                            size: 40,
                          )
                          .animate(onPlay: (controller) => controller.repeat())
                          .moveX(
                            begin: 5,
                            end: -5,
                            duration: const Duration(seconds: 1),
                          ),
                ),

                // New Location
                Expanded(
                  child: GestureDetector(
                    onTap: _showLocationPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        border: Border.all(
                          color: Colors.green.shade500,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'الموقع الجديد',
                            style: GoogleFonts.cairo(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedNewLocationName ?? 'اختر موقع...',
                            style: GoogleFonts.cairo(
                              color: _selectedNewLocationName != null
                                  ? Colors.green.shade900
                                  : Colors.green.shade300,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // Save Button
            CustomButton(
              text: 'حفظ وتأكيد',
              onPressed: _isSavingLocation ? () {} : _saveNewLocation,
              isLoading: _isSavingLocation,
            ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: 0.1, end: 0),
    );
  }
}

class LocationPickerSheet extends StatefulWidget {
  final List<dynamic> locations;
  final bool isLoading;

  const LocationPickerSheet({
    Key? key,
    required this.locations,
    required this.isLoading,
  }) : super(key: key);

  @override
  _LocationPickerSheetState createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredLocations = [];

  @override
  void initState() {
    super.initState();
    _filteredLocations = widget.locations;
    _searchController.addListener(_filterLocations);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterLocations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLocations = widget.locations.where((loc) {
        final nameAr = loc['nameAr']?.toString().toLowerCase() ?? '';
        final nameEn = loc['nameEn']?.toString().toLowerCase() ?? '';
        return nameAr.contains(query) || nameEn.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'اختر الموقع الجديد',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ابحث عن موقع...',
                  hintStyle: GoogleFonts.cairo(color: Colors.grey),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.primary,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                style: GoogleFonts.cairo(fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: widget.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _filteredLocations.isEmpty
                  ? Center(
                      child: Text(
                        'لم يتم العثور على مواقع',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount: _filteredLocations.length,
                      separatorBuilder: (context, index) =>
                          Divider(color: Colors.grey.shade200, height: 1),
                      itemBuilder: (context, index) {
                        final loc = _filteredLocations[index];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.green,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            loc['nameAr'] ?? '',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 4,
                          ),
                          onTap: () {
                            Navigator.pop(context, loc);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
