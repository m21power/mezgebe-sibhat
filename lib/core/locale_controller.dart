import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController {
  LocaleController._();
  static final LocaleController instance = LocaleController._();

  /// English by default.
  final ValueNotifier<Locale> locale = ValueNotifier(const Locale('en'));

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    locale.value = Locale(prefs.getString('lang') ?? 'en');
  }

  Future<void> set(String code) async {
    locale.value = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', code);
  }
}
