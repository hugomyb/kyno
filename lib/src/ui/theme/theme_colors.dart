import 'package:flutter/material.dart';

/// Helper class for theme-aware colors
class ThemeColors {
  ThemeColors(this.context);
  
  final BuildContext context;
  
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  ColorScheme get colorScheme => Theme.of(context).colorScheme;
  
  // Card colors
  Color get cardBackground => isDark ? const Color(0xFF1E293B) : Colors.white;
  Color get cardBackgroundAlt => isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
  
  // Text colors
  Color get textPrimary => isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
  Color get textSecondary => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get textTertiary => isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
  
  // Border colors
  Color get border => isDark 
      ? const Color(0xFF334155).withValues(alpha: 0.5) 
      : const Color(0xFFE2E8F0);
  Color get borderLight => isDark 
      ? const Color(0xFF334155).withValues(alpha: 0.3) 
      : const Color(0xFFF1F5F9);
  
  // Input colors
  Color get inputBackground => isDark ? const Color(0xFF1E293B) : Colors.white;
  Color get inputBorder => isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  
  // Accent colors (always vibrant)
  Color get primary => const Color(0xFF3B82F6);
  Color get primaryLight => isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6);
  Color get success => const Color(0xFF10B981);
  Color get warning => const Color(0xFFF59E0B);
  Color get error => const Color(0xFFEF4444);
  
  // Chip/Badge colors
  Color chipBackground(Color accentColor) => accentColor.withValues(alpha: isDark ? 0.2 : 0.15);
  
  // Shadow
  List<BoxShadow> get cardShadow => isDark
      ? []
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ];
  
  List<BoxShadow> get softShadow => isDark
      ? []
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ];
}

/// Extension to easily access theme colors
extension ThemeColorsExtension on BuildContext {
  ThemeColors get themeColors => ThemeColors(this);
}

