import 'package:flutter/material.dart';

class AppSettings {
  final String themeMode;
  final bool confirmDelete;
  final int defaultDueDays;

  const AppSettings({
    required this.themeMode,
    required this.confirmDelete,
    required this.defaultDueDays,
  });

  static const AppSettings defaults = AppSettings(
    themeMode: 'dark',
    confirmDelete: true,
    defaultDueDays: 5,
  );

  factory AppSettings.fromMap(Map? map) {
    if (map == null) return defaults;
    return AppSettings(
      themeMode: _normalizeThemeMode(map['themeMode']),
      confirmDelete: map['confirmDelete'] is bool
          ? map['confirmDelete'] as bool
          : defaults.confirmDelete,
      defaultDueDays: _normalizeDueDays(map['defaultDueDays']),
    );
  }

  AppSettings copyWith({
    String? themeMode,
    bool? confirmDelete,
    int? defaultDueDays,
  }) {
    return AppSettings(
      themeMode: _normalizeThemeMode(themeMode ?? this.themeMode),
      confirmDelete: confirmDelete ?? this.confirmDelete,
      defaultDueDays: _normalizeDueDays(defaultDueDays ?? this.defaultDueDays),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode,
      'confirmDelete': confirmDelete,
      'defaultDueDays': defaultDueDays,
    };
  }

  ThemeMode get materialThemeMode {
    switch (themeMode) {
      case 'system':
        return ThemeMode.system;
      case 'light':
        return ThemeMode.light;
      case 'dark':
      default:
        return ThemeMode.dark;
    }
  }

  static String _normalizeThemeMode(Object? value) {
    final mode = (value ?? '').toString().toLowerCase();
    if (mode == 'system' || mode == 'light' || mode == 'dark') return mode;
    return defaults.themeMode;
  }

  static int _normalizeDueDays(Object? value) {
    final days = value is int ? value : int.tryParse('${value ?? ''}');
    if (days == null) return defaults.defaultDueDays;
    return days.clamp(1, 30);
  }
}
