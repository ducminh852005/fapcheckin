import 'package:flutter/material.dart';

/// Design tokens scoped to login, so editing this page does not change other screens.
abstract final class LoginStyles {
  static const background = Color(0xFFF8FAFC);
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const orange = Color(0xFFFF6600);
  static const green = Color(0xFF059669);
  static const warmGlow = Color(0xFFFFE8D6);
  static const coolGlow = Color(0xFFE8EEF8);
  static const border = Color(0xFFE2E8F0);
  static const pagePadding = 24.0;
  static const contentWidth = 412.0;
  static const cardRadius = 28.0;
  static const title = TextStyle(
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w800,
    color: ink,
  );
  static const caption = TextStyle(fontSize: 12, height: 1.5, color: muted);
}
