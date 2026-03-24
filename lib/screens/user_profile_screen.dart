import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/app_colors.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String _nameArabic = '';
  String _phone = '';
  String _email = '';
  String _governorate = '';
  String _city = '';
  String _address = '';
  String _fullAddress = '';
  String _evaluation = '';
  num _balance = 0;
  String? _locationLink;
  String _customerCode = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final storage = StorageService();
    final userData = await storage.getUserData();
    
    if (!mounted) return;
    
    if (userData != null) {
      setState(() {
        _nameArabic = userData['nameArabic'] ?? userData['nameAr'] ?? '';
        _phone = userData['phoneNumber'] ?? userData['phone'] ?? '';
        _email = userData['email'] ?? '';
        _governorate = userData['governorate'] ?? '';
        _city = userData['district'] ?? '';
        _city = userData['district'] ?? '';
        _fullAddress = userData['fullAddress'] ?? '';
        _evaluation = userData['evaluation'] ?? '';
        _balance = userData['balance'] ?? 0;
        _locationLink = userData['locationLink'];
        _customerCode = userData['code']?.toString() ?? '';
        
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }



  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تسجيل الخروج', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من تسجيل الخروج؟', style: GoogleFonts.cairo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('تسجيل الخروج', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final storage = StorageService();
      await storage.clearAll();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              // Custom AppBar
              _buildAppBar(),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  child: Column(
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 24),
                      _buildContactSection(),
                      const SizedBox(height: 16),
                      _buildLocationSection(),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
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

  Widget _buildAppBar() {
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
            child: Text('الملف الشخصي', style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        const SizedBox(height: 16),
        // Avatar with gradient ring
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 38,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: const AssetImage('assets/images/avatar.jpg'),
            ),
          ),
        ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
        const SizedBox(height: 16),
        Text(
          _nameArabic,
          style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary.withOpacity(0.08), AppColors.primary.withOpacity(0.04)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.badge_outlined, color: AppColors.primary, size: 14),
              const SizedBox(width: 6),
              Text(
                'كود العميل: $_customerCode',
                style: GoogleFonts.cairo(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_outline, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text('معلومات الاتصال', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 18),
          _buildInfoRow(Icons.phone_iphone, 'رقم الهاتف', _phone, isCopyable: true),
          Divider(height: 28, color: Colors.grey.shade100),
          _buildInfoRow(Icons.email_outlined, 'البريد الإلكتروني', _email),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFE17055), Color(0xFFFAB1A0)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_on_outlined, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('معلومات الموقع', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
              ),
              TextButton.icon(
                onPressed: _showEditLocationModal,
                icon: const Icon(Icons.edit_location_alt_outlined, size: 18, color: AppColors.primary),
                label: Text('تعديل الموقع', style: GoogleFonts.cairo(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildInfoRow(Icons.location_city, 'المحافظة', _governorate.isNotEmpty ? _governorate : 'غير محدد'),
          Divider(height: 28, color: Colors.grey.shade100),
          _buildInfoRow(Icons.map_outlined, 'المنطقة', _city.isNotEmpty ? _city : 'غير محدد'),
          Divider(height: 28, color: Colors.grey.shade100),
          _buildInfoRow(Icons.home_outlined, 'العنوان بالكامل', _fullAddress.isNotEmpty ? _fullAddress : 'غير محدد'),
          Divider(height: 28, color: Colors.grey.shade100),
          _buildInfoRow(Icons.account_balance_wallet_outlined, 'الرصيد', _balance.toStringAsFixed(2)),
          Divider(height: 28, color: Colors.grey.shade100),
          _buildInfoRow(Icons.star_outline, 'التقييم', _evaluation.isNotEmpty ? _evaluation : 'غير محدد'),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isCopyable = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 11)),
              Text(value, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
            ],
          ),
        ),
        if (isCopyable)
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم النسخ: $value', style: GoogleFonts.cairo()),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.copy, color: Colors.grey.shade400, size: 16),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Logout Button
        Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 5))],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _logout,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('تسجيل الخروج', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }

  void _showEditLocationModal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditLocationScreen(
          initialGovernorate: _governorate,
          initialCity: _city,
          initialAddress: _fullAddress,
          initialLocationLink: _locationLink ?? '',
          onUpdate: (gov, city, addr, link) async {
            setState(() {
              _governorate = gov;
              _city = city;
              _fullAddress = addr;
              _locationLink = link;
            });
            final storage = StorageService();
            final userData = await storage.getUserData() ?? {};
            userData['governorate'] = gov;
            userData['district'] = city;
            userData['fullAddress'] = addr;
            userData['locationLink'] = link;
            await storage.saveUserData(userData);
          },
        ),
      ),
    );
  }
}

class EditLocationScreen extends StatefulWidget {
  final String initialGovernorate;
  final String initialCity;
  final String initialAddress;
  final String initialLocationLink;
  final Function(String, String, String, String) onUpdate;

  const EditLocationScreen({
    super.key,
    required this.initialGovernorate,
    required this.initialCity,
    required this.initialAddress,
    required this.initialLocationLink,
    required this.onUpdate,
  });

  @override
  State<EditLocationScreen> createState() => _EditLocationScreenState();
}

