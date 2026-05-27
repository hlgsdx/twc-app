import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light {
    final base = ColorScheme.fromSeed(
      seedColor: const Color(0xFF8F7AE5),
      brightness: Brightness.light,
    );
    final scheme = base.copyWith(
      surface: const Color(0xFFF8F4FF),
      surfaceContainerLowest: const Color(0xFFFFFFFF),
      surfaceContainerLow: const Color(0xFFF2ECFF),
      surfaceContainer: const Color(0xFFEDE5FF),
      surfaceContainerHigh: const Color(0xFFE5DBFA),
      surfaceContainerHighest: const Color(0xFFDCCFF4),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        elevation: 0,
      ),
    );
  }
}
