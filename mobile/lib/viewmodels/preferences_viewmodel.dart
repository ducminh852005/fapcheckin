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
  String? _registeredToken;
  // One token per app installation (FCM token used as the document key via a safe encoding).
  String _deviceId(String token) => Uri.encodeComponent(token);
  ThemeMode get themeMode => switch (theme) {'dark' => ThemeMode.dark, 'system' => ThemeMode.system, _ => ThemeMode.light};
  String tr(String vi, String en) => language == 'en' ? en : vi;

  Future<void> bindAccount(String? uid) async {
    if (_uid == uid) return;
    _uid = uid;
    _registeredToken = null;
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
    }
    notifyListeners();
    if (reminders) {
      try {
        final pushError = await _registerPush(generation, requestPermission: false);
        if (pushError != null && generation == _generation) {
          error = 'Không thể đăng ký nhận push: $pushError';
          notifyListeners();
        }
      } catch (e) {
        if (generation == _generation) {
          final msg = e.toString().replaceFirst(RegExp(r'^(Bad state|Exception|StateError):\s*'), '');
          error = 'Không thể đăng ký nhận push: $msg';
          notifyListeners();
        }
      }
    }
  }

  Future<String?> _registerPush(int generation, {bool requestPermission = true}) async {
    final messaging = FirebaseMessaging.instance;
    final permission = requestPermission ? await messaging.requestPermission() : await messaging.getNotificationSettings();
    if (permission.authorizationStatus != AuthorizationStatus.authorized && permission.authorizationStatus != AuthorizationStatus.provisional) {
      return 'Chưa được cấp quyền thông báo trên thiết bị.';
    }
    await _tokens?.cancel();
    final firstRegistration = Completer<String>();
    _tokens = messaging.onRegistered.listen((token) async {
      if (!firstRegistration.isCompleted) {
        firstRegistration.complete(token);
        return;
      }
      if (generation == _generation && reminders) {
        _registeredToken = token;
        await repository.registerDevice(_deviceId(token), token);
      }
    });
    await messaging.register();
    final token = await firstRegistration.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => '',
    );
    if (generation != _generation) return null;
    if (token.isEmpty) {
      return 'Chưa nhận được token thông báo. Kiểm tra cấu hình FCM/APNs.';
    }
    final saved = await repository.registerDevice(_deviceId(token), token);
    if (saved is ApiFailure<void>) {
      return saved.error.message;
    }
    _registeredToken = token;
    return null;
  }

  Future<bool> save({String? newTheme, String? newLanguage, bool? newReminders}) async {
    if (saving) return false;
    final generation = _generation;
    saving = true; error = null; notifyListeners();
    try {
      if (newReminders == true) {
        final pushError = await _registerPush(generation);
        if (pushError != null) {
          if (generation == _generation) error = pushError;
          return false;
        }
      }
      if (generation != _generation) return false;
      final result = await repository.savePreferences(
        theme: newTheme ?? theme,
        language: newLanguage ?? language,
        reminders: newReminders ?? reminders,
      );
      if (generation != _generation) return false;
      if (result is ApiFailure<void>) {
        if (generation == _generation) error = result.error.message;
        return false;
      }
      if (newReminders == false && reminders) {
        await unregisterDevice();
      }
      theme = newTheme ?? theme;
      language = newLanguage ?? language;
      reminders = newReminders ?? reminders;
      return true;
    } catch (e) {
      if (generation == _generation) {
        error = e.toString().replaceFirst(RegExp(r'^(Bad state|Exception|StateError):\s*'), '');
      }
      return false;
    } finally {
      if (generation == _generation) {
        saving = false;
        notifyListeners();
      }
    }
  }
  Future<void> unregisterDevice() async {
    try {
      final messaging = FirebaseMessaging.instance;
      var token = _registeredToken;
      if (token == null || token.isEmpty) {
        final registration = messaging.onRegistered.first.timeout(
          const Duration(seconds: 10),
          onTimeout: () => '',
        );
        await messaging.register();
        token = await registration;
      }
      if (token.isNotEmpty) {
        await repository.removeDevice(_deviceId(token));
      }
      await messaging.unregister();
      _registeredToken = null;
    } catch (_) { /* Sign-out must remain possible when offline. */ }
  }
  @override
  void dispose() { _generation++; _tokens?.cancel(); super.dispose(); }
}
