import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class LocaleController extends GetxController {
  final StorageService _storageService = Get.find();

  final Rx<Locale> _locale = const Locale('it', 'IT').obs;
  Locale get locale => _locale.value;

  @override
  void onInit() {
    super.onInit();
    _loadLocale();
  }

  void _loadLocale() {
    final savedLanguage = _storageService.getLanguage();
    if (savedLanguage == 'it') {
      _locale.value = const Locale('it', 'IT');
    } else {
      _locale.value = const Locale('en', 'US');
    }
    Get.updateLocale(_locale.value);
  }

  /// Re-applies the persisted language from storage.
  void reloadFromStorage() {
    _loadLocale();
  }

  Future<void> changeLocale(String languageCode) async {
    if (languageCode == currentLanguageCode) return;

    Locale newLocale;
    if (languageCode == 'it') {
      newLocale = const Locale('it', 'IT');
    } else {
      newLocale = const Locale('en', 'US');
    }

    _locale.value = newLocale;
    await _storageService.saveLanguage(languageCode);
    Get.updateLocale(newLocale);
  }

  String get currentLanguageCode {
    return _locale.value.languageCode;
  }

  bool get isEnglish => currentLanguageCode == 'en';
  bool get isItalian => currentLanguageCode == 'it';
}
