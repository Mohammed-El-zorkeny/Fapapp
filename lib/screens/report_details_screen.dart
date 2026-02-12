import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/price_list_model.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportDetailsScreen extends StatefulWidget {
  final int priceListId;

  const ReportDetailsScreen({super.key, required this.priceListId});

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

enum FilterState { all, selected, unselected }

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  final ApiService _apiService = ApiService();
  List<PriceListItemModel> _items = [];
  List<PriceListItemModel> _filteredItems = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  FilterState _currentFilter = FilterState.all;

  double get _totalAmount =>
      _items.fold(0, (sum, item) => sum + (item.price * item.quantity));

  @override
  void initState() {
    super.initState();
    _fetchItems();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _items.where((item) {
        final matchesQuery =
            item.nameAr.toLowerCase().contains(query) ||
            item.itemCode.toLowerCase().contains(query);
        if (!matchesQuery) return false;

        switch (_currentFilter) {
          case FilterState.selected:
            return item.quantity > 0;
          case FilterState.unselected:
            return item.quantity == 0;
          case FilterState.all:
            return true;
        }
      }).toList();
    });
  }

  void _toggleFilter() {
    setState(() {
      if (_currentFilter == FilterState.all) {
        _currentFilter = FilterState.selected;
      } else if (_currentFilter == FilterState.selected) {
        _currentFilter = FilterState.unselected;
      } else {
        _currentFilter = FilterState.all;
      }
    });
    _applyFilters();
  }

  Future<void> _fetchItems() async {
    setState(() => _isLoading = true);
    final result = await _apiService.getPriceListItems(widget.priceListId);

    if (!mounted) return;

    if (result['success']) {
      final List data = result['data']['items'];
      final items = data
          .map((json) => PriceListItemModel.fromJson(json))
          .toList();
      setState(() {
        _items = items;
        _filteredItems = items;
        _isLoading = false;
      });
    } else {
      if (result['authError'] == true) {
        setState(() {
          _errorMessage = 'جلسة غير صالحة';
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

  void _updateQuantity(PriceListItemModel item, int newQty) {
    if (newQty < item.minQty && newQty != 0) {
      // Allow 0, or >= minQty
      // Assuming user wants to delete if 0, but if specifically setting a value it must be >= minQty
      // But requirement says: "If minQty > 0: Auto-fill... CANNOT enter less than minQty... Can only increase"
      // It implies if I start editing, I must respect minQty.
      // However, 0 should be allowed if checking "unselected".
      // Let's enforce strictly: newQty must be 0 OR >= minQty.
      return;
    }
    setState(() {
      item.quantity = newQty;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const SizedBox.shrink(),
        title: const Text(
          'تفاصيل الكشف',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
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
            // Search Bar with Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  // Filter Icon (Interactive)
                  GestureDetector(
                    onTap: _toggleFilter,
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: _getFilterColor(),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getFilterIcon(),
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Search TextField
                  Expanded(
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDEDED),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _searchController,
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(
                          hintText: 'إبحث..',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          suffixIcon: Icon(
                            Icons.search,
                            color: Colors.grey,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Items List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : _filteredItems.isEmpty
                  ? const Center(child: Text('لا توجد أصناف'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        return _buildItemCard(_filteredItems[index]);
                      },
                    ),
            ),

            // Bottom Sticky Bar
            if (!_isLoading) _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Color _getFilterColor() {
    switch (_currentFilter) {
      case FilterState.selected:
        return Colors.red;
      case FilterState.unselected:
        return Colors.grey;
      case FilterState.all:
        return const Color(0xFF5D5D5D);
    }
  }

  IconData _getFilterIcon() {
    switch (_currentFilter) {
      case FilterState.selected:
        return Icons.filter_alt;
      case FilterState.unselected:
        return Icons.filter_alt_off;
      case FilterState.all:
        return Icons.filter_list;
    }
  }

  Widget _buildItemCard(PriceListItemModel item) {
    return Slidable(
      key: ValueKey(item.id),
      direction: Axis.horizontal,
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _swipeDelete(item),
            backgroundColor: const Color(0xFFD32F2F),
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'حذف',
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => _showQuantityDialog(context, item),
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 85,
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
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nameAr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '#${item.itemCode}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Direction Column (New)
              Container(
                width: 55,
                alignment: Alignment.center,
                child: Text(
                  item.itemSide.toUpperCase(),
                  style: TextStyle(
                    color: item.itemSide.toUpperCase() == 'L'
                        ? const Color(0xFFD32F2F)
                        : const Color(0xFF2196F3),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Price Section
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.price.toStringAsFixed(2),
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const Text(
                    'ج.م',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(width: 12),

              // Dotted Line
              CustomPaint(
                size: const Size(1, 40),
                painter: DottedLinePainter(),
              ),

              // Quantity (Left side)
              GestureDetector(
                onTap: () => _showQuantityDialog(context, item),
                child: Container(
                  width: 50,
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.quantity > 0
                        ? AppColors.primary
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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

  void _swipeDelete(PriceListItemModel item) {
    if (item.quantity == 0) return;

    final int previousQty = item.quantity;
    setState(() {
      item.quantity = 0;
    });
    _applyFilters();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حذف ${item.nameAr}'),
        action: SnackBarAction(
          label: 'تراجع',
          onPressed: () {
            setState(() {
              item.quantity = previousQty;
            });
            _applyFilters();
          },
        ),
      ),
    );
  }

  Future<void> _showQuantityDialog(
    BuildContext context,
    PriceListItemModel item,
  ) async {
    int initialQty = item.quantity;
    if (initialQty == 0 && item.minQty > 0) {
      initialQty = item.minQty;
    }

    int qty = initialQty;
    final TextEditingController qtyController = TextEditingController(
      text: qty.toString(),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.nameAr, textAlign: TextAlign.center),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'السعر الحالي: ${item.price.toStringAsFixed(2)} ج.م',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        int nextQty = qty - 1;
                        if (item.minQty > 0 && nextQty < item.minQty) return;
                        if (nextQty < 0) nextQty = 0;
                        setDialogState(() {
                          qty = nextQty;
                          qtyController.text = qty.toString();
                        });
                      },
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                    ),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: qtyController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '0',
                        ),
                        onChanged: (value) {
                          final newQty = int.tryParse(value);
                          if (newQty != null) {
                            qty = newQty;
                          }
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setDialogState(() {
                          qty++;
                          qtyController.text = qty.toString();
                        });
                      },
                      icon: const Icon(Icons.add_circle, color: Colors.green),
                    ),
                  ],
                ),
                if (item.minQty > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'الحد الأدنى: ${item.minQty}',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'الإجمالي: ${(qty * item.price).toStringAsFixed(2)} ج.م',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (qty > 0 && qty < item.minQty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'عفواً، الحد الأدنى للكمية هو ${item.minQty}',
                    ),
                  ),
                );
                return;
              }
              _updateQuantity(item, qty);
              Navigator.pop(context);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'عدد الأصناف',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                '${_items.where((i) => i.quantity > 0).length} أصناف',
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: GestureDetector(
              onTap: () {
                final selectedItems = _items
                    .where((i) => i.quantity > 0)
                    .toList();
                if (selectedItems.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى اختيار أصناف أولاً')),
                  );
                  return;
                }
                _showCreateOrderDialog(selectedItems);
              },
              child: Container(
                height: 55,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _totalAmount.toStringAsFixed(2),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(width: 1, height: 25, color: Colors.white24),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'إنشاء طلب جديد',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  void _showCreateOrderDialog(List<PriceListItemModel> selectedItems) {
    if (selectedItems.isEmpty) return; // Should be checked before calling

    final totalValue = selectedItems.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    final int itemsCount = selectedItems.length;
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إنشاء طلب جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Summary
            Text('عدد الأصناف: $itemsCount'),
            Text('الإجمالي: ${totalValue.toStringAsFixed(2)} جنيه'),
            const SizedBox(height: 16),

            // Notes field
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات (اختياري)',
                hintText: 'أضف ملاحظات على الطلب...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => _createOrder(selectedItems, notesController.text),
            child: const Text('إنشاء الطلب'),
          ),
        ],
      ),
    );
  }

  Future<void> _createOrder(
    List<PriceListItemModel> selectedItems,
    String notes,
  ) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Get token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // Prepare items array
      List<Map<String, dynamic>> itemsArray = selectedItems
          .map((item) => {"itemId": item.id, "qty": item.quantity})
          .toList();

      // Request body
      final body = {
        "priceListId": widget.priceListId,
        "notes": notes.trim(),
        "items": itemsArray,
      };

      // API call
      final dio = Dio();
      dio.options.headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await dio.post(
        'https://fapautoapps.com/ords/app/Transactions/CreateRequestInvoice',
        data: body,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading
      Navigator.pop(context); // Close dialog

      // Success
      final orderNumber = response.data['order']['autoNumber'];
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('✅ تم إنشاء الطلب'),
          content: Text('رقم الطلب: $orderNumber'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Go back to price lists
              },
              child: const Text('عودة للكشوفات'),
            ),
          ],
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      String errorMsg = 'حدث خطأ في إنشاء الطلب';

      if (e.response?.statusCode == 401) {
        errorMsg = 'جلستك انتهت. يرجى تسجيل الدخول';
        // Navigate to login if needed
      } else if (e.response?.statusCode == 403) {
        errorMsg = 'ليس لديك صلاحية';
      } else if (e.response?.data is Map &&
          e.response!.data['messageAr'] != null) {
        errorMsg = e.response!.data['messageAr'];
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('خطأ'),
          content: Text(errorMsg),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('حاول مرة أخرى'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildHeaderIcon(IconData icon, {Color? color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Icon(icon, color: color ?? AppColors.textDark, size: 20),
      ),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double dashHeight = 3, dashSpace = 2, startY = 0;
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.5)
      ..strokeWidth = 1;

    double currentY = startY;
    while (currentY < size.height) {
      canvas.drawLine(
        Offset(0, currentY),
        Offset(0, currentY + dashHeight),
        paint,
      );
      currentY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
