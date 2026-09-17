import 'package:flutter/material.dart';

/// Raintech Hotel palette, sampled from the product reference mockups.
abstract final class AppColors {
  // Surfaces
  static const background = Color(0xFFFAF7F0);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF1F4F9);
  static const cream = Color(0xFFE8E2D1);
  static const creamDark = Color(0xFFD6CDB6);

  // Brand
  static const primary = Color(0xFF113159);
  static const primaryDark = Color(0xFF0B2340);
  static const primaryLight = Color(0xFF1E3A5F);
  static const accent = Color(0xFFC9A84C);
  static const accentLight = Color(0xFFEBD9A8);

  // Text
  static const textPrimary = Color(0xFF16233A);
  static const textSecondary = Color(0xFF6B7A90);
  static const border = Color(0xFFE3E8F0);

  // Semantic (soft fills + strong tones for text/icons)
  static const success = Color(0xFF88C999);
  static const successDark = Color(0xFF3F9B5C);
  static const error = Color(0xFFE57373);
  static const errorDark = Color(0xFFD14343);
  static const warning = Color(0xFFFFB74D);
  static const warningDark = Color(0xFFE08A1E);
  static const info = Color(0xFF5C88DA);
  static const infoDark = Color(0xFF34619F);

  // Room status (interactive floor view)
  static const roomAvailable = Color(0xFF88C999);
  static const roomOccupied = Color(0xFF5C88DA);
  static const roomDirty = Color(0xFFE57373);
  static const roomMaintenance = Color(0xFFFFB74D);
  static const roomBlocked = Color(0xFFB0B7C3);

  /// Legacy aliases kept so older screens keep compiling.
  static const secondary = cream;
  static const secondaryDark = creamDark;

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get raisedShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];
}
