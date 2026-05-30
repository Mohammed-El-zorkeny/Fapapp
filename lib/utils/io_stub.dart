// Stub file for web platform where dart:io is not available
// This provides no-op implementations of dart:io types used in the app

class File {
  final String path;
  File(this.path);
  
  Future<bool> exists() async => false;
  Future<List<int>> readAsBytes() async => [];
}

class Directory {
  final String? path;
  Directory(this.path);
  
  Future<bool> exists() async => false;
}

class Platform {
  static bool get isAndroid => false;
  static bool get isIOS => false;
  static String get operatingSystemVersion => 'web';
}
