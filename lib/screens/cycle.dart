import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/glass_card.dart';
import 'models.dart';

class CyclePage extends StatefulWidget {
  final String trackerId;
  const CyclePage({super.key, required this.trackerId});

  @override
  State<CyclePage> createState() => _CyclePageState();
}

class _CyclePageState extends State<CyclePage> {
  final box = Hive.box('app');

  late Tracker tracker;
  late Map<String, bool> paid;
  int total = 0;
  DateTime? due;

  String get monthKey =>
      '${DateTime.now().year}-${DateTime.now().month}';

  @override
  void initState() {
    super.initState();
    final raw = box.get('trackers')[widget.trackerId];
    tracker = Tracker.fromMap(raw);

    paid = {for (var u in tracker.users) u: false};

    final saved = box.get('${tracker.id}_$monthKey');
    if (saved != null) {
      paid = Map<String, bool>.from(saved['paid']);
      total = saved['total'];
      if (saved['due'] != null) {
        due = DateTime.parse(saved['due']);
      }
    } else {
      total = tracker.amount ?? 0;
      due = tracker.dueDate;
    }
  }

  void persist() {
    box.put('${tracker.id}_$monthKey', {
      'paid': paid,
      'total': total,
      'due': due?.toIso8601String(),
    });
  }

  String message() {
    final per =
        tracker.users.isEmpty ? 0 : (total / tracker.users.length).round();

    return '''
${tracker.title}

Total: ₹$total (₹$per each)
${due != null ? 'Due: ${due!.day}/${due!.month}' : ''}

${tracker.users.map((u) => paid[u]! ? '✅ $u' : '❌ $u').join('\n')}
''';
  }

  @override
  Widget build(BuildContext context) {
    final allPaid = paid.values.every((e) => e);

    return Scaffold(
      appBar: AppBar(title: Text(tracker.title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Share.share(message()),
        label: const Text('Send update'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (tracker.amount == null && total == 0)
              TextField(
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Total'),
                onChanged: (v) {
                  total = int.tryParse(v) ?? 0;
                  persist();
                },
              ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: tracker.users.map((u) {
                  return GlassCard(
                    onTap: allPaid
                        ? null
                        : () {
                            setState(() => paid[u] = !paid[u]!);
                            persist();
                          },
                    child: Row(
                      children: [
                        Icon(
                          paid[u]!
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: paid[u]!
                              ? Colors.greenAccent
                              : Colors.white54,
                        ),
                        const SizedBox(width: 16),
                        Text(u),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
