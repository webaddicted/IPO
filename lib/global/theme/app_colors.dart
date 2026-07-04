import 'package:flutter/material.dart';

/// App colour palette — soft rose pink brand with emerald data accents.
class AppColors {
  const AppColors._();

  // Brand (#FF8DA1)
  static const Color primary = Color(0xFFFF8DA1);
  static const Color primaryLight = Color(0xFFFFB3C1);
  static const Color primaryDark = Color(0xFFE5748A);
  static const Color accent = Color(0xFF10B981);
  static const Color accentLight = Color(0xFF34D399);

  // Surfaces
  static const Color scaffold = Color(0xFFFDF8F9);
  static const Color scaffoldAlt = Color(0xFFFFF0F3);
  static const Color card = Colors.white;
  static const Color cardBorder = Color(0xFFF5DDE3);

  // Text
  static const Color textPrimary = Color(0xFF1A1F36);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color divider = Color(0xFFF0E4E8);

  // Status badge colours
  static const Color statusOpen = Color(0xFF059669);
  static const Color statusUpcoming = Color(0xFFD97706);
  static const Color statusClosed = Color(0xFFDC2626);
  static const Color statusListed = Color(0xFF6366F1);

  // GMP gain / loss
  static const Color gain = Color(0xFF059669);
  static const Color loss = Color(0xFFDC2626);
  static const Color neutral = Color(0xFF6B7280);

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE5748A), Color(0xFFFF8DA1), Color(0xFFFFB3C1)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFF8DA1), Color(0xFFFFB3C1)],
  );

  static const LinearGradient cardShimmer = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFBFC), Color(0xFFFFF0F3)],
  );

  static LinearGradient statusGradient(IpoStatusColor status) => switch (status) {
        IpoStatusColor.open => const LinearGradient(
            colors: [Color(0xFF059669), Color(0xFF10B981)],
          ),
        IpoStatusColor.upcoming => const LinearGradient(
            colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
          ),
        IpoStatusColor.closed => const LinearGradient(
            colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
          ),
        IpoStatusColor.listed => const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
          ),
      };
}

enum IpoStatusColor { open, upcoming, closed, listed }
