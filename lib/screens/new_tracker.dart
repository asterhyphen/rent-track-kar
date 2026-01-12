import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'models.dart';
import 'dart:math';

class NewTrackerPage extends StatefulWidget {
  const NewTrackerPage({super.key});

  @override
  State<NewTrackerPage> createState() => _NewTrackerPageState();
}

class _NewTrackerPageState extends State<NewTrackerPage> {
  final titleCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final userCtrl = TextEditingController();

  final List<String> users = [];
  DateTime startDate = DateTime.now();
  DateTime dueDate = DateTime.now().add(const Duration(days: 5));
  int iconCode = Icons.receipt_long.codePoint;

  Future<void> pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate : dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          dueDate = picked;
        }
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
              decoration:
                  const InputDecoration(labelText: 'Tracker name'),
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
                  'Start: ${startDate.day}/${startDate.month}/${startDate.year}'),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () => pickDate(true),
            ),
            ListTile(
              title: Text(
                  'Due: ${dueDate.day}/${dueDate.month}/${dueDate.year}'),
              trailing: const Icon(Icons.event),
              onTap: () => pickDate(false),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: userCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Add user'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (userCtrl.text.isNotEmpty) {
                      setState(() {
                        users.add(userCtrl.text);
                        userCtrl.clear();
                      });
                    }
                  },
                )
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: users
                  .map((u) => Chip(label: Text(u)))
                  .toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final box = Hive.box('app');
                final id =
                    '${titleCtrl.text}_${Random().nextInt(9999)}';

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
            )
          ],
        ),
      ),
    );
  }
}
