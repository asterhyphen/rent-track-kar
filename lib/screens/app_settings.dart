import 'package:flutter/material.dart';

class AppSettings {
  final String themeMode;
  final bool confirmDelete;

  const AppSettings({
    required this.themeMode,
    required this.confirmDelete,
  });

  static const AppSettings defaults = AppSettings(
    themeMode: 'dark',
    confirmDelete: true,
  );

  factory AppSettings.fromMap(Map? map) {
    if (map == null) return defaults;
    return AppSettings(
      themeMode: _normalizeThemeMode(map['themeMode']),
      confirmDelete: map['confirmDelete'] is bool
          ? map['confirmDelete'] as bool
          : defaults.confirmDelete,
    );
  }

  AppSettings copyWith({
    String? themeMode,
    bool? confirmDelete,
  }) {
    return AppSettings(
      themeMode: _normalizeThemeMode(themeMode ?? this.themeMode),
      confirmDelete: confirmDelete ?? this.confirmDelete,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode,
      'confirmDelete': confirmDelete,
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
}