class _EditLocationScreenState extends State<EditLocationScreen> {
  late TextEditingController _govController;
  late TextEditingController _cityController;
  late TextEditingController _addrController;
  late TextEditingController _linkController;
  final TextEditingController _searchController = TextEditingController();
  final String _googleMapsApiKey = 'AIzaSyA8NdDD7cUCWx_OIvDi0A8EApwA2Bll_sg';
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(30.0444, 31.2357);

  @override
  void initState() {
    super.initState();
    _govController = TextEditingController(text: widget.initialGovernorate);
    _cityController = TextEditingController(text: widget.initialCity);
    _addrController = TextEditingController(text: widget.initialAddress);
    _linkController = TextEditingController(text: widget.initialLocationLink);
    
    // Parse initial lat/lng from link if possible
    if (_linkController.text.isNotEmpty && _linkController.text.contains('?q=')) {
      try {
        final coordsStr = _linkController.text.split('?q=')[1].split(',');
        if (coordsStr.length >= 2) {
          final lat = double.tryParse(coordsStr[0]);
          final lng = double.tryParse(coordsStr[1]);
          if (lat != null && lng != null) {
            _selectedLocation = LatLng(lat, lng);
          }
        }
      } catch (e) {
        debugPrint('Parse initial link error: $e');
      }
    }
    _requestPermission();
  }
  
  Future<void> _requestPermission() async {
    await Permission.locationWhenInUse.request();
  }

  @override
  void dispose() {
    _govController.dispose();
    _cityController.dispose();
    _addrController.dispose();
    _linkController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onCameraIdle() {
    _getAddressFromLatLng(_selectedLocation.latitude, _selectedLocation.longitude);
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$_googleMapsApiKey&language=ar');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          final result = data['results'][0];
          final addressComponents = result['address_components'] as List;

          String gov = '';
          String dist = '';
          String fullAddr = result['formatted_address'] ?? '';

          for (var comp in addressComponents) {
            final types = comp['types'] as List;
            if (types.contains('administrative_area_level_1')) {
              gov = comp['long_name'];
            }
            if (types.contains('locality') ||
                types.contains('sublocality') ||
                types.contains('administrative_area_level_2')) {
              if (dist.isEmpty) dist = comp['long_name'];
            }
          }

          if (mounted) {
            setState(() {
              _govController.text = gov.isNotEmpty ? gov : _govController.text;
              _cityController.text = dist;
              _addrController.text = fullAddr;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(query)}&key=$_googleMapsApiKey&language=ar');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          final loc = data['results'][0]['geometry']['location'];
          final lat = loc['lat'];
          final lng = loc['lng'];
          
          if (_mapController != null) {
             _mapController!.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16));
             FocusScope.of(context).unfocus();
          }
        }
      }
    } catch (e) {
      debugPrint('Search Geocoding error: $e');
    }
  }

  Future<void> _updateLocation() async {
    setState(() => _isLoading = true);
    
    final result = await _apiService.editLocation(
      locationLink: _linkController.text,
      governorate: _govController.text,
      district: _cityController.text,
      fullAddress: _addrController.text,
    );
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      widget.onUpdate(
        _govController.text,
        _cityController.text,
        _addrController.text,
        _linkController.text,
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'تم التحديث بنجاح', style: GoogleFonts.cairo()),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'فشل التحديث', style: GoogleFonts.cairo()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تعديل الموقع', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: AppColors.background,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // Map Section
            Expanded(
              flex: 5,
              child: Stack(
                alignment: Alignment.center,
                children: [
                   GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(target: _selectedLocation, zoom: 12),
                      onCameraMove: (position) {
                        _selectedLocation = position.target;
                        final link = 'https://maps.google.com/?q=${_selectedLocation.latitude},${_selectedLocation.longitude}';
                        if (_linkController.text != link) {
                          _linkController.text = link;
                        }
                      },
                      onCameraIdle: _onCameraIdle,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      compassEnabled: false,
                      zoomControlsEnabled: false,
                   ),
                   // Fixed marker in center
                   const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on, size: 45, color: AppColors.primary),
                        SizedBox(height: 25), // Adjust to center pinpoint correctly
                      ],
                   ),
                   // Search Bar Overlay
                   Positioned(
                      top: 15,
                      left: 15,
                      right: 15,
                      child: Container(
                         decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                         ),
                         child: TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            onSubmitted: _searchLocation,
                            decoration: InputDecoration(
                               hintText: 'ابحث عن مكان...',
                               hintStyle: GoogleFonts.cairo(color: Colors.grey),
                               border: InputBorder.none,
                               prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                               suffixIcon: IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () {
                                     _searchController.clear();
                                  },
                               ),
                            ),
                         ),
                      ),
                   ),
                ],
              ),
            ),
            
            // Form Section
            Expanded(
              flex: 4,
              child: Container(
                 width: double.infinity,
                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                 decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
                 ),
                 child: SingleChildScrollView(
                    child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          Row(
                            children: [
                              const Icon(Icons.my_location, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(child: Text('اسحب الخريطة أو اضغط على زر نقطة الموقع لتحديد موقعك الحالي، أو استخدم البحث.', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade600, height: 1.3))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildTextField('المحافظة', _govController)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildTextField('المنطقة', _cityController)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField('العنوان بالكامل', _addrController, maxLines: 2),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: _isLoading ? null : _updateLocation,
                              child: _isLoading 
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text('تحديث الموقع', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                          const SizedBox(height: 10),
                       ],
                    ),
                 ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.cairo(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
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
    );
  }
}

