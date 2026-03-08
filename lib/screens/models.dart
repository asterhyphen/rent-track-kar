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

  Tracker copyWith({
    String? title,
    int? amount,
    DateTime? dueDate,
    List<String>? users,
    int? iconCode,
  }) {
    return Tracker(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      startDate: startDate,
      dueDate: dueDate ?? this.dueDate,
      users: users ?? this.users,
      iconCode: iconCode ?? this.iconCode,
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
  };

  static Tracker fromMap(Map map) => Tracker(
    id: map['id'],
    title: formatName(map['title']),
    amount: map['amount'],
    startDate: DateTime.parse(map['startDate']),
    dueDate: DateTime.parse(map['dueDate']),
    users: List<String>.from(map['users']).map(formatName).toList(),
    iconCode: map['icon'] ?? Icons.receipt_long.codePoint,
  );
}
