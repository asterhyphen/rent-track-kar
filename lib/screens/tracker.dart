import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'models.dart';
import 'dart:math';

const trackerIcons = {
  'Bill': Icons.receipt_long,
  'Electricity': Icons.bolt,
  'Rent': Icons.home,
  'Music': Icons.music_note,
  'Movies': Icons.movie,
  'Internet': Icons.wifi,
  'Food': Icons.restaurant,
};

int autoIconFromText(String text) {
  final t = text.toLowerCase();

  if (RegExp(r'\b(electric|electricity|power|current|bill)\b').hasMatch(t)) {
    return Icons.bolt.codePoint;
  }
  if (RegExp(r'\b(rent|house|home|flat|room)\b').hasMatch(t)) {
    return Icons.home.codePoint;
  }
  if (RegExp(r'\b(wifi|internet|broadband|fiber|network)\b').hasMatch(t)) {
    return Icons.wifi.codePoint;
  }
  if (RegExp(r'\b(music|spotify|song|playlist)\b').hasMatch(t)) {
    return Icons.music_note.codePoint;
  }
  if (RegExp(r'\b(movie|film|cinema|netflix|prime)\b').hasMatch(t)) {
    return Icons.movie.codePoint;
  }
  if (RegExp(r'\b(food|lunch|dinner|meal|restaurant)\b').hasMatch(t)) {
    return Icons.restaurant.codePoint;
  }

  return Icons.receipt_long.codePoint;
}

class TrackerPage extends StatefulWidget {
  const TrackerPage({super.key});

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
  final titleCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final userCtrl = TextEditingController();

  final List<String> users = [];
  DateTime startDate = DateTime.now();
  DateTime dueDate = DateTime.now().add(const Duration(days: 5));

  int iconCode = Icons.receipt_long.codePoint;
  bool iconManuallySelected = false;

  @override
  void initState() {
    super.initState();

    titleCtrl.addListener(() {
      if (!iconManuallySelected) {
        setState(() {
          iconCode = autoIconFromText(titleCtrl.text);
        });
      }
    });
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    amountCtrl.dispose();
    userCtrl.dispose();
    super.dispose();
  }

  Future<void> pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate : dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        isStart ? startDate = picked : dueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Tracker name'),
            ),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (leave empty if variable)',
              ),
            ),
            ListTile(
              title: Text(
                'Start: ${startDate.day}/${startDate.month}/${startDate.year}',
              ),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () => pickDate(true),
            ),
            ListTile(
              title: Text(
                'Due: ${dueDate.day}/${dueDate.month}/${dueDate.year}',
              ),
              trailing: const Icon(Icons.event),
              onTap: () => pickDate(false),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: userCtrl,
                    decoration: const InputDecoration(labelText: 'Add user'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (userCtrl.text.isNotEmpty) {
                      setState(() {
                        users.add(formatName(userCtrl.text));
                        userCtrl.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: users.map((u) => Chip(label: Text(u))).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Icon'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: trackerIcons.entries.map((e) {
                final selected = iconCode == e.value.codePoint;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      iconCode = e.value.codePoint;
                      iconManuallySelected = true;
                    });
                  },
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: selected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white12,
                    child: Icon(
                      e.value,
                      color: selected ? Colors.black : Colors.white,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final box = Hive.box('app');
                final id = '${titleCtrl.text}_${Random().nextInt(9999)}';

                final tracker = Tracker(
                  id: id,
                  title: titleCtrl.text,
                  amount: int.tryParse(amountCtrl.text),
                  startDate: startDate,
                  dueDate: dueDate,
                  users: users,
                  iconCode: iconCode,
                );

                final all = box.get('trackers', defaultValue: {});
                all[id] = tracker.toMap();
                box.put('trackers', all);

                Navigator.pop(context);
              },
              child: const Text('Create Tracker'),
            ),
          ],
        ),
      ),
    );
  }
}
