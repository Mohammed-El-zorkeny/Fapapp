import 'dart:convert';
import 'package:http/http.dart' as http;
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

  // API 4: Get Price List Items
  Future<Map<String, dynamic>> getPriceListItems(int id) async {
    final url = Uri.parse('$baseUrl/priceList/itemsPriceList?priceListId=$id');
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
}
