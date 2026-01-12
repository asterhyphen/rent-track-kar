import 'package:flutter/material.dart';

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
  title: map['title'],
  amount: map['amount'],
  startDate: DateTime.parse(map['startDate']),
  dueDate: DateTime.parse(map['dueDate']),
  users: List<String>.from(map['users']),
  iconCode: map['icon'] ?? Icons.receipt_long.codePoint,
);

}
