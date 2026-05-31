/// Mock data service for Admin Dashboard
/// Replace these methods with real API calls when backend endpoints are finalized.
class AdminMockService {
  // ─── Collection Representatives ───────────────────────────────────────

  static List<Map<String, dynamic>> getCollectionRepresentatives({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return [
      {
        'id': 1,
        'name': 'أحمد محمد السيد',
        'code': 'REP-001',
        'totalCollected': 45200.0,
        'transactionCount': 18,
      },
      {
        'id': 2,
        'name': 'محمود عبد الرحمن',
        'code': 'REP-002',
        'totalCollected': 32750.0,
        'transactionCount': 12,
      },
      {
        'id': 3,
        'name': 'خالد حسن إبراهيم',
        'code': 'REP-003',
        'totalCollected': 58900.0,
        'transactionCount': 24,
      },
      {
        'id': 4,
        'name': 'يوسف محمد علي',
        'code': 'REP-004',
        'totalCollected': 21300.0,
        'transactionCount': 9,
      },
      {
        'id': 5,
        'name': 'عمر أحمد عبد الله',
        'code': 'REP-005',
        'totalCollected': 67800.0,
        'transactionCount': 31,
      },
    ];
  }

  static List<Map<String, dynamic>> getCollectionTransactions({
    required int repId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final now = DateTime.now();
    return [
      {
        'id': 1001,
        'date': now.subtract(const Duration(days: 1)).toIso8601String(),
        'amount': 3500.0,
        'customerName': 'شركة الأمل للتجارة',
        'status': 'مكتمل',
      },
      {
        'id': 1002,
        'date': now.subtract(const Duration(days: 2)).toIso8601String(),
        'amount': 7200.0,
        'customerName': 'مؤسسة النور',
        'status': 'مكتمل',
      },
      {
        'id': 1003,
        'date': now.subtract(const Duration(days: 2)).toIso8601String(),
        'amount': 1500.0,
        'customerName': 'محلات السلام',
        'status': 'معلق',
      },
      {
        'id': 1004,
        'date': now.subtract(const Duration(days: 3)).toIso8601String(),
        'amount': 4800.0,
        'customerName': 'ورشة الخليج',
        'status': 'مكتمل',
      },
      {
        'id': 1005,
        'date': now.subtract(const Duration(days: 3)).toIso8601String(),
        'amount': 2300.0,
        'customerName': 'تجارة الصفا',
        'status': 'ملغي',
      },
      {
        'id': 1006,
        'date': now.subtract(const Duration(days: 4)).toIso8601String(),
        'amount': 9100.0,
        'customerName': 'مركز قطع الغيار',
        'status': 'مكتمل',
      },
      {
        'id': 1007,
        'date': now.subtract(const Duration(days: 5)).toIso8601String(),
        'amount': 5600.0,
        'customerName': 'شركة المحرك الذهبي',
        'status': 'مكتمل',
      },
      {
        'id': 1008,
        'date': now.toIso8601String(),
        'amount': 3200.0,
        'customerName': 'مؤسسة الفارس',
        'status': 'معلق',
      },
    ];
  }

  // ─── Return Representatives ───────────────────────────────────────────

  static List<Map<String, dynamic>> getReturnRepresentatives({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return [
      {'id': 1, 'name': 'أحمد محمد السيد', 'code': 'REP-001', 'returnCount': 5},
      {
        'id': 2,
        'name': 'محمود عبد الرحمن',
        'code': 'REP-002',
        'returnCount': 3,
      },
      {
        'id': 3,
        'name': 'خالد حسن إبراهيم',
        'code': 'REP-003',
        'returnCount': 8,
      },
      {'id': 4, 'name': 'يوسف محمد علي', 'code': 'REP-004', 'returnCount': 2},
      {
        'id': 5,
        'name': 'عمر أحمد عبد الله',
        'code': 'REP-005',
        'returnCount': 6,
      },
    ];
  }

  static List<Map<String, dynamic>> getReturnInvoices({
    required int repId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final now = DateTime.now();
    return [
      {
        'invoiceNo': 'INV-2024-0451',
        'customerName': 'شركة الأمل للتجارة',
        'date': now.subtract(const Duration(days: 1)).toIso8601String(),
        'totalAmount': 12500.0,
        'returnAmount': 3200.0,
      },
      {
        'invoiceNo': 'INV-2024-0389',
        'customerName': 'مؤسسة النور',
        'date': now.subtract(const Duration(days: 2)).toIso8601String(),
        'totalAmount': 8700.0,
        'returnAmount': 1500.0,
      },
      {
        'invoiceNo': 'INV-2024-0412',
        'customerName': 'محلات السلام',
        'date': now.subtract(const Duration(days: 3)).toIso8601String(),
        'totalAmount': 5400.0,
        'returnAmount': 5400.0,
      },
      {
        'invoiceNo': 'INV-2024-0378',
        'customerName': 'ورشة الخليج',
        'date': now.subtract(const Duration(days: 4)).toIso8601String(),
        'totalAmount': 22000.0,
        'returnAmount': 7800.0,
      },
      {
        'invoiceNo': 'INV-2024-0501',
        'customerName': 'تجارة الصفا',
        'date': now.subtract(const Duration(days: 5)).toIso8601String(),
        'totalAmount': 3200.0,
        'returnAmount': 900.0,
      },
    ];
  }

  static Map<String, dynamic> getInvoiceDetail({required String invoiceNo}) {
    return {
      'invoiceNo': invoiceNo,
      'customerName': 'شركة الأمل للتجارة',
      'date': DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String(),
      'totalAmount': 12500.0,
      'returnAmount': 3200.0,
      'items': [
        {
          'productName': 'فلتر زيت تويوتا كامري',
          'productCode': 'FLT-TOY-001',
          'direction': 'وارد',
          'unitPrice': 450.0,
          'returnQty': 2,
        },
        {
          'productName': 'كشاف أمامي هيونداي أكسنت',
          'productCode': 'HLD-HYN-012',
          'direction': 'وارد',
          'unitPrice': 1200.0,
          'returnQty': 1,
        },
        {
          'productName': 'تيل فرامل نيسان صني',
          'productCode': 'BRK-NIS-005',
          'direction': 'وارد',
          'unitPrice': 350.0,
          'returnQty': 3,
        },
        {
          'productName': 'رديتر مياه كيا سيراتو',
          'productCode': 'RAD-KIA-008',
          'direction': 'صادر',
          'unitPrice': 850.0,
          'returnQty': 1,
        },
      ],
    };
  }

  // ─── Delivery Representatives ─────────────────────────────────────────

  static List<Map<String, dynamic>> getDeliveryRepresentatives({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return [
      {
        'id': 1,
        'name': 'أحمد محمد السيد',
        'code': 'REP-001',
        'deliveryCount': 10,
      },
      {
        'id': 2,
        'name': 'محمود عبد الرحمن',
        'code': 'REP-002',
        'deliveryCount': 7,
      },
      {
        'id': 3,
        'name': 'خالد حسن إبراهيم',
        'code': 'REP-003',
        'deliveryCount': 15,
      },
      {'id': 4, 'name': 'يوسف محمد علي', 'code': 'REP-004', 'deliveryCount': 4},
      {
        'id': 5,
        'name': 'عمر أحمد عبد الله',
        'code': 'REP-005',
        'deliveryCount': 12,
      },
    ];
  }

  static List<Map<String, dynamic>> getDeliveryInvoices({
    required int repId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final now = DateTime.now();
    return [
      {
        'invoiceNo': 'DEL-2024-101',
        'customerName': 'شركة الأمل للتجارة',
        'date': now.toIso8601String(),
        'amount': 8500.0,
        'statusCode': 4,
        'address': 'المنطقة الصناعية - الرياض',
      },
      {
        'invoiceNo': 'DEL-2024-102',
        'customerName': 'مؤسسة النور',
        'date': now.toIso8601String(),
        'amount': 3200.0,
        'statusCode': 3,
        'address': 'شارع الملك فهد - جدة',
      },
      {
        'invoiceNo': 'DEL-2024-103',
        'customerName': 'محلات السلام',
        'date': now.toIso8601String(),
        'amount': 1500.0,
        'statusCode': 2,
        'address': 'حي النزهة - الدمام',
      },
      {
        'invoiceNo': 'DEL-2024-104',
        'customerName': 'ورشة الخليج للسيارات',
        'date': now.toIso8601String(),
        'amount': 12400.0,
        'statusCode': 1,
        'address': 'طريق الثمامة - الرياض',
      },
      {
        'invoiceNo': 'DEL-2024-105',
        'customerName': 'تجارة الصفا',
        'date': now.toIso8601String(),
        'amount': 6700.0,
        'statusCode': 0,
        'address': 'شارع فلسطين - جدة',
      },
      {
        'invoiceNo': 'DEL-2024-106',
        'customerName': 'مركز قطع الغيار المتحدة',
        'date': now.toIso8601String(),
        'amount': 4300.0,
        'statusCode': 2,
        'address': 'حي الروضة - الرياض',
      },
      {
        'invoiceNo': 'DEL-2024-107',
        'customerName': 'مؤسسة الفارس',
        'date': now.toIso8601String(),
        'amount': 9800.0,
        'statusCode': 4,
        'address': 'شارع الأمير سلطان - جدة',
      },
      {
        'invoiceNo': 'DEL-2024-108',
        'customerName': 'شركة المحرك الذهبي',
        'date': now.toIso8601String(),
        'amount': 2200.0,
        'statusCode': 0,
        'address': 'حي العليا - الرياض',
      },
      {
        'invoiceNo': 'DEL-2024-109',
        'customerName': 'محلات الأصيل',
        'date': now.toIso8601String(),
        'amount': 5100.0,
        'statusCode': 3,
        'address': 'طريق الملك عبدالعزيز - المدينة',
      },
      {
        'invoiceNo': 'DEL-2024-110',
        'customerName': 'ورشة الإتقان',
        'date': now.toIso8601String(),
        'amount': 7600.0,
        'statusCode': 1,
        'address': 'حي المروج - الرياض',
      },
    ];
  }

  static String getDeliveryStatusText(int statusCode) {
    switch (statusCode) {
      case 0:
        return 'قيد التجهيز';
      case 1:
        return 'استلم الفاتورة';
      case 2:
        return 'فى الطريق الى العميل';
      case 3:
        return 'تم الوصول الى العميل';
      case 4:
        return 'تم الاستلام من قبل العميل';
      default:
        return 'غير معروف';
    }
  }
}
