import 'package:flutter/material.dart';

String formatName(String input) {
  if (input.trim().isEmpty) return '';
  final s = input.trim().toLowerCase();
  return s[0].toUpperCase() + s.substring(1);
}

class Tracker {
  final String id;
  final String title;
  final int? amount;
  final DateTime startDate;
  final DateTime dueDate;
  final List<String> users;
  final int iconCode;

  Tracker({
    required this.id,
    required this.title,
    required this.amount,
    required this.startDate,
    required this.dueDate,
    required this.users,
    required this.iconCode,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'startDate': startDate.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'users': users,
        'icon': iconCode,
      };

  static Tracker fromMap(Map map) => Tracker(
        id: map['id'],
        title: formatName(map['title']),
        amount: map['amount'],
        startDate: DateTime.parse(map['startDate']),
        dueDate: DateTime.parse(map['dueDate']),
        users: List<String>.from(map['users'])
            .map(formatName)
            .toList(),
        iconCode: map['icon'] ?? Icons.receipt_long.codePoint,
      );
}
