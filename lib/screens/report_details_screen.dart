import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/price_list_model.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/screenshot_protection_mixin.dart';
import 'orders_screen.dart';

class ReportDetailsScreen extends StatefulWidget {
  final int priceListId;
  final String priceListName;

  const ReportDetailsScreen({
    super.key,
    required this.priceListId,
    required this.priceListName,
  });

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

enum FilterState { all, selected, unselected }

class _ReportDetailsScreenState extends State<ReportDetailsScreen>
    with ScreenshotProtectionMixin {
  final ApiService _apiService = ApiService();
  List<PriceListItemModel> _items = [];
  List<PriceListItemModel> _filteredItems = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  FilterState _currentFilter = FilterState.all;

  // Group Filter State
  List<Map<String, dynamic>> _groups = [];
  Set<int> _selectedGroupIds = {};
  bool _isLoadingGroups = false;

  // Cart State (Persists selections across group filters)
  final Map<int, int> _cart = {}; // itemId -> quantity
  final Map<int, PriceListItemModel> _cartItemsData = {}; // itemId -> model

  double get _totalAmount {
    double total = 0;
    _cart.forEach((itemId, qty) {
      final item = _cartItemsData[itemId];
      if (item != null) {
        total += item.price * qty;
      }
    });
    return total;
  }

  @override
  void initState() {
    super.initState();
    initScreenshotProtection();
    _fetchGroups();
    _fetchItems();
    _searchController.addListener(_applyFilters);
  }

  Future<void> _fetchGroups() async {
    setState(() => _isLoadingGroups = true);
    final result = await _apiService.getStockGroups();
    if (mounted) {
      setState(() {
        _isLoadingGroups = false;
        if (result['success']) {
          _groups = List<Map<String, dynamic>>.from(result['data']);
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    disposeScreenshotProtection();
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

    String? groupIdsStr;
    if (_selectedGroupIds.isNotEmpty) {
      groupIdsStr = _selectedGroupIds.join(',');
    }

    final result = await _apiService.getPriceListItems(
      widget.priceListId,
      groupIds: groupIdsStr,
    );

    if (!mounted) return;

    if (result['success']) {
      final List data = result['data']['items'];
      final items = data
          .map((json) => PriceListItemModel.fromJson(json))
          .toList();

      // Sync with cart
      for (var item in items) {
        if (_cart.containsKey(item.id)) {
          item.quantity = _cart[item.id]!;
          _cartItemsData[item.id] = item; // Update/Store metadata
        }
      }

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
      return;
    }
    setState(() {
      item.quantity = newQty;
      if (newQty <= 0) {
        _cart.remove(item.id);
        _cartItemsData.remove(item.id);
      } else {
        _cart[item.id] = newQty;
        _cartItemsData[item.id] = item;
      }
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
        title: Text(
          widget.priceListName,
          style: const TextStyle(
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
                        borderRadius: BorderRadius.circular(
                          10,
                        ), // Matched style
                      ),
                      child: Icon(
                        _getFilterIcon(),
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Group Filter Button (New)
                  GestureDetector(
                    onTap: _showGroupFilterSheet,
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: _selectedGroupIds.isEmpty
                            ? Colors.grey.shade400
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.category_outlined,
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
              child: _isLoading || _isLoadingGroups
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 10),
                          Text(
                            _isLoadingGroups
                                ? 'جاري تحميل المجموعات...'
                                : 'جاري تحميل الأصناف...',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
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
    _updateQuantity(item, 0); // Use common logic

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        content: Row(
          children: [
            Expanded(child: Text('تم حذف ${item.nameAr}')),
            TextButton(
              onPressed: () {
                _updateQuantity(item, previousQty);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'تراجع',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              icon: const Icon(Icons.close, color: Colors.white, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
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
                '${_cart.length} أصناف',
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_cart.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _cart.clear();
                      _cartItemsData.clear();
                      for (var item in _items) {
                        item.quantity = 0;
                      }
                    });
                    _applyFilters();
                  },
                  child: const Text(
                    'مسح الكل',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_cart.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى اختيار أصناف أولاً')),
                  );
                  return;
                }
                _showOrderSummaryBottomSheet();
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

  void _showOrderSummaryBottomSheet() {
    final TextEditingController notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final items = _cart.entries.map((e) {
            final data = _cartItemsData[e.key];
            return {
              'id': e.key,
              'qty': e.value,
              'name': data?.nameAr ?? 'صنف #${e.key}',
              'price': data?.price ?? 0.0,
              'code': data?.itemCode ?? '---',
            };
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
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
                  const SizedBox(height: 20),
                  const Text(
                    'مراجعة وتأكيد الطلب',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),

                  // Summary Header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'عدد الأصناف: ${items.length}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'الإجمالي: ${_totalAmount.toStringAsFixed(2)} جنيه',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Selected Items List
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'] as String,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'كود: ${item['code']} | السعر: ${item['price']} ج.م',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'x${item['qty']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 15),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setModalState(() {
                                    final id = item['id'] as int;
                                    _cart.remove(id);
                                    _cartItemsData.remove(id);

                                    // Update main UI if item is visible
                                    final mainItem = _items
                                        .where((i) => i.id == id)
                                        .firstOrNull;
                                    if (mainItem != null) {
                                      setState(() => mainItem.quantity = 0);
                                    }
                                  });
                                  if (_cart.isEmpty) Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Notes Box
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'أضف ملاحظاتك هنا...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  ),

                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          final selectedItems = _cart.entries.map((e) {
                            return PriceListItemModel(
                              id: e.key,
                              itemCode: _cartItemsData[e.key]?.itemCode ?? '',
                              nameAr: _cartItemsData[e.key]?.nameAr ?? '',
                              itemSide: '',
                              price: _cartItemsData[e.key]?.price ?? 0.0,
                              minQty: 0,
                              quantity: e.value,
                            );
                          }).toList();
                          _createOrder(selectedItems, notesController.text);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'تأكيد وإرسال الطلب',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
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
      // Prepare items array
      List<Map<String, dynamic>> itemsArray = selectedItems
          .map((item) => {"itemId": item.id, "qty": item.quantity})
          .toList();

      final result = await _apiService.createRequestInvoice(
        priceListId: widget.priceListId,
        notes: notes.trim(),
        items: itemsArray,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (result['success']) {
        Navigator.pop(context); // Close creation dialog

        final order = result['order'];
        final orderNumber =
            order['autoNumber'] ?? order['autoNumberBra'] ?? '---';

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Column(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 50),
                const SizedBox(height: 10),
                Text(
                  result['message'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('تم تسجيل طلبك ويمكنك متابعته الآن'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'رقم الطلب: $orderNumber',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const OrdersScreen(),
                      ),
                      (route) => route.isFirst,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'الذهاب للطلبات',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        // Show error from result
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('خطأ'),
            content: Text(result['message']),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حاول مرة أخرى'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ غير متوقع: $e')));
    }
  }

  void _showGroupFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _GroupFilterBottomSheet(
        groups: _groups,
        initialSelection: _selectedGroupIds,
        onApplied: (selected) {
          setState(() {
            _selectedGroupIds = selected;
          });
          _fetchItems();
        },
      ),
    );
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

class _GroupFilterBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> groups;
  final Set<int> initialSelection;
  final Function(Set<int>) onApplied;

  const _GroupFilterBottomSheet({
    required this.groups,
    required this.initialSelection,
    required this.onApplied,
  });

  @override
  State<_GroupFilterBottomSheet> createState() =>
      _GroupFilterBottomSheetState();
}

class _GroupFilterBottomSheetState extends State<_GroupFilterBottomSheet> {
  late Set<int> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = Set.from(widget.initialSelection);
  }

  void _toggleSelectAll() {
    setState(() {
      if (_tempSelected.length == widget.groups.length) {
        _tempSelected.clear();
      } else {
        _tempSelected = widget.groups.map((g) => g['id'] as int).toSet();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAllSelected =
        widget.groups.isNotEmpty &&
        _tempSelected.length == widget.groups.length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'تصفية حسب المجموعة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  TextButton(
                    onPressed: _toggleSelectAll,
                    child: Text(
                      isAllSelected ? 'إلغاء الكل' : 'تحديد الكل',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Groups List
            Expanded(
              child: widget.groups.isEmpty
                  ? const Center(child: Text('لا توجد مجموعات متاحة'))
                  : ListView.builder(
                      itemCount: widget.groups.length,
                      itemBuilder: (context, index) {
                        final group = widget.groups[index];
                        final id = group['id'] as int;
                        final name = group['nameAr'] ?? '';
                        final isSelected = _tempSelected.contains(id);

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _tempSelected.add(id);
                              } else {
                                _tempSelected.remove(id);
                              }
                            });
                          },
                          title: Text(
                            name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textDark,
                            ),
                          ),
                          activeColor: AppColors.primary,
                          checkboxShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      },
                    ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApplied(_tempSelected);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'تطبيق الفلتر',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                ],
              ),
            ),
          ],
        ),
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
