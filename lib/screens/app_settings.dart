import 'package:flutter/material.dart';

class AppSettings {
  static const String defaultMessageTemplate = '''*_{title}_*
_Due:_ {dueDate} ({daysRemaining} days remaining)
_Total:_ ₹{total} (₹{perHead} each)

_Paid ({paidCount}; ₹{paidAmount})_
```
{paidUsers}
```

_Pending ({pendingCount}; ₹{pendingAmount})_
```
{pendingUsers}
```''';

  final String themeMode;
  final bool confirmDelete;
  final String messageTemplate;

  const AppSettings({
    required this.themeMode,
    required this.confirmDelete,
    required this.messageTemplate,
  });

  static const AppSettings defaults = AppSettings(
    themeMode: 'dark',
    confirmDelete: true,
    messageTemplate: defaultMessageTemplate,
  );

  factory AppSettings.fromMap(Map? map) {
    if (map == null) return defaults;
    return AppSettings(
      themeMode: _normalizeThemeMode(map['themeMode']),
      confirmDelete: map['confirmDelete'] is bool
          ? map['confirmDelete'] as bool
          : defaults.confirmDelete,
      messageTemplate: _normalizeMessageTemplate(map['messageTemplate']),
    );
  }

  AppSettings copyWith({
    String? themeMode,
    bool? confirmDelete,
    String? messageTemplate,
  }) {
    return AppSettings(
      themeMode: _normalizeThemeMode(themeMode ?? this.themeMode),
      confirmDelete: confirmDelete ?? this.confirmDelete,
      messageTemplate: _normalizeMessageTemplate(
        messageTemplate ?? this.messageTemplate,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode,
      'confirmDelete': confirmDelete,
      'messageTemplate': messageTemplate,
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

  static String _normalizeMessageTemplate(Object? value) {
    final template = (value ?? '').toString().trim();
    if (template.isEmpty) return defaultMessageTemplate;
    return template;
  }
}
