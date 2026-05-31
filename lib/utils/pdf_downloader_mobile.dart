import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

/// Downloads a PDF file to local storage. Only works on mobile platforms.
Future<String?> downloadPdfToLocal({
  required String url,
  required String invoiceNumber,
  required String? token,
}) async {
  final dio = Dio();
  
  Directory? dir;
  if (defaultTargetPlatform == TargetPlatform.android) {
    dir = Directory('/storage/emulated/0/Download');
    if (!await dir.exists()) dir = await getExternalStorageDirectory();
  } else {
    dir = await getApplicationDocumentsDirectory();
  }
  
  final String savePath = '${dir?.path}/Fap_Invoice_$invoiceNumber.pdf';
  
  await dio.download(
    url,
    savePath,
    options: Options(headers: {'Authorization': 'Bearer $token'}),
    onReceiveProgress: (received, total) {},
  );
  
  return savePath;
}
