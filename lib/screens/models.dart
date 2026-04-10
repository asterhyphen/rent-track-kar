import 'package:flutter/material.dart';

String formatName(String input) {
  if (input.trim().isEmpty) return '';
  return input
      .trim()
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

DateTime recurringDueDateForMonth(DateTime template, DateTime month) {
  final lastDayOfMonth = DateTime(month.year, month.month + 1, 0).day;
  final targetDay = template.day.clamp(1, lastDayOfMonth);
  return DateTime(month.year, month.month, targetDay);
}

List<String> normalizeNames(Iterable<dynamic> values) {
  final seen = <String>{};
  final result = <String>[];

  for (final value in values) {
    final formatted = formatName('$value');
    if (formatted.isEmpty) continue;
    if (seen.add(formatted.toLowerCase())) {
      result.add(formatted);
    }
  }

  result.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return result;
}

class UserGroup {
  final String id;
  final String name;
  final List<String> members;

  const UserGroup({
    required this.id,
    required this.name,
    required this.members,
  });

  UserGroup copyWith({
    String? id,
    String? name,
    List<String>? members,
  }) {
    return UserGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      members: members ?? this.members,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'members': members,
  };

  static UserGroup fromMap(Map map) => UserGroup(
    id: '${map['id']}',
    name: formatName('${map['name']}'),
    members: normalizeNames(List<String>.from(map['members'] ?? const [])),
  );
}

class Tracker {
  final String id;
  final String title;
  final int? amount;
  final DateTime startDate;
  final DateTime dueDate;
  final List<String> users;
  final int iconCode;
  final bool archived;

  Tracker({
    required this.id,
    required this.title,
    required this.amount,
    required this.startDate,
    required this.dueDate,
    required this.users,
    required this.iconCode,
    required this.archived,
  });

  Tracker copyWith({
    String? title,
    int? amount,
    DateTime? dueDate,
    List<String>? users,
    int? iconCode,
    bool? archived,
  }) {
    return Tracker(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      startDate: startDate,
      dueDate: dueDate ?? this.dueDate,
      users: users == null ? this.users : normalizeNames(users),
      iconCode: iconCode ?? this.iconCode,
      archived: archived ?? this.archived,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'amount': amount,
    'startDate': startDate.toIso8601String(),
    'dueDate': dueDate.toIso8601String(),
    'users': users,
    'icon': iconCode,
    'archived': archived,
  };

  static Tracker fromMap(Map map) => Tracker(
    id: map['id'],
    title: formatName(map['title']),
    amount: map['amount'],
    startDate: DateTime.parse(map['startDate']),
    dueDate: DateTime.parse(map['dueDate']),
    users: normalizeNames(List<String>.from(map['users'] ?? const [])),
    iconCode: map['icon'] ?? Icons.receipt_long.codePoint,
    archived: map['archived'] == true,
  );
}
