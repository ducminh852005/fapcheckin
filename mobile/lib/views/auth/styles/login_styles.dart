import 'package:flutter/material.dart';

/// Design tokens scoped to login, so editing this page does not change other screens.
abstract final class LoginStyles {
  static const background = Color(0xFFF2F5FA);
  static const ink = Color(0xFF193457);
  static const muted = Color(0xFF64748B);
  static const orange = Color(0xFFFF7020);
  static const green = Color(0xFF00866A);
  static const warmGlow = Color(0xFFFFE0C5);
  static const coolGlow = Color(0xFFCFDFF7);
  static const border = Color(0xFF8D9197);
  static const pagePadding = 24.0;
  static const contentWidth = 412.0;
  static const cardRadius = 28.0;
  static const title = TextStyle(
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: ink,
  );
  static const caption = TextStyle(fontSize: 12, height: 1.5, color: muted);
}
