import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  // User Data
  String _nameArabic = 'أحمد محمد علي';
  String _phone = '01002841600';
  String _email = 'ahmed@example.com';
  String _governorate = 'القاهرة';
  String _city = 'مدينة نصر';
  String _address = 'شارع الجمهورية، متفرع من شارع الطيران، القاهرة';
  double _balance = 45250;
  int _ordersCount = 42;
  int _activeDays = 3;
  int _userId = 5001;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Mock data based on image, but keeping logic to load if available
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // If prefs have data, use it, otherwise keep default mock for pixel perfect demo
      if (prefs.containsKey('nameArabic'))
        _nameArabic = prefs.getString('nameArabic')!;
      if (prefs.containsKey('phone')) _phone = prefs.getString('phone')!;
      if (prefs.containsKey('email')) _email = prefs.getString('email')!;
      // ... other fields
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'تسجيل الخروج',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من تسجيل الخروج؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('تسجيل الخروج', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
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
      backgroundColor:
          Colors.grey[50], // Light grey background like image bottom
      appBar: AppBar(
        title: Text(
          'الملف الشخصي',
          style: GoogleFonts.cairo(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.grey),
          onPressed: () {}, // Settings action
        ),
        actions: [
          // Leading in RTL is Right side? No. Leading is Left. Actions is Right.
          // Image has "Settings" icon on... Left?
          // No, normally Back is Right in RTL.
          // Let's follow standard AppBar.
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildContactInfo(),
              const SizedBox(height: 16),
              _buildLocationInfo(),
              const SizedBox(height: 20),
              _buildActions(),
              const SizedBox(height: 30),
              _buildStatsRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFFD32F2F), // Red
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'أم',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _nameArabic,
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'كود العميل: $_userId#',
            style: GoogleFonts.cairo(
              color: const Color(0xFFD32F2F),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, color: Color(0xFFD32F2F)),
              const SizedBox(width: 8),
              Text(
                'معلومات الاتصال',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.phone_iphone,
            'رقم الهاتف',
            _phone,
            isCopyable: true,
          ),
          const Divider(height: 24),
          _buildInfoRow(Icons.email_outlined, 'البريد الإلكتروني', _email),
        ],
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Color(0xFFD32F2F)),
              const SizedBox(width: 8),
              Text(
                'معلومات الموقع',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.location_city,
                  'المحافظة',
                  _governorate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(Icons.apartment, 'المنطقة', _city),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.home_outlined,
                  'العنوان بالكامل',
                  _address,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isCopyable = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFD32F2F), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.cairo(color: Colors.grey, fontSize: 11),
              ),
              Text(
                value,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        if (isCopyable)
          Icon(Icons.copy, color: Colors.grey.withOpacity(0.5), size: 18),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFD32F2F), size: 20),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.cairo(color: Colors.grey, fontSize: 11),
              ),
              Text(
                value,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFD32F2F)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            minimumSize: const Size(double.infinity, 48),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.edit, color: Color(0xFFD32F2F), size: 18),
              const SizedBox(width: 8),
              Text(
                'تعديل البيانات',
                style: GoogleFonts.cairo(
                  color: const Color(0xFFD32F2F),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _logout,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD32F2F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            minimumSize: const Size(double.infinity, 48),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'تسجيل الخروج',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            '$_ordersCount طلب',
            'إجمالي الطلبات',
            Icons.inventory_2_outlined,
            const Color(0xFFD32F2F),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            '$_activeDays أيام',
            'آخر نشاط',
            Icons.access_time,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            '${_balance.toStringAsFixed(0)}',
            'إجمالي الشراء',
            Icons.credit_card,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(
            label,
            style: GoogleFonts.cairo(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
