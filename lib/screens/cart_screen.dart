import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../utils/cart_provider.dart';
import '../utils/user_session.dart';
import '../services/api_service.dart';
import 'orders_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartProvider _cart = CartProvider.instance;
  final ApiService _apiService = ApiService();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _isSendingOrders = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _placeAllOrders() async {
    final groups = _cart.groups;
    if (groups.isEmpty) return;

    setState(() => _isSendingOrders = true);

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF6366F1)),
              const SizedBox(height: 16),
              Text(
                'جاري إرسال ${groups.length} ${groups.length == 1 ? 'طلب' : 'طلبات'}...',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    List<String> successOrders = [];
    List<String> failedOrders = [];

    for (final group in groups) {
      final items = group.entries
          .map((e) => {'itemId': e.item.id, 'qty': e.item.quantity})
          .toList();

      final result = await _apiService.createRequestInvoice(
        priceListId: group.priceListId,
        notes: _notesController.text.trim(),
        items: items,
      );

      if (result['success']) {
        final order = result['order'];
        final orderNumber = order?['autoNumber'] ?? order?['autoNumberBra'] ?? '---';
        successOrders.add('${group.priceListName}: #$orderNumber');
      } else {
        failedOrders.add('${group.priceListName}: ${result['message']}');
      }
    }

    if (!mounted) return;
    Navigator.pop(context); // close loading dialog
    setState(() => _isSendingOrders = false);

    // Show results
    _showResultDialog(successOrders, failedOrders);
  }

  void _showResultDialog(List<String> successes, List<String> failures) {
    final allSuccess = failures.isEmpty;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              Icon(
                allSuccess ? Icons.check_circle_rounded : Icons.info_rounded,
                color: allSuccess ? AppColors.success : AppColors.warning,
                size: 52,
              ),
              const SizedBox(height: 8),
              Text(
                allSuccess ? 'تم إرسال جميع الطلبات!' : 'نتيجة الإرسال',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (successes.isNotEmpty) ...[
                Text('✅ تم بنجاح:', style: GoogleFonts.cairo(color: AppColors.success, fontWeight: FontWeight.bold)),
                ...successes.map((s) => Padding(
                  padding: const EdgeInsets.only(right: 8, top: 4),
                  child: Text(s, style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textMedium)),
                )),
              ],
              if (failures.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('❌ فشل:', style: GoogleFonts.cairo(color: AppColors.error, fontWeight: FontWeight.bold)),
                ...failures.map((f) => Padding(
                  padding: const EdgeInsets.only(right: 8, top: 4),
                  child: Text(f, style: GoogleFonts.cairo(fontSize: 12, color: AppColors.error)),
                )),
              ],
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (successes.isNotEmpty) {
                    _cart.clearAll();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const OrdersScreen()),
                      (route) => route.isFirst,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  successes.isNotEmpty ? 'الذهاب للطلبات' : 'حسناً',
                  style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
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
    return AnimatedBuilder(
      animation: _cart,
      builder: (context, _) {
        final allGroups = _cart.groups;

        // Filter groups/items based on search query
        final filteredGroups = _searchQuery.isEmpty
            ? allGroups
            : allGroups.map((g) {
                final filteredEntries = g.entries.where((e) {
                  final name = e.item.nameAr.toLowerCase();
                  final code = e.item.itemCode.toLowerCase();
                  final words = _searchQuery.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
                  // كل كلمة لازم تكون موجودة في الاسم أو الكود
                  return words.every((word) => name.contains(word) || code.contains(word));
                }).toList();
                if (filteredEntries.isEmpty) return null;
                final subtotal = filteredEntries.fold(
                  0.0, (s, e) => s + e.item.price * e.item.quantity);
                return (
                  priceListId: g.priceListId,
                  priceListName: g.priceListName,
                  entries: filteredEntries,
                  subtotal: subtotal,
                );
              }).whereType<({int priceListId, String priceListName, List<CartEntry> entries, double subtotal})>().toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FB),
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                _buildAppBar(allGroups.length),
                if (allGroups.isNotEmpty) _buildSearchBar(),
                Expanded(
                  child: allGroups.isEmpty
                      ? _buildEmptyCart()
                      : filteredGroups.isEmpty
                      ? _buildNoResults()
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          children: [
                            ...filteredGroups.asMap().entries.map((e) =>
                              _buildGroupCard(e.value, e.key)
                            ),
                            const SizedBox(height: 8),
                            _buildNotesField(),
                            const SizedBox(height: 100),
                          ],
                        ),
                ),
                if (allGroups.isNotEmpty) _buildCheckoutBar(allGroups.length),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(int groupCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F6),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.arrow_forward_ios, color: Color(0xFF3A3F47), size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.shopping_cart_rounded, color: Color(0xFF6366F1), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سلة المشتريات',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF1E293B),
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),
                if (groupCount > 0)
                  Text(
                    '$groupCount ${groupCount == 1 ? 'كشف' : 'كشوفات'} — ${_cart.totalItemCount} صنف',
                    style: GoogleFonts.cairo(color: const Color(0xFF94A3B8), fontSize: 12),
                  ),
              ],
            ),
          ),
          if (!_cart.isEmpty)
            GestureDetector(
              onTap: () => _confirmClearAll(),
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF4444), size: 20),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.cairo(fontSize: 14, color: const Color(0xFF1E293B)),
                decoration: InputDecoration(
                  hintText: 'ابحث في السلة بالاسم أو الكود...',
                  hintStyle: GoogleFonts.cairo(color: const Color(0xFFB0B8C4), fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  isDense: true,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () => _searchController.clear(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Color(0xFFE2E8F0), shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 14, color: Color(0xFF64748B)),
                  ),
                ),
              )
            else
              const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 60, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text('لا توجد نتائج', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
          const SizedBox(height: 6),
          Text('"$_searchQuery" غير موجود في السلة', style: GoogleFonts.cairo(fontSize: 13, color: const Color(0xFF94A3B8))),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _searchController.clear(),
            child: Text('مسح البحث', style: GoogleFonts.cairo(color: const Color(0xFF6366F1), fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildGroupCard(
    ({int priceListId, String priceListName, List<CartEntry> entries, double subtotal}) group,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EBF0)),
      ),
      child: Column(
        children: [
          // Group Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_outlined, color: Color(0xFF6366F1), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.priceListName,
                        style: GoogleFonts.cairo(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${group.entries.length} ${group.entries.length == 1 ? 'صنف' : 'أصناف'}',
                        style: GoogleFonts.cairo(color: const Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (UserSession.instance.canViewPrices)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatMoney(group.subtotal),
                        style: GoogleFonts.cairo(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text('جنيه', style: GoogleFonts.cairo(color: const Color(0xFF94A3B8), fontSize: 11)),
                    ],
                  ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _confirmClearGroup(group.priceListId, group.priceListName),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 16),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8EBF0)),
          // Items
          ...group.entries.asMap().entries.map((e) => _buildItemRow(e.value, e.key == group.entries.length - 1, group.priceListId)),
        ],
      ),
    ).animate().fadeIn(delay: (index * 80).ms, duration: 350.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildItemRow(CartEntry entry, bool isLast, int priceListId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF1F3F6))),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${entry.item.quantity}',
                  style: GoogleFonts.cairo(color: const Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text('قطعة', style: GoogleFonts.cairo(color: const Color(0xFF94A3B8), fontSize: 8)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.item.nameAr,
                  style: GoogleFonts.cairo(color: const Color(0xFF1E293B), fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '#${entry.item.itemCode}',
                  style: GoogleFonts.cairo(color: const Color(0xFFB0B8C4), fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (UserSession.instance.canViewPrices)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${formatMoney(entry.item.price * entry.item.quantity)} ج.م',
                  style: GoogleFonts.cairo(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '${formatMoney(entry.item.price)} × ${entry.item.quantity}',
                  style: GoogleFonts.cairo(color: const Color(0xFFB0B8C4), fontSize: 10),
                ),
              ],
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              _cart.removeItem(priceListId, entry.item.id);
            },
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EBF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: Color(0xFF64748B), size: 20),
              const SizedBox(width: 8),
              Text('ملاحظات على الطلبات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            maxLines: 3,
            style: GoogleFonts.cairo(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'أضف ملاحظاتك هنا... (اختياري)',
              hintStyle: GoogleFonts.cairo(color: const Color(0xFFB0B8C4), fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6366F1)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutBar(int groupCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE8EBF0))),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildSummaryChip('الكشوفات', '$groupCount', Icons.description_outlined),
              const SizedBox(width: 8),
              _buildSummaryChip('الأصناف', '${_cart.totalItemCount}', Icons.inventory_2_outlined),
              if (UserSession.instance.canViewPrices) ...[
                const SizedBox(width: 8),
                _buildSummaryChip('الإجمالي', '${formatMoney(_cart.grandTotal)} ج', Icons.account_balance_wallet_outlined),
              ],
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isSendingOrders ? null : () => _confirmPlaceOrders(groupCount),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    UserSession.instance.canViewPrices 
                      ? 'إرسال $groupCount ${groupCount == 1 ? 'طلب' : 'طلبات'} ← ${formatMoney(_cart.grandTotal)} ج.م'
                      : 'إرسال $groupCount ${groupCount == 1 ? 'طلب' : 'طلبات'}',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF64748B), size: 14),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: GoogleFonts.cairo(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(label, style: GoogleFonts.cairo(color: const Color(0xFF94A3B8), fontSize: 9)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_cart_outlined, size: 56, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 20),
          Text(
            'السلة فارغة',
            style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
          ),
          const SizedBox(height: 8),
          Text(
            'اختر منتجات من الكشوفات لإضافتها',
            style: GoogleFonts.cairo(fontSize: 14, color: const Color(0xFF94A3B8)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'تصفح الكشوفات',
                style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
    );
  }

  void _confirmPlaceOrders(int count) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Color(0xFF6366F1), size: 32),
              ),
              const SizedBox(height: 14),
              Text(
                'تأكيد الإرسال',
                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              Text(
                UserSession.instance.canViewPrices
                  ? 'سيتم إرسال $count ${count == 1 ? 'طلب' : 'طلبات'} بإجمالي ${formatMoney(_cart.grandTotal)} ج.م'
                  : 'سيتم إرسال $count ${count == 1 ? 'طلب' : 'طلبات'}',
                style: GoogleFonts.cairo(color: const Color(0xFF94A3B8), fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('إلغاء', style: GoogleFonts.cairo(color: const Color(0xFF64748B), fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _placeAllOrders();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('تأكيد وإرسال', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('تأكيد المسح', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          content: Text('هل تريد مسح جميع المنتجات من السلة؟', style: GoogleFonts.cairo()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo())),
            ElevatedButton(
              onPressed: () {
                _cart.clearAll();
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: Text('مسح الكل', style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearGroup(int priceListId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('حذف كشف', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          content: Text('حذف جميع منتجات كشف "$name"؟', style: GoogleFonts.cairo()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo())),
            ElevatedButton(
              onPressed: () {
                _cart.clearGroup(priceListId);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: Text('حذف', style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
