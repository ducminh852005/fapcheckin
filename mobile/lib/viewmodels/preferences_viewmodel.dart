import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fapcheckin_core/repositories/account_features_repository.dart';
import 'package:fapcheckin_core/result/api_result.dart';

class PreferencesViewModel extends ChangeNotifier {
  PreferencesViewModel(this.repository);
  final AccountFeaturesRepository repository;
  String theme = 'light', language = 'vi';
  bool reminders = false, saving = false;
  String? error;
  String? _uid;
  int _generation = 0;
  StreamSubscription<String>? _tokens;
  // One token per app installation (FCM token used as the document key via a safe encoding).
  String _deviceId(String token) => Uri.encodeComponent(token);
  ThemeMode get themeMode => switch (theme) {'dark' => ThemeMode.dark, 'system' => ThemeMode.system, _ => ThemeMode.light};
  String tr(String vi, String en) => language == 'en' ? en : vi;

  Future<void> bindAccount(String? uid) async {
    if (_uid == uid) return;
    _uid = uid;
    final generation = ++_generation;
    await _tokens?.cancel();
    theme = 'light'; language = 'vi'; reminders = false; saving = false; error = null;
    notifyListeners();
    if (uid == null) return;
    final result = await repository.preferences();
    if (generation != _generation) return;
    if (result is ApiSuccess<Map<String, dynamic>>) {
      theme = result.data['theme'] as String? ?? 'light';
      language = result.data['language'] as String? ?? 'vi';
      reminders = result.data['reminders'] == true;
    } else if (result is ApiFailure<Map<String, dynamic>>) { error = result.error.message; }
    notifyListeners();
    if (reminders) {
      try { await _registerPush(generation, requestPermission: false); } catch (e) { if (generation == _generation) { error = 'Không thể đăng ký nhận push: $e'; notifyListeners(); } }
    }
  }
  Future<void> _registerPush(int generation, {bool requestPermission = true}) async {
    final messaging = FirebaseMessaging.instance;
    final permission = requestPermission ? await messaging.requestPermission() : await messaging.getNotificationSettings();
    if (permission.authorizationStatus != AuthorizationStatus.authorized && permission.authorizationStatus != AuthorizationStatus.provisional) throw StateError('Chưa được cấp quyền thông báo trên thiết bị.');
    final token = await messaging.getToken();
    if (generation != _generation) return;
    if (token == null) throw StateError('Chưa nhận được token thông báo. Kiểm tra cấu hình FCM/APNs.');
    final saved = await repository.registerDevice(_deviceId(token), token);
    if (saved is ApiFailure<void>) throw StateError(saved.error.message);
    await _tokens?.cancel();
    _tokens = messaging.onTokenRefresh.listen((token) async {
      if (generation == _generation && reminders) await repository.registerDevice(_deviceId(token), token);
    });
  }
  Future<bool> save({String? newTheme, String? newLanguage, bool? newReminders}) async {
    if (saving) return false;
    final generation = _generation;
    saving = true; error = null; notifyListeners();
    try {
      if (newReminders == true) await _registerPush(generation);
      if (generation != _generation) return false;
      final result = await repository.savePreferences(theme: newTheme ?? theme, language: newLanguage ?? language, reminders: newReminders ?? reminders);
      if (generation != _generation) return false;
      if (result is ApiFailure<void>) throw StateError(result.error.message);
      theme = newTheme ?? theme; language = newLanguage ?? language; reminders = newReminders ?? reminders;
      return true;
    } catch (e) { if (generation == _generation) error = e.toString(); return false; }
    finally { if (generation == _generation) { saving = false; notifyListeners(); } }
  }
  Future<void> unregisterDevice() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await repository.removeDevice(_deviceId(token));
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) { /* Sign-out must remain possible when offline. */ }
  }
  @override
  void dispose() { _generation++; _tokens?.cancel(); super.dispose(); }
}
