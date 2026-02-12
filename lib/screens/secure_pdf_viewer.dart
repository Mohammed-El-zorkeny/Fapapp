import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:screenshot_callback/screenshot_callback.dart';
import 'package:dio/dio.dart';
import '../services/storage_service.dart';
import '../utils/app_colors.dart';

class SecurePdfViewer extends StatefulWidget {
  final String title;
  final String filePath; // URL or Local Path

  const SecurePdfViewer({
    super.key,
    this.title = 'عرض الكشف',
    required this.filePath,
    String? userName,
  });

  @override
  State<SecurePdfViewer> createState() => _SecurePdfViewerState();
}

class _SecurePdfViewerState extends State<SecurePdfViewer> {
  final StorageService _storageService = StorageService();
  final PdfViewerController _pdfViewerController = PdfViewerController();
  // Internal ScreenshotCallback - nullable to handle web/unsupported platforms
  ScreenshotCallback? _screenshotCallback;

  bool _hasError = false;
  bool _isLoading = true;
  String? _errorMessage;
  String? _userName;
  Uint8List? _pdfBytes;

  late final bool _isNetworkUrl;

  @override
  void initState() {
    super.initState();
    _isNetworkUrl = widget.filePath.startsWith('http');
    _loadUserAndPdf();
    _initScreenshotProtection();
  }

  Future<void> _loadUserAndPdf() async {
    try {
      _userName = await _storageService.getUserNameAr() ?? 'User';

      if (_isNetworkUrl) {
        await _fetchPdfBytes();
      } else {
        // Local file
        if (!kIsWeb) {
          final file = File(widget.filePath);
          if (await file.exists()) {
            _pdfBytes = await file.readAsBytes();
          } else {
            throw Exception('File not found');
          }
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = _pdfBytes == null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = _parseError(e);
        });
      }
    }
  }

  Future<void> _fetchPdfBytes() async {
    final token = await _storageService.getToken();
    final dio = Dio();

    // Set Headers
    dio.options.headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/pdf',
    };

    try {
      final response = await dio.get(
        widget.filePath,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        final dynamic data = response.data;
        if (data is List<int>) {
          _pdfBytes = Uint8List.fromList(data);
        } else {
          throw Exception('Invalid data format');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      if (kIsWeb) {
        // Check for generic connection error which usually means CORS on Web
        // Dio often wraps XHR errors as DioExceptionType.connectionError or unknown
        if (e is DioException &&
            (e.type == DioExceptionType.connectionError ||
                e.type == DioExceptionType.unknown)) {
          _showCorsDialog();
          return; // Stop further error handling
        }
      }
      print("Download Error: $e");
      rethrow;
    }
  }

  void _showCorsDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('خطأ في المتصفح (CORS)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('المتصفح يمنع الاتصال بالسيرفر بسبب سياسات الأمان.'),
            const SizedBox(height: 10),
            const Text(
              'لحل المشكلة أثناء التطوير، قم بتشغيل التطبيق بهذا الأمر:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey.shade100,
              child: const SelectableText(
                'flutter run -d chrome --web-browser-flag "--disable-web-security"',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  String _parseError(dynamic e) {
    final eStr = e.toString();
    if (eStr.contains('401')) return 'يرجى تسجيل الدخول مجدداً';
    if (eStr.contains('403')) return 'ليس لديك صلاحية';
    if (eStr.contains('404')) return 'الملف غير موجود';
    return 'حدث خطأ في التحميل';
  }

  void _initScreenshotProtection() {
    // ScreenshotCallback likely doesn't support Web or might act up.
    if (kIsWeb) return;

    try {
      _screenshotCallback = ScreenshotCallback();
      _screenshotCallback?.addListener(() {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تحذير أمني'),
            content: const Text('يمنع التقاط صور للشاشة حمايةً للبيانات.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      });
    } catch (e) {
      print("Screenshot protection init failed: $e");
    }
  }

  @override
  void dispose() {
    try {
      _screenshotCallback?.dispose();
    } catch (e) {
      print("Error disposing screenshot callback: $e");
    }
    super.dispose();
  }

  Widget _buildWatermarkText() {
    return Transform.rotate(
      angle: -0.5,
      child: Opacity(
        opacity: 0.15,
        child: Text(
          _userName ?? 'Loading...',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  Widget _buildWatermarkOverlay() {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            6,
            (index) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Flexible(child: _buildWatermarkText()),
                Flexible(child: _buildWatermarkText()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black),
          titleTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          actions: [
            if (!_isLoading && !_hasError)
              _PdfZoomControls(
                onZoomIn: () => _pdfViewerController.zoomLevel += 0.25,
                onZoomOut: () => _pdfViewerController.zoomLevel -= 0.25,
              ),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              if (_pdfBytes != null)
                SfPdfViewer.memory(
                  _pdfBytes!,
                  controller: _pdfViewerController,
                  pageLayoutMode: PdfPageLayoutMode.continuous,
                  enableDoubleTapZooming: true,
                  interactionMode: PdfInteractionMode.pan,
                  onDocumentLoadFailed: (details) {
                    setState(() {
                      _hasError = true;
                      _errorMessage = 'الملف تالف أو غير مدعوم';
                    });
                  },
                ),

              if (_isLoading) const Center(child: CircularProgressIndicator()),

              if (_hasError)
                _PdfErrorView(
                  errorMessage: _errorMessage,
                  onRetry: _loadUserAndPdf,
                ),

              Positioned.fill(child: _buildWatermarkOverlay()),
            ],
          ),
        ),
      ),
    );
  }
}

class _PdfZoomControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const _PdfZoomControls({required this.onZoomIn, required this.onZoomOut});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.zoom_out, color: AppColors.primary),
          onPressed: onZoomOut,
        ),
        IconButton(
          icon: const Icon(Icons.zoom_in, color: AppColors.primary),
          onPressed: onZoomIn,
        ),
      ],
    );
  }
}

class _PdfErrorView extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback onRetry;

  const _PdfErrorView({this.errorMessage, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'تعذر عرض الملف',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
