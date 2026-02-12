class PriceListModel {
  final int id;
  final String autoNumber;
  final String nameAr;
  final String nameEn;
  final String messageAr;
  final String priceListUrlPdf;
  final String status;
  final String startDate;
  final String endDate;

  PriceListModel({
    required this.id,
    required this.autoNumber,
    required this.nameAr,
    required this.nameEn,
    required this.messageAr,
    required this.priceListUrlPdf,
    required this.status,
    required this.startDate,
    required this.endDate,
  });

  factory PriceListModel.fromJson(Map<String, dynamic> json) {
    return PriceListModel(
      id: json['id'] ?? 0,
      autoNumber: json['autoNumber'] ?? '',
      nameAr: json['nameAr'] ?? '',
      nameEn: json['nameEn'] ?? '',
      messageAr: json['messageAr'] ?? '',
      priceListUrlPdf: json['priceListUrlPdf'] ?? '',
      status: json['status'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
    );
  }
}

class PriceListItemModel {
  final int id;
  final String itemCode;
  final String nameAr;
  final String itemSide; // New field
  final double price;
  final int minQty;
  int quantity;

  PriceListItemModel({
    required this.id,
    required this.itemCode,
    required this.nameAr,
    required this.itemSide, // New field
    required this.price,
    required this.minQty,
    this.quantity = 0,
  });

  factory PriceListItemModel.fromJson(Map<String, dynamic> json) {
    return PriceListItemModel(
      id: json['id'] ?? 0,
      itemCode: json['itemCode'] ?? '',
      nameAr: json['nameAr'] ?? '',
      itemSide: json['itemSide'] ?? '', // Default to empty if missing
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      minQty: json['minQty'] ?? 0,
    );
  }
}
