import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'storage_service.dart';

class ApiService {
  static const String baseUrl = 'https://fapautoapps.com/ords/app';
  final StorageService _storageService = StorageService();

  // Helper method for headers
  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  // API 1: Login (Request OTP)
  Future<Map<String, dynamic>> requestOtp(String phoneNumber) async {
    final url = Uri.parse('$baseUrl/auth/requestOtp');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: json.encode({'phoneNumber': phoneNumber}),
      );

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'message': data['messageAr'], 'data': data};
      } else {
        return {
          'success': false,
          'message': data['messageAr'] ?? 'حدث خطأ غير متوقع',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'تعذر الاتصال بالخادم. تأكد من اتصالك بالإنترنت.',
      };
    }
  }

  // API 2: Verify OTP
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    final url = Uri.parse('$baseUrl/auth/verifyOtp');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: json.encode({'phoneNumber': phoneNumber, 'otp': otp}),
      );

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && data['status'] == 'success') {
        // Save Token and User Data
        if (data['token'] != null) {
          await _storageService.saveToken(data['token']);
        }
        await _storageService.saveUserData(data);

        return {'success': true, 'message': data['messageAr'], 'data': data};
      } else {
        return {
          'success': false,
          'message': data['messageAr'] ?? 'الكود غير صحيح',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'تعذر الاتصال بالخادم. تأكد من اتصالك بالإنترنت.',
      };
    }
  }

  Future<Map<String, String>> get _authHeaders async {
    final token = await _storageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ""}',
    };
  }

  // API 3: Get Price Lists
  Future<Map<String, dynamic>> getPriceLists() async {
    final url = Uri.parse('$baseUrl/priceList/myPriceList');
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'data': data['priceLists']};
      } else if (response.statusCode == 401) {
        return {'success': false, 'authError': true};
      } else {
        return {'success': false, 'message': 'فشل في تحميل الكشوفات'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال'};
    }
  }

  // API 4: Get Price List Items with Group Filter
  Future<Map<String, dynamic>> getPriceListItems(
    int id, {
    String? groupIds,
  }) async {
    String urlStr = '$baseUrl/priceList/itemsPriceList?priceListId=$id';
    if (groupIds != null && groupIds.isNotEmpty) {
      urlStr += '&groupIds=$groupIds';
    }
    final url = Uri.parse(urlStr);
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'data': data};
      } else if (response.statusCode == 401) {
        return {'success': false, 'authError': true};
      } else {
        return {'success': false, 'message': 'فشل في تحميل التفاصيل'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال'};
    }
  }

  // API 11: Get Stock Groups
  Future<Map<String, dynamic>> getStockGroups() async {
    final url = Uri.parse('$baseUrl/Items/getlistGroup');
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'data': data['stockGroups'] ?? []};
      } else if (response.statusCode == 401) {
        return {'success': false, 'authError': true};
      } else {
        return {
          'success': false,
          'message': data['messageAr'] ?? 'فشل في تحميل المجموعات',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال'};
    }
  }

  // API 5: Get Customers List
  Future<Map<String, dynamic>> getCustomers() async {
    final url = Uri.parse('$baseUrl/Customers/List');
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        final customersData = data['customers'];
        if (customersData is List) {
          return {'success': true, 'data': customersData};
        } else if (data is List) {
          return {'success': true, 'data': data};
        }
        return {'success': true, 'data': []};
      } else if (response.statusCode == 401) {
        return {'success': false, 'authError': true};
      } else {
        return {
          'success': false,
          'message': data['messageAr'] ?? 'فشل في تحميل قائمة العملاء',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // API 6: Get Banks List
  Future<Map<String, dynamic>> getBanks() async {
    final url = Uri.parse('$baseUrl/Bank/List');
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        final banksData = data['banks'];
        if (banksData is List) {
          return {'success': true, 'data': banksData};
        }
        return {'success': true, 'data': []};
      } else if (response.statusCode == 401) {
        return {'success': false, 'authError': true};
      } else {
        return {
          'success': false,
          'message': data['messageAr'] ?? 'فشل في تحميل قائمة البنوك',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // API 7: Get Invoices by Customer
  Future<Map<String, dynamic>> getInvoicesByCustomer(int customerId) async {
    final url = Uri.parse(
      '$baseUrl/salesinvoice/getinvoicebycust?customersId=$customerId',
    );
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);
      final body = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        try {
          final data = json.decode(body);
          return {'success': true, 'data': data['invoices'] ?? []};
        } catch (e) {
          debugPrint('JSON Decode Error (getInvoicesByCustomer): $e');
          debugPrint('Response Body: $body');
          return {
            'success': false,
            'message': 'خطأ في معالجة البيانات من السيرفر',
          };
        }
      } else {
        debugPrint('API Error (getInvoicesByCustomer): ${response.statusCode}');
        debugPrint('Body: $body');
        try {
          final data = json.decode(body);
          return {
            'success': false,
            'message': data['messageAr'] ?? 'فشل في تحميل الفواتير',
          };
        } catch (_) {
          return {
            'success': false,
            'message': 'فشل في تحميل الفواتير (${response.statusCode})',
          };
        }
      }
    } catch (e) {
      debugPrint('Connection Error (getInvoicesByCustomer): $e');
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // API 7b: Get All Sales Invoices (without customer filter)
  Future<Map<String, dynamic>> getAllSalesInvoices() async {
    final url = Uri.parse('$baseUrl/salesinvoice/getinvoicebycust');
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);
      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode == 200) {
        try {
          final data = json.decode(body);
          return {'success': true, 'data': data['invoices'] ?? []};
        } catch (e) {
          return {'success': false, 'message': 'خطأ في معالجة البيانات'};
        }
      } else {
        try {
          final data = json.decode(body);
          return {'success': false, 'message': data['messageAr'] ?? 'فشل في تحميل الفواتير'};
        } catch (_) {
          return {'success': false, 'message': 'فشل في تحميل الفواتير (${response.statusCode})'};
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // API 7c: Get Invoice by AutoNumber (from QR scan)
  Future<Map<String, dynamic>> getInvoiceByAutoNumber(String autoNumber) async {
    final url = Uri.parse(
      '$baseUrl/salesinvoice/GetInvoiceByAutoNumber?autoNumber=${Uri.encodeComponent(autoNumber)}',
    );
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);
      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode == 200) {
        try {
          final data = json.decode(body);
          final invoices = data['invoices'] as List?;
          if (invoices != null && invoices.isNotEmpty) {
            return {'success': true, 'data': Map<String, dynamic>.from(invoices.first)};
          }
          return {'success': false, 'message': 'لم يتم العثور على الفاتورة'};
        } catch (e) {
          return {'success': false, 'message': 'خطأ في معالجة البيانات'};
        }
      } else {
        try {
          final data = json.decode(body);
          return {'success': false, 'message': data['messageAr'] ?? 'فشل في جلب الفاتورة'};
        } catch (_) {
          return {'success': false, 'message': 'فشل في جلب الفاتورة (${response.statusCode})'};
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // API 8: Get Invoice Items for Return by ID
  Future<Map<String, dynamic>> getInvoiceItemsById(int invoiceId) async {
    final url = Uri.parse(
      '$baseUrl/salesinvoice/getitemsbyinvoice?invoiceId=$invoiceId',
    );
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);
      final body = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        try {
          final data = json.decode(body);
          return {'success': true, 'data': data['invoice']?['items'] ?? []};
        } catch (e) {
          debugPrint('JSON Decode Error (getInvoiceItemsById): $e');
          debugPrint('Response Body: $body');
          return {'success': false, 'message': 'خطأ في معالجة بيانات الفاتورة'};
        }
      } else {
        debugPrint('API Error (getInvoiceItemsById): ${response.statusCode}');
        debugPrint('Body: $body');
        try {
          final data = json.decode(body);
          return {
            'success': false,
            'message': data['messageAr'] ?? 'فشل في تحميل بيانات الفاتورة',
          };
        } catch (_) {
          return {
            'success': false,
            'message': 'فشل في تحميل بيانات الفاتورة (${response.statusCode})',
          };
        }
      }
    } catch (e) {
      debugPrint('Connection Error (getInvoiceItemsById): $e');
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // API 9: Submit Return
  Future<Map<String, dynamic>> submitReturn({
    required String customerId,
    required String invoiceNo,
    required List<Map<String, dynamic>> items,
  }) async {
    final url = Uri.parse('$baseUrl/Returns/Submit');
    try {
      final headers = await _authHeaders;
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          'customerId': customerId,
          'invoiceNo': invoiceNo,
          'items': items,
        }),
      );

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'message': data['messageAr']};
      } else {
        return {
          'success': false,
          'message': data['messageAr'] ?? 'فشل في إرسال المرتجع',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // API 10: Get Customer Statement
  Future<Map<String, dynamic>> getCustomerStatement({
    required int customerId,
    required String startDate,
    required String endDate,
    int page = 1,
  }) async {
    final url = Uri.parse(
      '$baseUrl/Customers/Statement?customerId=$customerId&startDate=$startDate&endDate=$endDate&page=$page',
    );
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);
      final body = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final data = json.decode(body);
        if (data['status'] == 'success') {
          return {
            'success': true,
            'data': data['statement'] ?? [],
            'total': data['total'] ?? 0,
          };
        }
        return {
          'success': false,
          'message': data['messageAr'] ?? 'فشل جلب البيانات',
        };
      } else {
        return {
          'success': false,
          'message': 'خطأ في السيرفر (${response.statusCode})',
        };
      }
    } catch (e) {
      debugPrint('Connection Error (getCustomerStatement): $e');
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // API 12: Create Request Invoice (New Order)
  Future<Map<String, dynamic>> createRequestInvoice({
    required int priceListId,
    required String notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final url = Uri.parse('$baseUrl/Transactions/CreateRequestInvoice');
    try {
      final headers = await _authHeaders;
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          'priceListId': priceListId,
          'notes': notes,
          'items': items,
        }),
      );

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'message': data['messageAr'] ?? 'تم إنشاء الطلب بنجاح',
          'order': data['order'],
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'authError': true};
      } else {
        return {
          'success': false,
          'message':
              data['messageAr'] ?? data['message'] ?? 'فشل في إنشاء الطلب',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // API 13: Create Payment
  Future<Map<String, dynamic>> createPayment({
    required int bankId,
    required int customerId,
    required int invoiceId,
    required double value,
    required String? notes,
    required String? imageBase64,
    required String? imageName,
  }) async {
    final url = Uri.parse('$baseUrl/Payment/CreatePayment');
    try {
      final headers = await _authHeaders;
      final userData = await _storageService.getUserData();
      final salesmanId =
          int.tryParse(userData?['userId']?.toString() ?? '0') ?? 0;
      final requestBody = {
        'bankId': bankId,
        'customerId': customerId,
        'invoiceId': invoiceId,
        'salesmanId': salesmanId,
        'value': value,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (imageBase64 != null) 'imageBase64': imageBase64,
        if (imageName != null) 'imageName': imageName,
      };
      debugPrint('===== createPayment REQUEST =====');
      debugPrint('URL: $url');
      debugPrint('BODY: ${json.encode(requestBody)}');
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(requestBody),
      );

      final responseBody = utf8.decode(response.bodyBytes);
      debugPrint('===== createPayment RESPONSE =====');
      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('BODY: $responseBody');
      final data = json.decode(responseBody);

      if (response.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'message': data['messageAr'] ?? 'تم إنشاء سند القبض بنجاح',
          'payment': data['payment'],
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'authError': true};
      } else {
        return {
          'success': false,
          'message': data['messageAr'] ?? 'فشل في إنشاء التحصيل',
        };
      }
    } catch (e) {
      debugPrint('===== createPayment ERROR =====');
      debugPrint('$e');
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // API: Create Return Invoice
  Future<Map<String, dynamic>> createReturnInvoice({
    required int invoiceSalesId,
    required int salesmanId,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final url = Uri.parse('$baseUrl/ReturnInvoice/CreateInvoice');
    try {
      final headers = await _authHeaders;
      final body = {
        'invoiceSalesId': invoiceSalesId,
        'salesmanId': salesmanId,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'items': items,
      };
      debugPrint('===== createReturnInvoice REQUEST =====');
      debugPrint('URL: $url');
      debugPrint('BODY: ${json.encode(body)}');
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );

      final responseBody = utf8.decode(response.bodyBytes);
      debugPrint('===== createReturnInvoice RESPONSE =====');
      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('BODY: $responseBody');
      final data = json.decode(responseBody);

      if (response.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'message': data['messageAr'] ?? 'تم إنشاء فاتورة المرتجع بنجاح',
          'return': data['return'],
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'authError': true, 'message': 'انتهت صلاحية الجلسة'};
      } else {
        return {
          'success': false,
          'message': data['messageAr'] ?? data['message'] ?? 'فشل في إنشاء فاتورة المرتجع',
        };
      }
    } catch (e) {
      debugPrint('===== createReturnInvoice ERROR =====');
      debugPrint('$e');
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // API: Get My Payments
  Future<Map<String, dynamic>> getMyPayments() async {
    final url = Uri.parse('$baseUrl/Payment/GetAllMyPayment');
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);
      final data = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'data': List<Map<String, dynamic>>.from(
              (data['payments'] as List).map((e) => Map<String, dynamic>.from(e))),
          'total': data['total'] ?? 0,
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'authError': true, 'message': 'انتهت صلاحية الجلسة'};
      } else {
        return {
          'success': false,
          'message': data['messageAr'] ?? 'فشل في جلب التحصيلات',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // API: Get All Items for a Return Invoice (sold + returned breakdown)
  Future<Map<String, dynamic>> getReturnInvoiceItems({
    required int invoiceId,
    required int returnId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/ReturnInvoice/GetItemsAllInvoiceById?invoiceId=$invoiceId&returnId=$returnId',
    );
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);
      final data = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'data': List<Map<String, dynamic>>.from(
              (data['items'] as List).map((e) => Map<String, dynamic>.from(e))),
          'total': data['total'] ?? 0,
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'authError': true, 'message': 'انتهت صلاحية الجلسة'};
      } else {
        return {
          'success': false,
          'message': data['messageAr'] ?? 'فشل في جلب تفاصيل المرتجع',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // API: Get My Return Invoices
  Future<Map<String, dynamic>> getMyReturnInvoices() async {
    final url = Uri.parse('$baseUrl/ReturnInvoice/GetMyInvoice');
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);
      final data = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'data': List<Map<String, dynamic>>.from(
              (data['returns'] as List).map((e) => Map<String, dynamic>.from(e))),
          'total': data['total'] ?? 0,
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'authError': true, 'message': 'انتهت صلاحية الجلسة'};
      } else {
        return {
          'success': false,
          'message': data['messageAr'] ?? 'فشل في جلب المرتجعات',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // File Download with Progress
  // File Download with Progress & Auth
  Future<String?> downloadFile(
    String url,
    String savePath, {
    Function(int, int)? onReceiveProgress,
  }) async {
    try {
      final dio = Dio();
      // Add Auth Headers
      final headers = await _authHeaders;
      dio.options.headers = headers;

      // Set Timeouts
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 60);

      await dio.download(
        url,
        savePath,
        onReceiveProgress: onReceiveProgress,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      return savePath;
    } catch (e) {
      print("Download Error: $e");
      // Rethrow to handle specific errors in UI
      throw e;
    }
  }

  // API 13: Get My Orders
  Future<Map<String, dynamic>> getMyOrders() async {
    final url = Uri.parse('$baseUrl/order/GetMyRequests');
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);
      final body = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final data = json.decode(body);
        if (data['status'] == 'success') {
          return {
            'success': true,
            'data': data['requests'] ?? [],
            'total': data['total'] ?? 0,
          };
        }
        return {
          'success': false,
          'message': data['messageAr'] ?? 'فشل جلب الطلبات',
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'authError': true};
      } else {
        return {
          'success': false,
          'message': 'خطأ في السيرفر (${response.statusCode})',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // API 14: Get Stores
  Future<Map<String, dynamic>> getStores() async {
    final url = Uri.parse('$baseUrl/Items/getStores');
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);
      final body = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final data = json.decode(body);
        if (data['status'] == 'success') {
          return {'success': true, 'data': data['stores'] ?? []};
        }
        return {
          'success': false,
          'message': data['messageAr'] ?? 'فشل جلب المخازن',
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'authError': true};
      } else {
        return {'success': false, 'message': 'خطأ في السيرفر'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // API 15: Get Sub Stores
  Future<Map<String, dynamic>> getSubStores(int storeId) async {
    final url = Uri.parse('$baseUrl/Items/getSubStores?storeId=$storeId');
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);
      final body = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final data = json.decode(body);
        if (data['status'] == 'success') {
          return {'success': true, 'data': data['subStores'] ?? []};
        }
        return {
          'success': false,
          'message': data['messageAr'] ?? 'فشل جلب المخازن الفرعية',
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'authError': true};
      } else {
        return {'success': false, 'message': 'خطأ في السيرفر'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // API 16: Get Item Card Stock
  Future<Map<String, dynamic>> getItemCardStock({
    required String itemCode,
    required int storeId,
    required int subStoreId,
    required String startDate,
    required String endDate,
  }) async {
    final url = Uri.parse(
      '$baseUrl/Items/getCarditemsstcok?itemCode=$itemCode&storeId=$storeId&subStoreId=$subStoreId&startDate=$startDate&endDate=$endDate',
    );
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);
      final body = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final data = json.decode(body);
        if (data['status'] == 'success') {
          return {
            'success': true,
            'itemInfo': data['itemInfo'],
            'transactions': data['transactions'] ?? [],
          };
        }
        return {
          'success': false,
          'message': data['messageAr'] ?? 'فشل جلب كارت الصنف',
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'authError': true};
      } else {
        return {'success': false, 'message': 'الصنف غير موجود أو خطأ بالسيرفر'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // API 17: Get Info Item
  Future<Map<String, dynamic>> getInfoItem(String itemCode) async {
    final url = Uri.parse('$baseUrl/Items/getInfoItem?itemCode=$itemCode');
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);
      final body = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final data = json.decode(body);
        if (data['status'] == 'success') {
          return {'success': true, 'item': data['item']};
        }
        return {
          'success': false,
          'message': data['messageAr'] ?? 'فشل جلب بيانات الصنف',
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'authError': true};
      } else {
        return {'success': false, 'message': 'الصنف غير موجود أو خطأ بالسيرفر'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // API 18: Get Locations
  Future<Map<String, dynamic>> getLocations({int subStoreId = 1}) async {
    final url = Uri.parse('$baseUrl/Items/getLocations?subStoreId=$subStoreId');
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);
      final body = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final data = json.decode(body);
        if (data['status'] == 'success') {
          return {'success': true, 'locations': data['locations'] ?? []};
        }
        return {
          'success': false,
          'message': data['messageAr'] ?? 'فشل جلب المواقع',
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'authError': true};
      } else {
        return {'success': false, 'message': 'خطأ في السيرفر'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // API 19: Update Locations
  Future<Map<String, dynamic>> updateLocations(
    String itemCode,
    int locationId,
  ) async {
    final url = Uri.parse('$baseUrl/Items/updateLocations');
    try {
      final headers = await _authHeaders;
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({'itemCode': itemCode, 'locationId': locationId}),
      );

      final body = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final data = json.decode(body);
        if (data['status'] == 'success') {
          return {
            'success': true,
            'message': data['messageAr'] ?? 'تم التحديث بنجاح',
            'locationName': data['locationName'],
          };
        }
        return {
          'success': false,
          'message': data['messageAr'] ?? 'فشل التحديث',
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'authError': true};
      } else {
        return {'success': false, 'message': 'خطأ في السيرفر'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // API: Get Order Details
  Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    final url = Uri.parse(
      '$baseUrl/Transactions/ViewOrderDetails?orderId=$orderId',
    );
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);
      final body = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final data = json.decode(body);
        if (data['status'] == 'success') {
          return {'success': true, 'data': data};
        }
        return {
          'success': false,
          'message': data['messageAr'] ?? 'فشل جلب تفاصيل الطلب',
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'authError': true};
      } else {
        return {'success': false, 'message': 'خطأ في السيرفر'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // API: Update Order
  Future<Map<String, dynamic>> updateOrderDetails({
    required int orderId,
    required List<Map<String, dynamic>> items,
  }) async {
    final url = Uri.parse('$baseUrl/Transactions/UpdateRequestInvoice');
    try {
      final headers = await _authHeaders;
      final response = await http.put(
        url,
        headers: headers,
        body: json.encode({'orderId': orderId, 'items': items}),
      );
      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode == 200) {
        final data = json.decode(body);
        if (data['status'] == 'success') {
          return {
            'success': true,
            'message': data['messageAr'] ?? 'تم حفظ التعديلات بنجاح',
          };
        }
        return {
          'success': false,
          'message': data['messageAr'] ?? 'فشل في حفظ التعديلات',
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'authError': true};
      } else {
        return {'success': false, 'message': 'خطأ في السيرفر'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // API: Update Order Status
  Future<Map<String, dynamic>> updateOrderStatus({
    required int orderId,
    required String status,
    String? notes,
  }) async {
    final url = Uri.parse('$baseUrl/Transactions/UpdateStatusOrder');
    try {
      final headers = await _authHeaders;
      final response = await http.put(
        url,
        headers: headers,
        body: json.encode({
          'orderId': orderId,
          'status': status,
          if (notes != null) 'notes': notes,
        }),
      );
      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode == 200) {
        final data = json.decode(body);
        if (data['status'] == 'success') {
          return {
            'success': true,
            'message': data['messageAr'] ?? 'تم تحديث حالة الطلب بنجاح',
          };
        }
        return {
          'success': false,
          'message': data['messageAr'] ?? 'فشل في تحديث حالة الطلب',
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'authError': true};
      } else {
        return {'success': false, 'message': 'خطأ في السيرفر'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // API: Update Item Notes
  Future<Map<String, dynamic>> updateItemNotes({
    required int dtlId,
    required String notes,
  }) async {
    final url = Uri.parse('$baseUrl/Transactions/UpdateNotesByDtlid');
    try {
      final headers = await _authHeaders;
      final response = await http.put(
        url,
        headers: headers,
        body: json.encode({'dtlId': dtlId, 'notes': notes}),
      );
      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode == 200) {
        final data = json.decode(body);
        if (data['status'] == 'success') {
          return {
            'success': true,
            'message': data['messageAr'] ?? 'تم تحديث الملاحظات بنجاح',
          };
        }
        return {
          'success': false,
          'message': data['messageAr'] ?? 'فشل في تحديث الملاحظات',
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'authError': true};
      } else {
        return {'success': false, 'message': 'خطأ في السيرفر'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // API 20: Edit User Location
  Future<Map<String, dynamic>> editLocation({
    required String locationLink,
    required String governorate,
    required String district,
    required String fullAddress,
  }) async {
    final url = Uri.parse('$baseUrl/Customers/Editlocation');
    try {
      final headers = await _authHeaders;
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          'locationLink': locationLink,
          'governorate': governorate,
          'district': district,
          'fullAddress': fullAddress,
        }),
      );
      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode == 200) {
        final data = json.decode(body);
        if (data['status'] == 'success') {
          return {
            'success': true,
            'message': data['messageAr'] ?? 'تم تحديث الموقع بنجاح',
            'data': data['data']
          };
        }
        return {
          'success': false,
          'message': data['messageAr'] ?? 'فشل في تحديث الموقع',
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'authError': true};
      } else {
        return {'success': false, 'message': 'خطأ في السيرفر'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // API: Update Device Token for Notifications
  Future<Map<String, dynamic>> updateDeviceToken({
    required String deviceToken,
    required String deviceType,
    required String appVersion,
  }) async {
    final url = Uri.parse('$baseUrl/auth/UpdateDeviceToken');
    try {
      final headers = await _authHeaders;
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          'deviceToken': deviceToken,
          'deviceType': deviceType,
          'appVersion': appVersion,
        }),
      );

      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode == 200) {
        final data = json.decode(body);
        if (data['status'] == 'success') {
          return {'success': true, 'message': data['messageAr'], 'data': data};
        }
        return {
          'success': false,
          'message': data['messageAr'] ?? 'فشل تحديث التوكن',
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'authError': true};
      } else {
        return {'success': false, 'message': 'خطأ في السيرفر'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال بالسيرفر'};
    }
  }

  // API: Get My Notifications
  Future<Map<String, dynamic>> getMyNotifications() async {
    final url = Uri.parse('$baseUrl/auth/MyNotifications');
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);
      final data = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'data': data['notifications'] ?? []};
      } else if (response.statusCode == 401) {
        return {'success': false, 'authError': true};
      } else {
        return {'success': false, 'message': 'فشل في جلب الإشعارات'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // API: Mark Notification(s) as Read
  Future<Map<String, dynamic>> markNotificationAsRead(int? notificationId) async {
    final url = Uri.parse('$baseUrl/auth/ReadMyNotifications');
    try {
      final headers = await _authHeaders;
      final body = notificationId != null ? {'notificationId': notificationId} : {};

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );

      final data = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'message': data['messageAr']};
      } else {
        return {
          'success': false,
          'message': data['messageAr'] ?? 'فشل في التحديث',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // API: Get My Invoices
  Future<Map<String, dynamic>> getMyInvoices({
    String? dateType,
    String? startDate,
    String? endDate,
  }) async {
    final Map<String, String> queryParams = {};
    if (dateType != null) queryParams['dateType'] = dateType;
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;

    final url = Uri.parse('$baseUrl/order/MyInvoices').replace(queryParameters: queryParams);
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);
      final body = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final data = json.decode(body);
        if (data['status'] == 'success') {
          return {
            'success': true,
            'data': data['invoices'] ?? [],
            'total': data['total'] ?? 0,
          };
        }
        return {
          'success': false,
          'message': data['messageAr'] ?? 'فشل جلب الفواتير',
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'authError': true};
      } else {
        return {
          'success': false,
          'message': 'خطأ في السيرفر (${response.statusCode})',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // API: View Invoice Details
  Future<Map<String, dynamic>> getViewInvoiceDetails(int invoiceId) async {
    final url = Uri.parse('$baseUrl/order/ViewInvoiceDetails?invoiceId=$invoiceId');
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);
      final body = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final data = json.decode(body);
        if (data['status'] == 'success') {
          return {'success': true, 'data': data};
        }
        return {
          'success': false,
          'message': data['messageAr'] ?? 'فشل جلب تفاصيل الفاتورة',
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'authError': true};
      } else {
        return {'success': false, 'message': 'خطأ في السيرفر'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // API: Get Order Status Steps (Tracking)
  Future<Map<String, dynamic>> getOrderStatusSteps(int orderId) async {
    final url = Uri.parse('$baseUrl/Transactions/OrderStatusSteps?orderId=$orderId');
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);
      final body = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final data = json.decode(body);
        if (data['status'] == 'success') {
          return {'success': true, 'data': data};
        }
        return {
          'success': false,
          'message': data['messageAr'] ?? 'فشل جلب حالة الطلب',
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'authError': true};
      } else {
        return {'success': false, 'message': 'خطأ في السيرفر'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }
  // API: Get Advertisements / Notices
  Future<Map<String, dynamic>> getAds({String? adType}) async {
    final queryParam = adType != null ? '?adType=$adType' : '';
    final url = Uri.parse('$baseUrl/Advertisements/GetAllAdvertisements$queryParam');
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);
      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode == 200) {
        final data = json.decode(body);
        if (data['status'] == 'success') {
          return {'success': true, 'data': data['advertisements'] ?? []};
        }
        return {'success': false, 'message': data['messageAr'] ?? 'لا توجد إعلانات'};
      } else if (response.statusCode == 401) {
        return {'success': false, 'authError': true};
      }
      return {'success': false, 'message': 'خطأ في السيرفر'};
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال'};
    }
  }

  // API: Report screenshot/screen recording
  Future<Map<String, dynamic>> reportScreenCapture({
    required String captureType, // SCREENSHOT or SCREEN_RECORDING
    required String deviceType,
    required String deviceModel,
    required String osVersion,
    required String appVersion,
    String? screenName,
  }) async {
    final url = Uri.parse('$baseUrl/Screenshot/CreateUserScreenshot');
    try {
      final headers = await _authHeaders;
      final response = await http.post(url, headers: headers, body: json.encode({
        'captureType': captureType,
        'deviceType': deviceType,
        'deviceModel': deviceModel,
        'osVersion': osVersion,
        'appVersion': appVersion,
        'screenName': screenName ?? 'UNKNOWN',
      }));
      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode == 200) {
        final data = json.decode(body);
        return {'success': data['status'] == 'success', 'message': data['messageAr'] ?? ''};
      }
      return {'success': false, 'message': 'خطأ في السيرفر'};
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال'};
    }
  }

  // GET Purchase Invoices List
  Future<Map<String, dynamic>> getPurchaseInvoices({String? autoNumber}) async {
    String query = '';
    if (autoNumber != null && autoNumber.isNotEmpty) {
      query = '?autoNumber=${Uri.encodeComponent(autoNumber)}';
    }
    final url = Uri.parse('$baseUrl/PurchaseInvoice/GetAllInvoice$query');
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);
      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode == 200) {
        final data = json.decode(body);
        return {'success': true, 'data': data['invoices'] ?? [], 'total': data['total'] ?? 0};
      } else {
        final data = json.decode(body);
        return {'success': false, 'message': data['messageAr'] ?? 'فشل في تحميل الفواتير'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // POST Receive Purchase Item Delivery
  Future<Map<String, dynamic>> receivePurchaseItem({
    required int invoiceId,
    required String itemCode,
    required double qtyReceived,
  }) async {
    final url = Uri.parse('$baseUrl/PurchaseInvoice/DeliveryInvoice');
    try {
      final headers = await _authHeaders;
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          'invoiceId': invoiceId,
          'itemCode': itemCode,
          'qtyReceived': qtyReceived,
        }),
      );
      final body = utf8.decode(response.bodyBytes);
      final data = json.decode(body);
      if (response.statusCode == 200) {
        return {'success': data['status'] == 'success', 'message': data['messageAr'] ?? 'تم الاستلام بنجاح'};
      } else {
        return {'success': false, 'message': data['messageAr'] ?? 'فشل في عملية الاستلام'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // GET User's Deliveries List
  Future<Map<String, dynamic>> getMyDeliveries({int? invoiceId}) async {
    String query = '';
    if (invoiceId != null) {
      query = '?invoiceId=$invoiceId';
    }
    final url = Uri.parse('$baseUrl/PurchaseInvoice/GetAllItemsDelivery$query');
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);
      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode == 200) {
        final data = json.decode(body);
        return {'success': true, 'data': data['deliveries'] ?? [], 'total': data['total'] ?? 0};
      } else {
        final data = json.decode(body);
        return {'success': false, 'message': data['messageAr'] ?? 'فشل في تحميل البيانات'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // POST Update Delivery Quantity
  Future<Map<String, dynamic>> updateDeliveryQty({
    required int deliveryId,
    required double qtyReceived,
  }) async {
    final url = Uri.parse('$baseUrl/PurchaseInvoice/UpdateQtyDelivery');
    try {
      final headers = await _authHeaders;
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          'deliveryId': deliveryId,
          'qtyReceived': qtyReceived,
        }),
      );
      final body = utf8.decode(response.bodyBytes);
      final data = json.decode(body);
      if (response.statusCode == 200) {
        return {'success': data['status'] == 'success', 'message': data['messageAr'] ?? 'تم تعديل الكمية بنجاح'};
      } else {
        return {'success': false, 'message': data['messageAr'] ?? 'فشل في تعديل الكمية'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // GET Active Stock Count Sessions
  Future<Map<String, dynamic>> getActiveCountSessions() async {
    final url = Uri.parse('$baseUrl/StockCount/GetActiveSessions');
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);
      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode == 200) {
        final data = json.decode(body);
        return {'success': true, 'data': data['sessions'] ?? [], 'total': data['total'] ?? 0};
      } else {
        final data = json.decode(body);
        return {'success': false, 'message': data['messageAr'] ?? 'فشل في جلب جلسات الجرد'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // POST Save Count Detail
  Future<Map<String, dynamic>> saveCountDetail({
    required int masterId,
    required String itemCode,
    required double qtyCounted,
    required String location,
    String? notes,
  }) async {
    final url = Uri.parse('$baseUrl/StockCount/SaveCountDetail');
    try {
      final headers = await _authHeaders;
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          'masterId': masterId,
          'itemCode': itemCode,
          'qtyCounted': qtyCounted,
          'location': location,
          'notes': notes ?? '',
        }),
      );
      final body = utf8.decode(response.bodyBytes);
      final data = json.decode(body);
      if (response.statusCode == 200) {
        return {'success': data['status'] == 'success', 'message': data['messageAr'] ?? 'تم تسجيل عملية الجرد بنجاح'};
      } else {
        return {'success': false, 'message': data['messageAr'] ?? 'فشل في تسجيل عملية الجرد'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // GET Counted Items List in Current Session
  Future<Map<String, dynamic>> getCountSessionDetails({required int masterId}) async {
    final url = Uri.parse('$baseUrl/StockCount/GetSessionDetails?masterId=$masterId');
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);
      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode == 200) {
        final data = json.decode(body);
        return {'success': true, 'data': data['details'] ?? [], 'total': data['total'] ?? 0};
      } else {
        final data = json.decode(body);
        return {'success': false, 'message': data['messageAr'] ?? 'فشل في جلب تفاصيل الجرد'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // POST Update Counted Item Quantity / Notes
  Future<Map<String, dynamic>> updateCountQty({
    required int detailId,
    required double qtyCounted,
    String? notes,
  }) async {
    final url = Uri.parse('$baseUrl/StockCount/UpdateCountQty');
    try {
      final headers = await _authHeaders;
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          'detailId': detailId,
          'qtyCounted': qtyCounted,
          'notes': notes ?? '',
        }),
      );
      final body = utf8.decode(response.bodyBytes);
      final data = json.decode(body);
      if (response.statusCode == 200) {
        return {'success': data['status'] == 'success', 'message': data['messageAr'] ?? 'تم تعديل الكمية بنجاح'};
      } else {
        return {'success': false, 'message': data['messageAr'] ?? 'فشل في تعديل الكمية'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // GET Delivery Men List
  Future<Map<String, dynamic>> getDeliveryMen() async {
    final url = Uri.parse('$baseUrl/DeliveryReview/GetDeliveryMen');
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);
      final body = utf8.decode(response.bodyBytes);
      final data = json.decode(body);
      if (response.statusCode == 200) {
        return {'success': data['status'] == 'success', 'data': data['deliveryMen'] ?? []};
      } else {
        return {'success': false, 'message': data['messageAr'] ?? 'فشل في تحميل قائمة المناديب'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // GET Delivery Invoices By Date
  Future<Map<String, dynamic>> getInvoicesByDate({String? deliveryDate}) async {
    String query = '';
    if (deliveryDate != null && deliveryDate.isNotEmpty) {
      query = '?deliveryDate=${Uri.encodeComponent(deliveryDate)}';
    }
    final url = Uri.parse('$baseUrl/DeliveryReview/GetInvoicesByDate$query');
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);
      final body = utf8.decode(response.bodyBytes);
      final data = json.decode(body);
      if (response.statusCode == 200) {
        return {'success': data['status'] == 'success', 'data': data['invoices'] ?? []};
      } else {
        return {'success': false, 'message': data['messageAr'] ?? 'فشل في تحميل الفواتير'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // GET Salesman Invoices By Date
  Future<Map<String, dynamic>> getSalesmanInvoices({String? deliveryDate}) async {
    String query = '';
    if (deliveryDate != null && deliveryDate.isNotEmpty) {
      query = '?deliveryDate=${Uri.encodeComponent(deliveryDate)}';
    }
    final url = Uri.parse('$baseUrl/DeliveryReview/GetSalesmanInvoices$query');
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);
      final body = utf8.decode(response.bodyBytes);
      final data = json.decode(body);
      if (response.statusCode == 200) {
        return {'success': data['status'] == 'success', 'data': data['invoices'] ?? []};
      } else {
        return {'success': false, 'message': data['messageAr'] ?? 'فشل في تحميل فواتير المندوب'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // POST Start Delivery Journey
  Future<Map<String, dynamic>> startDeliveryJourney({
    required int invoiceId,
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse('$baseUrl/DeliveryReview/StartDeliveryJourney');
    try {
      final headers = await _authHeaders;
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          'invoiceId': invoiceId,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );
      final body = utf8.decode(response.bodyBytes);
      final data = json.decode(body);
      if (response.statusCode == 200) {
        return {'success': data['status'] == 'success', 'message': data['messageAr'] ?? 'تم بدء الرحلة بنجاح'};
      } else {
        return {'success': false, 'message': data['messageAr'] ?? 'فشل بدء الرحلة'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // POST Add Tracking Point (Breadcrumbs with battery telemetry)
  Future<Map<String, dynamic>> addTrackingPoint({
    required int invoiceId,
    required double latitude,
    required double longitude,
    double? bearing,
    required int batteryLevel,
    required bool isCharging,
  }) async {
    final url = Uri.parse('$baseUrl/DeliveryReview/AddTrackingPoint');
    try {
      final headers = await _authHeaders;
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          'invoiceId': invoiceId,
          'latitude': latitude,
          'longitude': longitude,
          'bearing': bearing ?? 0.0,
          'batteryLevel': batteryLevel,
          'isCharging': isCharging ? 'Y' : 'N',
        }),
      );
      final body = utf8.decode(response.bodyBytes);
      final data = json.decode(body);
      if (response.statusCode == 200) {
        return {'success': data['status'] == 'success', 'message': data['messageAr'] ?? 'تم تسجيل النقطة'};
      } else {
        return {'success': false, 'message': data['messageAr'] ?? 'فشل تسجيل النقطة'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // POST End Delivery Journey
  Future<Map<String, dynamic>> endDeliveryJourney({
    required int invoiceId,
    required double latitude,
    required double longitude,
    required double totalKm,
    required double totalMinutes,
    required String deliveryStatus,
    String? notes,
  }) async {
    final url = Uri.parse('$baseUrl/DeliveryReview/EndDeliveryJourney');
    try {
      final headers = await _authHeaders;
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          'invoiceId': invoiceId,
          'latitude': latitude,
          'longitude': longitude,
          'totalKm': totalKm,
          'totalMinutes': totalMinutes,
          'deliveryStatus': deliveryStatus,
          'notes': notes ?? '',
        }),
      );
      final body = utf8.decode(response.bodyBytes);
      final data = json.decode(body);
      if (response.statusCode == 200) {
        return {'success': data['status'] == 'success', 'message': data['messageAr'] ?? 'تم إنهاء الرحلة بنجاح'};
      } else {
        return {'success': false, 'message': data['messageAr'] ?? 'فشل إنهاء الرحلة'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // GET Invoice Details for Review
  Future<Map<String, dynamic>> getInvoiceDetails(int invoiceId) async {
    final url = Uri.parse('$baseUrl/DeliveryReview/GetInvoiceDetails?invoiceId=$invoiceId');
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);
      final body = utf8.decode(response.bodyBytes);
      final data = json.decode(body);
      if (response.statusCode == 200) {
        return {'success': data['status'] == 'success', 'data': data['items'] ?? []};
      } else {
        return {'success': false, 'message': data['messageAr'] ?? 'فشل في تحميل تفاصيل الفاتورة'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // POST Update Invoice Delivery Details
  Future<Map<String, dynamic>> updateInvoiceDelivery({
    required int invoiceId,
    int? salesmanDeliveryId,
    required String deliveryStatus,
    String? deliveryNotes,
  }) async {
    final url = Uri.parse('$baseUrl/DeliveryReview/UpdateInvoiceDelivery');
    try {
      final headers = await _authHeaders;
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          'invoiceId': invoiceId,
          'salesmanDeliveryId': salesmanDeliveryId,
          'deliveryStatus': deliveryStatus,
          'deliveryNotes': deliveryNotes ?? '',
        }),
      );
      final body = utf8.decode(response.bodyBytes);
      final data = json.decode(body);
      if (response.statusCode == 200) {
        return {'success': data['status'] == 'success', 'message': data['messageAr'] ?? 'تم تحديث الفاتورة بنجاح'};
      } else {
        return {'success': false, 'message': data['messageAr'] ?? 'فشل في تحديث الفاتورة'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // POST Update Item Review Status
  Future<Map<String, dynamic>> updateItemReview({
    required int invoiceId,
    int? detailId,
    required int isReviewed,
    required bool reviewAll,
  }) async {
    final url = Uri.parse('$baseUrl/DeliveryReview/UpdateItemReview');
    try {
      final headers = await _authHeaders;
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          'invoiceId': invoiceId,
          'detailId': detailId,
          'isReviewed': isReviewed,
          'reviewAll': reviewAll.toString(),
        }),
      );
      final body = utf8.decode(response.bodyBytes);
      final data = json.decode(body);
      if (response.statusCode == 200) {
        return {'success': data['status'] == 'success', 'message': data['messageAr'] ?? 'تم التحديث بنجاح'};
      } else {
        return {'success': false, 'message': data['messageAr'] ?? 'فشل في تحديث حالة المراجعة'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }
}
