import 'dart:io';
import 'dart:typed_data';

/// Load PDF bytes from a local file path. Only works on mobile.
Future<Uint8List?> loadLocalPdfBytes(String filePath) async {
  final file = File(filePath);
  if (await file.exists()) {
    return await file.readAsBytes();
  }
  return null;
}
