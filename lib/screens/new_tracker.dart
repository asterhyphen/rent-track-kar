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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
            Expanded(
              child: ListView(
                children:
                    users.map((u) => Text('• $u')).toList(),
              ),
            ),
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
                );

                final all = box.get('trackers', defaultValue: {});
                all[id] = tracker.toMap();
                box.put('trackers', all);

                Navigator.pop(context);
              },
              child: const Text('Create'),
            )
          ],
        ),
      ),
    );
  }
}
