import 'package:flutter/material.dart';
import '../models/price_list_model.dart';

/// Represents a single cart entry linked to a specific price list (كشف)
class CartEntry {
  final int priceListId;
  final String priceListName;
  final PriceListItemModel item;

  CartEntry({
    required this.priceListId,
    required this.priceListName,
    required this.item,
  });
}

/// Global Cart — groups items by their source price list
class CartProvider extends ChangeNotifier {
  CartProvider._internal();
  static final CartProvider instance = CartProvider._internal();

  // priceListId → {itemId → CartEntry}
  final Map<int, Map<int, CartEntry>> _cart = {};
  // priceListId → priceListName
  final Map<int, String> _priceListNames = {};

  // ─────────────── Read ───────────────

  bool get isEmpty => _cart.isEmpty || _cart.values.every((m) => m.isEmpty);

  int get totalItemCount {
    int count = 0;
    for (final group in _cart.values) {
      count += group.length;
    }
    return count;
  }

  int get totalUnitCount {
    int count = 0;
    for (final group in _cart.values) {
      for (final entry in group.values) {
        count += entry.item.quantity;
      }
    }
    return count;
  }

  double get grandTotal {
    double total = 0;
    for (final group in _cart.values) {
      for (final entry in group.values) {
        total += entry.item.price * entry.item.quantity;
      }
    }
    return total;
  }

  /// Returns groups: each group is a list of CartEntries for one price list
  List<({int priceListId, String priceListName, List<CartEntry> entries, double subtotal})> get groups {
    final result = <({int priceListId, String priceListName, List<CartEntry> entries, double subtotal})>[];
    for (final entry in _cart.entries) {
      if (entry.value.isEmpty) continue;
      final entries = entry.value.values.toList();
      final subtotal = entries.fold(
        0.0,
        (sum, e) => sum + e.item.price * e.item.quantity,
      );
      result.add((
        priceListId: entry.key,
        priceListName: _priceListNames[entry.key] ?? 'كشف #${entry.key}',
        entries: entries,
        subtotal: subtotal,
      ));
    }
    return result;
  }

  int getQuantity(int priceListId, int itemId) {
    return _cart[priceListId]?[itemId]?.item.quantity ?? 0;
  }

  // ─────────────── Write ───────────────

  void addOrUpdate(int priceListId, String priceListName, PriceListItemModel item) {
    _priceListNames[priceListId] = priceListName;
    _cart.putIfAbsent(priceListId, () => {});
    if (item.quantity <= 0) {
      _cart[priceListId]!.remove(item.id);
    } else {
      _cart[priceListId]![item.id] = CartEntry(
        priceListId: priceListId,
        priceListName: priceListName,
        item: item,
      );
    }
    // cleanup empty groups
    _cart.removeWhere((_, v) => v.isEmpty);
    notifyListeners();
  }

  void removeItem(int priceListId, int itemId) {
    _cart[priceListId]?.remove(itemId);
    _cart.removeWhere((_, v) => v.isEmpty);
    notifyListeners();
  }

  void clearGroup(int priceListId) {
    _cart.remove(priceListId);
    notifyListeners();
  }

  void clearAll() {
    _cart.clear();
    notifyListeners();
  }

  /// Returns all entries for a specific priceList (to sync back to UI)
  Map<int, int> getQuantitiesForList(int priceListId) {
    final group = _cart[priceListId];
    if (group == null) return {};
    return group.map((itemId, entry) => MapEntry(itemId, entry.item.quantity));
  }
}
