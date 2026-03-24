import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utils/app_colors.dart';
import '../services/api_service.dart';
import '../widgets/custom_button.dart';

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key});

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final TextEditingController _invoiceController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _invoiceSearchController =
      TextEditingController();
  final TextEditingController _itemSearchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  Map<String, dynamic>? _selectedCustomer;
  Map<String, dynamic>? _selectedInvoice;
  List<Map<String, dynamic>> _invoiceItems = [];
  List<Map<String, dynamic>> _filteredInvoiceItems = [];
  bool _isLoading = false;
  bool _isFetchingCustomers = false;
  bool _isFetchingInvoices = false;
  bool _isFetchingItems = false;
  String _itemSearchQuery = '';

  // Customer search & pagination
  final List<Map<String, dynamic>> _customers = [];
  String _customerSearchQuery = '';
  int _customerCurrentPage = 0;

  // Invoice search & pagination
  final List<Map<String, dynamic>> _invoices = [];
  String _invoiceSearchQuery = '';
  int _invoiceCurrentPage = 0;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
    _itemSearchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _searchController.dispose();
    _invoiceSearchController.dispose();
    _itemSearchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _filterItems() {
    setState(() {
      _itemSearchQuery = _itemSearchController.text.toLowerCase();
      if (_itemSearchQuery.isEmpty) {
        _filteredInvoiceItems = List.from(_invoiceItems);
      } else {
        _filteredInvoiceItems = _invoiceItems.where((item) {
          final name = (item['nameAr'] ?? '').toString().toLowerCase();
          final code = (item['itemCode'] ?? '').toString().toLowerCase();
          return name.contains(_itemSearchQuery) ||
              code.contains(_itemSearchQuery);
        }).toList();
      }
    });
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
        }
      });
    }
  }

  Future<void> _fetchInvoices() async {
    if (_selectedCustomer == null) return;

    setState(() {
      _isFetchingInvoices = true;
      _invoices.clear();
      _selectedInvoice = null;
      _invoiceItems.clear();
      _filteredInvoiceItems.clear();
    });

    final customerId =
        int.tryParse(_selectedCustomer!['id']?.toString() ?? '0') ?? 0;
    final result = await _apiService.getInvoicesByCustomer(customerId);

    if (mounted) {
      setState(() {
        _isFetchingInvoices = false;
        if (result['success']) {
          final List<dynamic> data = result['data'] ?? [];
          _invoices.addAll(
            data.map((e) => Map<String, dynamic>.from(e)).toList(),
          );
        }
      });
    }
  }

  List<Map<String, dynamic>> get _filteredCustomers {
    List<Map<String, dynamic>> filtered = _customers;
    if (_customerSearchQuery.isNotEmpty) {
      final query = _customerSearchQuery.toLowerCase();
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
    final start = _customerCurrentPage * _pageSize;
    if (start >= filtered.length) return [];
    final end = (start + _pageSize) > filtered.length
        ? filtered.length
        : (start + _pageSize);
    return filtered.sublist(start, end);
  }

  void _showCustomerSearch() {
    _customerSearchQuery = '';
    _searchController.clear();
    _customerCurrentPage = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setModalState) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setModalState(() {
                        _customerSearchQuery = value;
                        _customerCurrentPage = 0;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'ابحث باسم أو كود العميل...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                                      _selectedCustomer?['customerCode'] ==
                                      customer['customerCode'];
                                  return ListTile(
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
                                        _fetchInvoices();
                                      });
                                      Navigator.pop(context);
                                    },
                                    title: Text(
                                      customer['nameAr'] ?? 'بدون اسم',
                                      style: GoogleFonts.cairo(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
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
                                      onPressed: _customerCurrentPage > 0
                                          ? () => setModalState(
                                              () => _customerCurrentPage--,
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
                                      'صفحة ${_customerCurrentPage + 1} من ${(_filteredCustomers.length / _pageSize).ceil()}',
                                      style: GoogleFonts.cairo(fontSize: 12),
                                    ),
                                    TextButton.icon(
                                      onPressed:
                                          (_customerCurrentPage + 1) *
                                                  _pageSize <
                                              _filteredCustomers.length
                                          ? () => setModalState(
                                              () => _customerCurrentPage++,
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
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredInvoices {
    List<Map<String, dynamic>> filtered = _invoices;
    if (_invoiceSearchQuery.isNotEmpty) {
      final query = _invoiceSearchQuery.toLowerCase();
      filtered = _invoices.where((inv) {
        final autoNum = (inv['autoNumber'] ?? '').toString().toLowerCase();
        return autoNum.contains(query);
      }).toList();
    }
    return filtered;
  }

  List<Map<String, dynamic>> get _paginatedInvoices {
    final filtered = _filteredInvoices;
    final start = _invoiceCurrentPage * _pageSize;
    if (start >= filtered.length) return [];
    final end = (start + _pageSize) > filtered.length
        ? filtered.length
        : (start + _pageSize);
    return filtered.sublist(start, end);
  }

  void _showInvoiceSearch() {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار العميل أولاً')),
      );
      return;
    }

    _invoiceSearchQuery = '';
    _invoiceSearchController.clear();
    _invoiceCurrentPage = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setModalState) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _invoiceSearchController,
                    onChanged: (value) {
                      setModalState(() {
                        _invoiceSearchQuery = value;
                        _invoiceCurrentPage = 0;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'ابحث برقم الفاتورة...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _isFetchingInvoices
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredInvoices.isEmpty
                      ? Center(
                          child: Text(
                            'لا توجد فواتير لهذا العميل',
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
                                itemCount: _paginatedInvoices.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(),
                                itemBuilder: (context, index) {
                                  final invoice = _paginatedInvoices[index];
                                  final isSelected =
                                      _selectedInvoice?['autoNumber'] ==
                                      invoice['autoNumber'];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.primary
                                          .withOpacity(0.1),
                                      child: const Icon(
                                        Icons.description,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _selectedInvoice = invoice;
                                        _invoiceController.text =
                                            invoice['autoNumber'] ?? '';
                                        _fetchInvoiceItemsById(invoice['id']);
                                      });
                                      Navigator.pop(context);
                                    },
                                    title: Text(
                                      invoice['autoNumber'] ?? 'بدون رقم',
                                      style: GoogleFonts.cairo(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
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
                            if (_filteredInvoices.length > _pageSize)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      onPressed: _invoiceCurrentPage > 0
                                          ? () => setModalState(
                                              () => _invoiceCurrentPage--,
                                            )
                                          : null,
                                      icon: const Icon(
                                        Icons.arrow_back_ios,
                                        size: 16,
                                      ),
                                    ),
                                    Text(
                                      'صفحة ${_invoiceCurrentPage + 1} من ${(_filteredInvoices.length / _pageSize).ceil()}',
                                      style: GoogleFonts.cairo(fontSize: 12),
                                    ),
                                    IconButton(
                                      onPressed:
                                          (_invoiceCurrentPage + 1) *
                                                  _pageSize <
                                              _filteredInvoices.length
                                          ? () => setModalState(
                                              () => _invoiceCurrentPage++,
                                            )
                                          : null,
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
        ),
      ),
    );
  }

  Future<void> _fetchInvoiceItemsById(int invoiceId) async {
    setState(() => _isFetchingItems = true);
    final result = await _apiService.getInvoiceItemsById(invoiceId);
    if (mounted) {
      setState(() {
        _isFetchingItems = false;
        if (result['success']) {
          _invoiceItems = (result['data'] as List).map((item) {
            return {
              ...Map<String, dynamic>.from(item),
              'returnQty': 0,
              'controller': TextEditingController(text: '0'),
            };
          }).toList();
          _filterItems();
        } else {
          _invoiceItems = [];
          _filteredInvoiceItems = [];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'فشل في تحميل الفاتورة'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      });
    }
  }

  void _scanQRCode() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        child: MobileScanner(
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final String? code = barcodes.first.rawValue;
              if (code != null) {
                _invoiceController.text = code;
                Navigator.pop(context);
              }
            }
          },
        ),
      ),
    );
  }

  Future<void> _submitReturn() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الرجاء اختيار العميل')));
      return;
    }
    if (_selectedInvoice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار الفاتورة أولاً')),
      );
      return;
    }

    final returns = _invoiceItems
        .where((item) {
          final qtyText = item['controller'].text;
          final qty = int.tryParse(qtyText) ?? 0;
          return qty > 0;
        })
        .map((item) {
          return {
            'invoice_dtl_id': item['invoiceDtlId'] ?? item['invoice_dtl_id'] ?? 0,
            'qty': int.tryParse(item['controller'].text) ?? 0,
          };
        })
        .toList();

    if (returns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال الكميات المرتجعة')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final invoiceSalesId = int.tryParse(_selectedInvoice!['id']?.toString() ?? '0') ?? 0;
    
    final result = await _apiService.createReturnInvoice(
      invoiceSalesId: invoiceSalesId,
      notes: _notesController.text,
      items: returns,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        final returnData = result['return'] ?? {};
        final autoNumber = returnData['autoNumber'] ?? '---';
        
        _showSuccessDialog(autoNumber);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'فشل في إرسال المرتجع'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(String autoNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 20),
              Text(
                'تم إنشاء فاتورة المرتجع بنجاح',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'رقم الفاتورة: ',
                      style: GoogleFonts.cairo(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      autoNumber,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Dialog
                    Navigator.pop(context); // Screen
                  },
                  child: Text(
                    'حسناً',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
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
            'المرتجعات',
            style: GoogleFonts.cairo(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('اختيار العميل'),
                      _buildCustomerSelector(),
                      const SizedBox(height: 20),
                      _buildSectionTitle('بيانات الفاتورة'),
                      _buildInvoiceSelector(),
                      if (_invoiceItems.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildSectionTitle('ملاحظات'),
                        _buildNotesField(),
                      ],
                      if (_isFetchingItems)
                        const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      if (_invoiceItems.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildItemSearchField(),
                        const SizedBox(height: 15),
                        _buildItemsList(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (_invoiceItems.isNotEmpty) _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 4),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.person_pin_rounded,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedCustomer == null
                    ? 'بحث عن عميل...'
                    : '${_selectedCustomer!['customerCode'] ?? '---'} - ${_selectedCustomer!['nameAr'] ?? '---'}',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: _selectedCustomer == null
                      ? AppColors.textLight
                      : AppColors.textDark,
                  fontWeight: _selectedCustomer == null
                      ? FontWeight.normal
                      : FontWeight.bold,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceSelector() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _showInvoiceSearch,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.document_scanner_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedInvoice == null
                          ? 'اختيار الفاتورة...'
                          : (_selectedInvoice!['autoNumber'] ?? '---'),
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: _selectedInvoice == null
                            ? AppColors.textLight
                            : AppColors.textDark,
                        fontWeight: _selectedInvoice == null
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textLight,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 58,
          width: 58,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.white,
              size: 26,
            ),
            onPressed: _scanQRCode,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _notesController,
        style: GoogleFonts.cairo(fontSize: 14),
        maxLines: 2,
        decoration: InputDecoration(
          hintText: 'ملاحظات (اختياري)...',
          hintStyle: GoogleFonts.cairo(color: Colors.grey, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildItemSearchField() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _itemSearchController,
        style: GoogleFonts.cairo(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'ابحث في أصناف الفاتورة...',
          hintStyle: GoogleFonts.cairo(color: Colors.grey, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    if (_filteredInvoiceItems.isEmpty && _itemSearchQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'لا توجد نتائج بحث',
            style: GoogleFonts.cairo(color: AppColors.textLight),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredInvoiceItems.length,
      itemBuilder: (context, index) {
        final item = _filteredInvoiceItems[index];
        return _buildItemCard(item);
      },
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final soldQty = int.tryParse(item['qty']?.toString() ?? '0') ?? 0;
    final returnQty = int.tryParse(item['controller'].text) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 95,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Name and Code (Right side)
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['nameAr'] ?? 'صنف بدون اسم',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '#${item['itemCode'] ?? '---'}',
                        style: GoogleFonts.cairo(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                      if (item['itemSide'] != null) ...[
                        const SizedBox(width: 10),
                        Text(
                          item['itemSide'].toString(),
                          style: GoogleFonts.cairo(
                            color:
                                item['itemSide'].toString().toUpperCase() == 'L'
                                ? Colors.red
                                : Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          const VerticalDivider(width: 1, indent: 20, endIndent: 20),

          // Sold Qty Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'المباع',
                  style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  '$soldQty',
                  style: GoogleFonts.cairo(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const VerticalDivider(width: 1, indent: 15, endIndent: 15),

          // Return Qty Input
          InkWell(
            onTap: () => _updateItemQty(item, soldQty),
            child: Container(
              width: 55,
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: returnQty > 0
                    ? Colors.orange.shade100
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: returnQty > 0
                      ? Colors.orange.shade300
                      : Colors.transparent,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'المرتجع',
                      style: GoogleFonts.cairo(fontSize: 9, color: Colors.grey),
                    ),
                    Text(
                      item['controller'].text,
                      style: GoogleFonts.cairo(
                        color: returnQty > 0
                            ? Colors.orange.shade700
                            : AppColors.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateItemQty(Map<String, dynamic> item, int soldQty) {
    int currentReturnQty = int.tryParse(item['controller'].text) ?? 0;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'تعديل الكمية المرتجعة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item['nameAr'] ?? '',
                    style: GoogleFonts.cairo(fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'الكمية المباعة: $soldQty',
                    style: GoogleFonts.cairo(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () {
                          if (currentReturnQty > 0) {
                            setDialogState(() => currentReturnQty--);
                          }
                        },
                        child: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Text(
                          '$currentReturnQty',
                          style: GoogleFonts.cairo(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          if (currentReturnQty < soldQty) {
                            setDialogState(() => currentReturnQty++);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'الكمية المرتجعة لا يمكن أن تتجاوز المباعة',
                                ),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        child: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.green,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: GoogleFonts.cairo(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                setState(() {
                  item['controller'].text = currentReturnQty.toString();
                });
                Navigator.pop(context);
              },
              child: Text(
                'تأكيد',
                style: GoogleFonts.cairo(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    final activeReturns = _invoiceItems
        .where((i) => (int.tryParse(i['controller'].text) ?? 0) > 0)
        .length;

    return Container(
      padding: const EdgeInsets.all(20),
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
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أصناف مرتجعة',
                  style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  '$activeReturns صنف',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: CustomButton(
                text: 'إرسال المرتجع',
                isLoading: _isLoading,
                onPressed: _submitReturn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
