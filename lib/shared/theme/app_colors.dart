import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Primary ────────────────────────────────────────
  static const Color primary = Color(0xFF014AB3);
  static const Color primaryDark = Color(0xFF013A8C);
  static const Color primaryLight = Color(0xFF4D7FD6);

  /// Light tint of primary — used for icon backgrounds, badges,
  /// "selected" chips, etc.
  static const Color primaryContainer = Color(0xFFE3EDFB);

  static const Color onPrimary = Colors.white;

  // ─── Neutrals ───────────────────────────────────────
  static const Color background = Colors.white;
  static const Color surface = Colors.white;

  /// Light gray background for input fields / cards.
  static const Color surfaceVariant = Color(0xFFF5F7FA);

  static const Color border = Color(0xFFE5E9F0);

  // ─── Text ───────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1D29);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  // ─── Status colors (reservations, notifications) ────
  static const Color success = Color(0xFF12B76A);
  static const Color successBg = Color(0xFFE6F9F0);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFEF6E7);

  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0xFFFDECEC);

  static const Color info = Color(0xFF3B82F6);

  /// "SAVE X%" / discount tags.
  static const Color discount = Color(0xFFEF4444);
}