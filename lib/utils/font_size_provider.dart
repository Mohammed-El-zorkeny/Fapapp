import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global font scale provider — persisted in SharedPreferences
class FontSizeProvider extends ChangeNotifier {
  FontSizeProvider._internal();
  static final FontSizeProvider instance = FontSizeProvider._internal();

  static const String _key = 'app_font_scale';

  // 0.85 = صغير | 1.0 = متوسط (افتراضي) | 1.15 = كبير
  double _scale = 1.0;

  double get scale => _scale;

  /// Call once at app startup
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _scale = prefs.getDouble(_key) ?? 1.0;
    notifyListeners();
  }

  Future<void> setScale(double value) async {
    _scale = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, value);
    notifyListeners();
  }

  static const List<({String label, double value, IconData icon})> presets = [
    (label: 'صغير', value: 0.82, icon: Icons.text_fields),
    (label: 'متوسط', value: 1.0, icon: Icons.format_size),
    (label: 'كبير', value: 1.18, icon: Icons.format_size),
  ];
}
