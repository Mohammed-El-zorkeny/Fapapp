import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/order_details_model.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class OrderEditScreen extends StatefulWidget {
  final int orderId;
  const OrderEditScreen({super.key, required this.orderId});

  @override
  State<OrderEditScreen> createState() => _OrderEditScreenState();
}

class _OrderEditScreenState extends State<OrderEditScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  OrderDetailsModel? _orderDetails;
  OrderDetailsModel? _originalOrderDetails;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<OrderItem> _filteredSelectedItems = [];
  List<AvailableItem> _filteredAvailableItems = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_applyFilters);
    _loadOrderDetails();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    if (_orderDetails == null) return;
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredSelectedItems = _orderDetails!.selectedItems.where((item) {
        final matchesQuery =
            item.nameAr.toLowerCase().contains(query) ||
            item.itemCode.toLowerCase().contains(query);
        return matchesQuery;
      }).toList();

      _filteredAvailableItems = _orderDetails!.availableItems.where((item) {
        final matchesQuery =
            item.nameAr.toLowerCase().contains(query) ||
            item.itemCode.toLowerCase().contains(query);
        return matchesQuery;
      }).toList();
    });
  }

  void _loadOrderDetails() async {
    setState(() => _isLoading = true);

    final response = await ApiService().getOrderDetails(widget.orderId);
    if (response['success'] == true && response['data'] != null) {
      if (mounted) {
        setState(() {
          _orderDetails = OrderDetailsModel.fromJson(response['data']);
          _originalOrderDetails = OrderDetailsModel.fromJson(
            response['data'],
          ); // Store original for ACTION calculation
          _applyFilters();
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'حدث خطأ')),
        );
      }
    }
  }

  void _recalculateTotal() {
    if (_orderDetails == null) return;
    double newTotal = 0;
    for (var item in _orderDetails!.selectedItems) {
      item.totalValue = item.qty * item.price;
      newTotal += item.totalValue;
    }
    setState(() {
      _orderDetails!.orderInfo.orderTotal = newTotal;
    });
  }

  void _saveChanges() async {
    if (_orderDetails == null || _originalOrderDetails == null) return;
    setState(() => _isLoading = true);

    List<Map<String, dynamic>> itemsPayload = [];

    // Check for ADD and UPDATE
    for (var currentItem in _orderDetails!.selectedItems) {
      if (currentItem.dtlId == null || currentItem.dtlId == 0) {
        // ADD
        itemsPayload.add({
          "action": "ADD",
          "itemId": currentItem.itemId,
          "qty": currentItem.qty,
        });
      } else {
        // UPDATE
        final originalItemList = _originalOrderDetails!.selectedItems
            .where((element) => element.dtlId == currentItem.dtlId)
            .toList();
        final originalItem = originalItemList.isNotEmpty
            ? originalItemList[0]
            : null;

        if (originalItem != null && originalItem.qty != currentItem.qty) {
          itemsPayload.add({
            "action": "UPDATE",
            "dtlId": currentItem.dtlId,
            "qty": currentItem.qty,
          });
        }
      }
    }

    // Check for DELETE
    for (var originalItem in _originalOrderDetails!.selectedItems) {
      final stillExists = _orderDetails!.selectedItems.any(
        (element) => element.dtlId == originalItem.dtlId,
      );
      if (!stillExists && originalItem.dtlId != null) {
        itemsPayload.add({"action": "DELETE", "dtlId": originalItem.dtlId});
      }
    }

    if (itemsPayload.isEmpty) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لم يتم تعديل أي بيانات')));
      return;
    }

    final response = await ApiService().updateOrderDetails(
      orderId: _orderDetails!.orderInfo.orderId,
      items: itemsPayload,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (response['success']) {
        final data = response['data']?['summary'] ?? {};
        final newTotal =
            data['newTotal'] ?? _orderDetails!.orderInfo.orderTotal;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Column(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 50),
                const SizedBox(height: 10),
                Text(
                  response['message'] ?? 'تم تعديل الطلب بنجاح',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('تم حفظ التعديلات ويمكنك متابعتها الآن'),
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
                    'تم التحديث بـ ${newTotal} ج.م',
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
                    Navigator.pop(context, true); // Go back to orders
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'عودة للطلبات',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'فشل الحفظ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          title: const Text(
            'تعديل الطلب',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _orderDetails == null
            ? const Center(child: Text('لم يتم العثور على بيانات'))
            : Column(
                children: [
                  _buildOrderSummaryCard(),

                  // Interactive Elements (Search)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
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
                                hintText: 'إبحث عن صنف..',
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

                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: AppColors.primary,
                      tabs: const [
                        Tab(text: 'الأصناف المحددة'),
                        Tab(text: 'إضافة أصناف'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSelectedItemsList(),
                        _buildAvailableItemsList(),
                      ],
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: (_isLoading || _orderDetails == null)
            ? null
            : _buildBottomBar(),
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
                '${_orderDetails!.selectedItems.length} أصناف',
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
              onTap: _showOrderSummaryBottomSheet,
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
                        _orderDetails!.orderInfo.orderTotal.toStringAsFixed(2),
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
                          'حفظ التعديلات',
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
    if (_orderDetails == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
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
                    'مراجعة وتأكيد التعديلات',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _orderDetails!.selectedItems.length,
                      itemBuilder: (context, index) {
                        final item = _orderDetails!.selectedItems[index];
                        return ListTile(
                          title: Text(item.nameAr),
                          subtitle: Text(
                            'الكمية: ${item.qty} × ${item.price.toStringAsFixed(2)} = ${(item.qty * item.price).toStringAsFixed(2)} ج.م',
                          ),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: const Text(
                              'ج',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
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
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'الإجمالي',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_orderDetails!.orderInfo.orderTotal.toStringAsFixed(2)} ج.م',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(
                                context,
                              ); // Close bottom sheet first
                              _saveChanges(); // Trigger process and show loading in main screen
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text(
                              'تأكيد التعديلات الآن',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
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

  Widget _buildOrderSummaryCard() {
    final info = _orderDetails!.orderInfo;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(15),
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryShadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'طلب: ${info.autoNumberBra}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                info.invDate,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  info.statusAr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${info.orderTotal.toStringAsFixed(2)} ج.م',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildSelectedItemsList() {
    final items = _filteredSelectedItems;
    if (items.isEmpty) {
      return const Center(child: Text('لا توجد أصناف محددة'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Slidable(
          key: ValueKey(item.itemId),
          direction: Axis.horizontal,
          startActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              SlidableAction(
                onPressed: (_) {
                  final deletedItem = item;
                  final deletedIndex = _orderDetails!.selectedItems.indexWhere(
                    (i) => i.itemId == item.itemId,
                  );

                  setState(() {
                    if (deletedIndex != -1) {
                      _orderDetails!.selectedItems.removeAt(deletedIndex);
                      _recalculateTotal();
                      _applyFilters();
                    }
                  });

                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(seconds: 8),
                      content: Row(
                        children: [
                          Expanded(child: Text('تم حذف ${item.nameAr}')),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                if (deletedIndex != -1) {
                                  _orderDetails!.selectedItems.insert(
                                    deletedIndex,
                                    deletedItem,
                                  );
                                  _recalculateTotal();
                                  _applyFilters();
                                }
                              });
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
                },
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
          child:
              GestureDetector(
                onTap: () => _showSelectedQuantityDialog(context, item),
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

                      // Direction Column
                      Container(
                        width: 55,
                        alignment: Alignment.center,
                        child: Text(
                          (item.itemSide ?? '').toUpperCase(),
                          style: TextStyle(
                            color: (item.itemSide ?? '').toUpperCase() == 'L'
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
                      Container(
                        width: 50,
                        margin: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${item.qty}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn().moveY(
                begin: 10,
                end: 0,
                delay: Duration(milliseconds: 50 * index),
              ),
        );
      },
    );
  }

  Widget _buildAvailableItemsList() {
    final items = _filteredAvailableItems;
    if (items.isEmpty) {
      return const Center(child: Text('لا توجد أصناف متاحة'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => _showAvailableQuantityDialog(context, item),
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

                // Direction Column
                Container(
                  width: 55,
                  alignment: Alignment.center,
                  child: Text(
                    (item.itemSide ?? '').toUpperCase(),
                    style: TextStyle(
                      color: (item.itemSide ?? '').toUpperCase() == 'L'
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

                // Add button instead of quantity
                Container(
                  width: 50,
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.add, color: AppColors.textDark),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn().moveY(
          begin: 10,
          end: 0,
          delay: Duration(milliseconds: 50 * index),
        );
      },
    );
  }

  Future<void> _showSelectedQuantityDialog(
    BuildContext context,
    OrderItem item,
  ) async {
    int qty = item.qty;
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
                  'السعر: ${item.price.toStringAsFixed(2)} ج.م',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (qty > 1) {
                          setDialogState(() {
                            qty--;
                            qtyController.text = qty.toString();
                          });
                        }
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
                        ),
                        onChanged: (value) {
                          final newQty = int.tryParse(value);
                          if (newQty != null && newQty > 0) {
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
              setState(() {
                item.qty = qty;
                _recalculateTotal();
              });
              Navigator.pop(context);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAvailableQuantityDialog(
    BuildContext context,
    AvailableItem item,
  ) async {
    int qty = 1;
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
                  'السعر: ${item.price.toStringAsFixed(2)} ج.م',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (qty > 1) {
                          setDialogState(() {
                            qty--;
                            qtyController.text = qty.toString();
                          });
                        }
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
                        ),
                        onChanged: (value) {
                          final newQty = int.tryParse(value);
                          if (newQty != null && newQty > 0) {
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
              if (qty > 0 && item.minQty > 0 && qty < item.minQty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'عفواً، الحد الأدنى للكمية هو ${item.minQty}',
                    ),
                  ),
                );
                return;
              }
              item.tempQty = qty;
              _addItemToSelected(item);
              Navigator.pop(context);
            },
            child: const Text('إضافة للطلب'),
          ),
        ],
      ),
    );
  }

  void _addItemToSelected(AvailableItem availableItem) {
    // Check if item already selected
    final existingIndex = _orderDetails!.selectedItems.indexWhere(
      (i) => i.itemId == availableItem.itemId,
    );

    setState(() {
      if (existingIndex >= 0) {
        _orderDetails!.selectedItems[existingIndex].qty +=
            availableItem.tempQty;
      } else {
        _orderDetails!.selectedItems.add(
          OrderItem(
            itemId: availableItem.itemId,
            itemCode: availableItem.itemCode,
            nameAr: availableItem.nameAr,
            nameEn: availableItem.nameEn,
            itemSide: availableItem.itemSide,
            qty: availableItem.tempQty,
            price: availableItem.price,
            totalValue: availableItem.price * availableItem.tempQty,
          ),
        );
      }

      // Reset temp qty
      availableItem.tempQty = 1;
      _recalculateTotal();
      _applyFilters();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تمت إضافة الصنف بنجاح'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.green,
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
