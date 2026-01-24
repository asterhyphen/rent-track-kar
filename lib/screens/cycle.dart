import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/glass_card.dart';
import 'models.dart';
import 'tracker.dart';

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

  late TextEditingController totalController;
  bool editingTotal = false;

  String get monthKey => '${DateTime.now().year}-${DateTime.now().month}';

  @override
  void initState() {
    super.initState();
    tracker = Tracker.fromMap(box.get('trackers')[widget.trackerId]);

    paid = {for (var u in tracker.users) u: false};

    final saved = box.get('${tracker.id}_$monthKey');
    if (saved != null) {
      paid = Map<String, bool>.from(saved['paid']);
      total = saved['total'];
      due = saved['due'] != null
          ? DateTime.parse(saved['due'])
          : tracker.dueDate;
    } else {
      total = tracker.amount ?? 0;
      due = tracker.dueDate;
    }

    totalController = TextEditingController(text: total.toString());
  }

  void persist() {
    box.put('${tracker.id}_$monthKey', {
      'paid': paid,
      'total': total,
      'due': due?.toIso8601String(),
    });
  }

  void persistTracker() {
    final all = box.get('trackers');
    all[tracker.id] = tracker.toMap();
    box.put('trackers', all);
  }

  void openEditTracker() {
    final titleCtrl = TextEditingController(text: tracker.title);
    final amountCtrl =
        TextEditingController(text: tracker.amount?.toString() ?? '');
    final users = List<String>.from(tracker.users);
    DateTime newDue = due ?? tracker.dueDate;
    int icon = tracker.iconCode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (context, setModal) => ListView(
            shrinkWrap: true,
            children: [
              TextField(
                controller: titleCtrl,
                decoration:
                    const InputDecoration(labelText: 'Tracker name'),
              ),

              if (tracker.amount == null)
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Amount'),
                ),

              ListTile(
                title: Text(
                  'Due: ${newDue.day}/${newDue.month}/${newDue.year}',
                ),
                trailing: const Icon(Icons.event),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: newDue,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setModal(() => newDue = picked);
                  }
                },
              ),

              const SizedBox(height: 8),
              const Text('Users'),
              Wrap(
                spacing: 8,
                children: users
                    .map(
                      (u) => Chip(
                        label: Text(u),
                        onDeleted: () {
                          setModal(() => users.remove(u));
                          paid.remove(u);
                        },
                      ),
                    )
                    .toList(),
              ),

              TextField(
                decoration: const InputDecoration(labelText: 'Add user'),
                onSubmitted: (v) {
                  if (v.isNotEmpty && !users.contains(v)) {
                    setModal(() => users.add(v));
                    paid[v] = false;
                  }
                },
              ),

              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: trackerIcons.entries.map((e) {
                  final selected = icon == e.value.codePoint;
                  return GestureDetector(
                    onTap: () => setModal(
                      () => icon = e.value.codePoint,
                    ),
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

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    tracker = tracker.copyWith(
                      title: titleCtrl.text,
                      amount: int.tryParse(amountCtrl.text),
                      dueDate: newDue,
                      users: users,
                      iconCode: icon,
                    );
                    due = newDue;
                    total = tracker.amount ?? total;
                  });

                  persist();
                  persistTracker();
                  Navigator.pop(context);
                },
                child: const Text('Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String message() {
    final per =
        tracker.users.isEmpty ? 0 : (total / tracker.users.length).round();

    final paidUsers =
        tracker.users.where((u) => paid[u] == true).toList()..sort();
    final pendingUsers =
        tracker.users.where((u) => paid[u] != true).toList()..sort();

    final now = DateTime.now();
    final daysRemaining =
        due!.difference(DateTime(now.year, now.month, now.day)).inDays;

    // the message
    return '''
*_${tracker.title}_*
_Due:_ ${due!.day}/${due!.month}/${due!.year} (${daysRemaining} days remaining)
_Total:_ ₹$total (₹$per each)

_Paid (${paidUsers.length}; ₹${paidUsers.length * per})_
```
${paidUsers.join('\n')}
```

_Pending (${pendingUsers.length}; ₹${pendingUsers.length * per})_
```
${pendingUsers.join('\n')}
```
''';
  }

  @override
  Widget build(BuildContext context) {
    final allPaid = paid.values.every((e) => e);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(IconData(tracker.iconCode,
                fontFamily: 'MaterialIcons')),
            const SizedBox(width: 12),
            Text(tracker.title),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: openEditTracker,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Share.share(message()),
        label: const Text('Share'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (tracker.amount == null)
              TextField(
                controller: totalController,
                keyboardType: TextInputType.number,
                readOnly: !editingTotal,
                decoration: InputDecoration(
                  labelText: 'Total',
                  prefixText: '₹ ',
                  suffixIcon: IconButton(
                    icon: Icon(
                        editingTotal ? Icons.check : Icons.edit),
                    onPressed: () {
                      setState(() {
                        if (editingTotal) {
                          total = int.tryParse(
                                  totalController.text) ??
                              total;
                          persist();
                        }
                        editingTotal = !editingTotal;
                      });
                    },
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: tracker.users.map((u) {
                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      onTap: allPaid
                          ? null
                          : () {
                              setState(
                                  () => paid[u] = !paid[u]!);
                              persist();
                            },
                      child: Row(
                        children: [
                          Icon(
                            paid[u]!
                                ? Icons.check_circle
                                : Icons
                                    .radio_button_unchecked,
                            color: paid[u]!
                                ? Colors.greenAccent
                                : Colors.white54,
                          ),
                          const SizedBox(width: 16),
                          Text(u),
                        ],
                      ),
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