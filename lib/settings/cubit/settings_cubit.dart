import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState()) {
    _loadSettings();
  }

  static const _keyHijriOffset  = 'hijri_offset';
  static const _keyLanguage      = 'language';
  static const _keyTheme         = 'theme';
  static const _keyNotifications = 'notifications_enabled';
  static const _keyAdhan         = 'adhan_enabled';
  static const _keyVibration     = 'vibration_enabled';
  static const _key24Hour        = 'use_24_hour';
  static const _keyDarkHeader    = 'dark_header';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    emit(state.copyWith(
      hijriOffset:          prefs.getInt(_keyHijriOffset) ?? 0,
      languageCode:         prefs.getString(_keyLanguage) ?? 'en',
      themeMode:            prefs.getString(_keyTheme) ?? 'dark',
      notificationsEnabled: prefs.getBool(_keyNotifications) ?? true,
      adhanEnabled:         prefs.getBool(_keyAdhan) ?? true,
      vibrationEnabled:     prefs.getBool(_keyVibration) ?? true,
      use24Hour:            prefs.getBool(_key24Hour) ?? false,
      darkHeader:           prefs.getBool(_keyDarkHeader) ?? true,
      isLoaded:             true,
    ));
  }

  Future<void> setHijriOffset(int offset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyHijriOffset, offset);
    emit(state.copyWith(hijriOffset: offset));
  }

  Future<void> setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, code);
    emit(state.copyWith(languageCode: code));
  }

  Future<void> setTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, theme);
    emit(state.copyWith(themeMode: theme));
  }

  Future<void> toggleNotifications(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, val);
    emit(state.copyWith(notificationsEnabled: val));
  }

  Future<void> toggleAdhan(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAdhan, val);
    emit(state.copyWith(adhanEnabled: val));
  }

  Future<void> toggleVibration(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVibration, val);
    emit(state.copyWith(vibrationEnabled: val));
  }

  Future<void> toggle24Hour(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key24Hour, val);
    emit(state.copyWith(use24Hour: val));
  }

  Future<void> toggleDarkHeader(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkHeader, val);
    emit(state.copyWith(darkHeader: val));
  }

  Future<void> resetAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    emit(const SettingsState(isLoaded: true));
  }
}