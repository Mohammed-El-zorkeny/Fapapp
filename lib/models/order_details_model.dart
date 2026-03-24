class OrderDetailsModel {
  final OrderInfo orderInfo;
  final List<OrderItem> selectedItems;
  final List<AvailableItem> availableItems;

  OrderDetailsModel({
    required this.orderInfo,
    required this.selectedItems,
    required this.availableItems,
  });

  factory OrderDetailsModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailsModel(
      orderInfo: OrderInfo.fromJson(json['orderInfo'] ?? {}),
      selectedItems:
          (json['selectedItems'] as List?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      availableItems:
          (json['availableItems'] as List?)
              ?.map((item) => AvailableItem.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class OrderInfo {
  final int orderId;
  final String autoNumberBra;
  final int priceListId;
  final String invDate;
  final String statusCode;
  final String statusAr;
  final String? notes;
  final String? urlpdf;
  double orderTotal;

  OrderInfo({
    required this.orderId,
    required this.autoNumberBra,
    required this.priceListId,
    required this.invDate,
    required this.statusCode,
    required this.statusAr,
    this.notes,
    this.urlpdf,
    required this.orderTotal,
  });

  factory OrderInfo.fromJson(Map<String, dynamic> json) {
    return OrderInfo(
      orderId: _parseInt(json['orderId']),
      autoNumberBra: json['autoNumberBra'] ?? '',
      priceListId: _parseInt(json['priceListId']),
      invDate: json['invDate'] ?? '',
      statusCode: json['statusCode'] ?? '',
      statusAr: json['statusAr'] ?? '',
      notes: json['notes'],
      urlpdf: json['urlpdf'],
      orderTotal: _parseDouble(json['orderTotal']),
    );
  }
}

class OrderItem {
  final int? dtlId;
  final int itemId;
  final String itemCode;
  final String nameAr;
  final String nameEn;
  final String? itemSide;
  int qty;
  final int? qtyPlan;
  final double price;
  double totalValue;
  final String? notes;

  OrderItem({
    this.dtlId,
    required this.itemId,
    required this.itemCode,
    required this.nameAr,
    required this.nameEn,
    this.itemSide,
    required this.qty,
    this.qtyPlan,
    required this.price,
    required this.totalValue,
    this.notes,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      dtlId: json['dtlId'] != null ? _parseInt(json['dtlId']) : null,
      itemId: _parseInt(json['itemId']),
      itemCode: json['itemCode'] ?? '',
      nameAr: json['nameAr'] ?? '',
      nameEn: json['nameEn'] ?? '',
      itemSide: json['itemSide'],
      qty: _parseInt(json['qty']),
      qtyPlan: json['qtyPlan'] != null ? _parseInt(json['qtyPlan']) : null,
      price: _parseDouble(json['price']),
      totalValue: _parseDouble(json['totalValue']),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dtlId': dtlId,
      'itemId': itemId,
      'itemCode': itemCode,
      'qty': qty,
      'price': price,
      'totalValue': totalValue,
    };
  }
}

class AvailableItem {
  final int priceDtlId;
  final int itemId;
  final String itemCode;
  final String nameAr;
  final String nameEn;
  final String? itemSide;
  final double price;
  final int minQty;
  int tempQty;

  AvailableItem({
    required this.priceDtlId,
    required this.itemId,
    required this.itemCode,
    required this.nameAr,
    required this.nameEn,
    this.itemSide,
    required this.price,
    required this.minQty,
    this.tempQty = 1,
  });

  factory AvailableItem.fromJson(Map<String, dynamic> json) {
    return AvailableItem(
      priceDtlId: _parseInt(json['priceDtlId']),
      itemId: _parseInt(json['itemId']),
      itemCode: json['itemCode'] ?? '',
      nameAr: json['nameAr'] ?? '',
      nameEn: json['nameEn'] ?? '',
      itemSide: json['itemSide'],
      price: _parseDouble(json['price']),
      minQty: _parseInt(json['minQty'] ?? 0),
      tempQty: 1,
    );
  }
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  if (value is double) return value.toInt();
  return 0;
}

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
