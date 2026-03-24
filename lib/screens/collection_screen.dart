import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_button.dart';
import '../services/api_service.dart';
import 'dart:convert';
import 'package:path/path.dart' as p;

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Form fields
  Map<String, dynamic>? _selectedCustomer;
  final TextEditingController _amountController = TextEditingController();
  List<Map<String, dynamic>> _multiplePayments = [];
  File? _proofImage;
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  // Search state
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final ApiService _apiService = ApiService();
  final List<Map<String, dynamic>> _customers = [];
  bool _isFetchingCustomers = false;
  int _currentPage = 0;
  static const int _pageSize = 10;

  final List<Map<String, dynamic>> _banks = [];
  bool _isFetchingBanks = false;
  Map<String, dynamic>? _selectedBank;

  List<Map<String, dynamic>> get _filteredCustomers {
    List<Map<String, dynamic>> filtered = _customers;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = _customers.where((customer) {
        final nameAr = (customer['nameAr'] ?? '').toString().toLowerCase();
        final code = (customer['customerCode'] ?? '').toString().toLowerCase();
        return nameAr.contains(query) || code.contains(query);
      }).toList();
    }
    return filtered;
  }

  List<Map<String, dynamic>> get _paginatedCustomers {
    final filtered = _filteredCustomers;
    final start = _currentPage * _pageSize;
    if (start >= filtered.length) return [];
    final end = (start + _pageSize) > filtered.length
        ? filtered.length
        : (start + _pageSize);
    return filtered.sublist(start, end);
  }

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
    _fetchBanks();
  }

  Future<void> _fetchCustomers() async {
    setState(() => _isFetchingCustomers = true);
    final result = await _apiService.getCustomers();
    if (mounted) {
      setState(() {
        _isFetchingCustomers = false;
        if (result['success']) {
          _customers.clear();
          final List<dynamic> data = result['data'] ?? [];
          _customers.addAll(
            data.map((e) => Map<String, dynamic>.from(e)).toList(),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في تحميل العملاء: ${result['message']}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      });
    }
  }

  Future<void> _fetchBanks() async {
    setState(() => _isFetchingBanks = true);
    final result = await _apiService.getBanks();
    if (mounted) {
      setState(() {
        _isFetchingBanks = false;
        if (result['success']) {
          _banks.clear();
          final List<dynamic> data = result['data'] ?? [];
          _banks.addAll(data.map((e) => Map<String, dynamic>.from(e)).toList());
        }
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showCustomerSearch() {
    _searchQuery = '';
    _searchController.clear();
    _currentPage = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'اختر العميل',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setModalState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'ابحث عن اسم أو كود العميل...',
                        hintStyle: GoogleFonts.cairo(fontSize: 14),
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
                      ),
                    ),
                  ),
                  Expanded(
                    child: _isFetchingCustomers
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredCustomers.isEmpty
                        ? Center(
                            child: Text(
                              'لا يوجد عملاء مطابقتين للبحث',
                              style: GoogleFonts.cairo(
                                color: AppColors.textLight,
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  itemCount: _paginatedCustomers.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(),
                                  itemBuilder: (context, index) {
                                    final customer = _paginatedCustomers[index];
                                    final isSelected =
                                        _selectedCustomer?['id'] ==
                                        customer['id'];
                                    return ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                      leading: CircleAvatar(
                                        backgroundColor: AppColors.primary
                                            .withOpacity(0.1),
                                        child: const Icon(
                                          Icons.person,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          _selectedCustomer = customer;
                                        });
                                        Navigator.pop(context);
                                      },
                                      title: Text(
                                        customer['nameAr'] ?? 'بدون اسم',
                                        style: GoogleFonts.cairo(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.textDark,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'كود: ${customer['customerCode'] ?? '---'}',
                                        style: GoogleFonts.cairo(fontSize: 12),
                                      ),
                                      trailing: isSelected
                                          ? const Icon(
                                              Icons.check_circle,
                                              color: AppColors.primary,
                                            )
                                          : null,
                                    );
                                  },
                                ),
                              ),
                              if (_filteredCustomers.length > _pageSize)
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton.icon(
                                        onPressed: _currentPage > 0
                                            ? () => setModalState(
                                                () => _currentPage--,
                                              )
                                            : null,
                                        icon: const Icon(
                                          Icons.arrow_back_ios,
                                          size: 16,
                                        ),
                                        label: Text(
                                          'السابق',
                                          style: GoogleFonts.cairo(),
                                        ),
                                      ),
                                      Text(
                                        'صفحة ${_currentPage + 1} من ${(_filteredCustomers.length / _pageSize).ceil()}',
                                        style: GoogleFonts.cairo(fontSize: 12),
                                      ),
                                      TextButton.icon(
                                        onPressed:
                                            (_currentPage + 1) * _pageSize <
                                                _filteredCustomers.length
                                            ? () => setModalState(
                                                () => _currentPage++,
                                              )
                                            : null,
                                        label: Text(
                                          'التالي',
                                          style: GoogleFonts.cairo(),
                                        ),
                                        icon: const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _proofImage = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل اختيار الصورة: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'اختر مصدر الصورة',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: Text('الكاميرا', style: GoogleFonts.cairo()),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.primary,
                ),
                title: Text('المعرض', style: GoogleFonts.cairo()),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addPaymentEntry() {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال المبلغ'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار البنك/طريقة التحويل'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _multiplePayments.add({
        'amount': double.parse(_amountController.text),
        'bank': _selectedBank,
      });
      _amountController.clear();
      _selectedBank = null;
    });
  }

  void _removePaymentEntry(int index) {
    setState(() {
      _multiplePayments.removeAt(index);
    });
  }

  double _getTotalAmount() {
    return _multiplePayments.fold(
      0,
      (sum, payment) => sum + (payment['amount'] as double),
    );
  }

  Future<void> _submitCollection() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار العميل'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_multiplePayments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إضافة طرق الدفع (على الأقل واحدة)'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إضافة صورة الإثبات'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageBase64;
      String? imageName;
      if (_proofImage != null) {
        final bytes = await _proofImage!.readAsBytes();
        imageBase64 = base64Encode(bytes);
        imageName = p.basename(_proofImage!.path);
      }

      List<String> autoNumbers = [];
      bool allSuccess = true;
      String errorMessage = '';

      for (var payment in _multiplePayments) {
        final result = await _apiService.createPayment(
          bankId: payment['bank']?['id'] ?? 0,
          customerId: _selectedCustomer!['id'] ?? 0,
          value: payment['amount'],
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          imageBase64: imageBase64,
          imageName: imageName,
        );

        if (result['success']) {
          final paymentData = result['payment'];
          if (paymentData != null && paymentData['autoNumber'] != null) {
            autoNumbers.add(paymentData['autoNumber']);
          }
        } else {
          allSuccess = false;
          errorMessage = result['message'];
          break;
        }
      }

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (allSuccess) {
        _showSuccessDialog(autoNumbers);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(List<String> autoNumbers) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success),
              const SizedBox(width: 8),
              Text(
                'تم الحفظ بنجاح',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تم إنشاء سندات القبض التالية:',
                style: GoogleFonts.cairo(),
              ),
              const SizedBox(height: 12),
              ...autoNumbers.map((no) => Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'رقم السند:',
                          style: GoogleFonts.cairo(fontSize: 12),
                        ),
                        Text(
                          no,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Back to previous screen
              },
              child: Text(
                'حسناً',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'التحصيل الالكتروني',
          style: GoogleFonts.cairo(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Selection
                _buildSectionTitle('العميل المستفيد'),
                _buildCustomerSelector(),

                const SizedBox(height: 24),

                // Payment Details
                _buildSectionTitle('إضافة مبالغ للتحصيل (متعدد)'),
                _buildMultiplePaymentForm(),

                const SizedBox(height: 24),

                // Proof Image
                _buildSectionTitle('صورة إيصال التحصيل'),
                _buildImagePicker(),

                const SizedBox(height: 24),

                // Notes
                _buildSectionTitle('ملاحظات المندوب'),
                _buildNotesField(),

                const SizedBox(height: 32),

                // Submit Button
                CustomButton(
                  text: 'تأكيد وحفظ التحصيل',
                  onPressed: _submitCollection,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildCustomerSelector() {
    return InkWell(
      onTap: _showCustomerSearch,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_search_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedCustomer == null
                    ? 'اضغط للبحث عن عميل...'
                    : '${_selectedCustomer!['customerCode'] ?? '---'} - ${_selectedCustomer!['nameAr'] ?? '---'}',
                style: GoogleFonts.cairo(
                  color: _selectedCustomer == null
                      ? AppColors.textLight
                      : AppColors.textDark,
                  fontWeight: _selectedCustomer == null
                      ? FontWeight.normal
                      : FontWeight.bold,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiplePaymentForm() {
    return Column(
      children: [
        // Amount and Add Button Row
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.cairo(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'المبلغ المحصل',
                  labelStyle: GoogleFonts.cairo(fontSize: 12),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addPaymentEntry,
              icon: const Icon(Icons.add_circle, color: AppColors.primary),
              iconSize: 40,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Bank Selection Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Map<String, dynamic>>(
              isExpanded: true,
              hint: Text(
                'اختر البنك / طريقة التحويل...',
                style: GoogleFonts.cairo(fontSize: 12),
              ),
              value: _selectedBank,
              style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textDark),
              items: _banks.map((bank) {
                return DropdownMenuItem(
                  value: bank,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(bank['nameAr'] ?? ''),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBank = value;
                });
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Payment List
        if (_multiplePayments.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                ..._multiplePayments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final payment = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.payments_outlined,
                              color: AppColors.primary,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${payment['amount'].toStringAsFixed(2)} جنيه',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  payment['bank']?['nameAr'] ?? 'غير معروف',
                                  style: GoogleFonts.cairo(
                                    color: AppColors.textLight,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _removePaymentEntry(index),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: AppColors.error,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'إجمالي المبلغ:',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_getTotalAmount().toStringAsFixed(2)} جنيه',
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        if (_proofImage != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _proofImage!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),
        ],
        InkWell(
          onTap: _showImageSourceDialog,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _proofImage == null ? Icons.add_a_photo : Icons.edit,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  _proofImage == null ? 'إضافة صورة' : 'تغيير الصورة',
                  style: GoogleFonts.cairo(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 4,
      style: GoogleFonts.cairo(),
      decoration: InputDecoration(
        hintText: 'أضف ملاحظات...',
        hintStyle: GoogleFonts.cairo(color: AppColors.textLight),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
