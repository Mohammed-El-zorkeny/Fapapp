/// Web stub - PDF download to local storage is not supported on web.
Future<String?> downloadPdfToLocal({
  required String url,
  required String invoiceNumber,
  required String? token,
}) async {
  // Not supported on web - use url_launcher instead
  return null;
}
