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

  int get perHead => tracker.users.isEmpty ? 0 : (total / tracker.users.length).ceil();

  void setAllPaid(bool value) {
    setState(() {
      for (final user in tracker.users) {
        paid[user] = value;
      }
      persist();
    });
  }

  @override
  void initState() {
    super.initState();
    tracker = Tracker.fromMap(box.get('trackers')[widget.trackerId]);

    tracker = tracker.copyWith(
      users: List<String>.from(tracker.users)
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())),
    );

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
    final amountCtrl = TextEditingController(
      text: tracker.amount?.toString() ?? '',
    );
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
                decoration: const InputDecoration(labelText: 'Tracker name'),
              ),

              if (tracker.amount == null)
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount'),
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
                    setModal(() {
                      users.add(formatName(v));
                      users.sort(
                        (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
                      );
                    });
                    paid[formatName(v)] = false;
                  }
                },
              ),

              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: trackerIcons.entries.map((e) {
                  final selected = icon == e.value.codePoint;
                  return GestureDetector(
                    onTap: () => setModal(() => icon = e.value.codePoint),
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
                      users: List<String>.from(users)
                        ..sort(
                          (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
                        ),
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
    final per = tracker.users.isEmpty ? 0 : (total / tracker.users.length).ceil();

    final paidUsers = tracker.users.where((u) => paid[u] == true).toList()
      ..sort();
    final pendingUsers = tracker.users.where((u) => paid[u] != true).toList()
      ..sort();

    final now = DateTime.now();
    final daysRemaining = due!
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;

    // the message
    return '''
*_${tracker.title}_*
_Due:_ ${due!.day}/${due!.month}/${due!.year} ($daysRemaining days remaining)
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
    final totalUsers = tracker.users.length;
    final paidCount = tracker.users.where((u) => paid[u] == true).length;
    final pendingCount = tracker.users.length - paidCount;
    final paidAmount = paidCount * perHead;
    final pendingAmount = pendingCount * perHead;
    final paidProgress = totalUsers == 0 ? 0.0 : paidCount / totalUsers;
    final allPaid = totalUsers > 0 && paidCount == totalUsers;
    final today = DateTime.now();
    final dueDateOnly = DateTime(due!.year, due!.month, due!.day);
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final daysRemaining = dueDateOnly.difference(todayDateOnly).inDays;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(IconData(tracker.iconCode, fontFamily: 'MaterialIcons')),
            const SizedBox(width: 12),
            Text(tracker.title),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: openEditTracker),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Share.share(message()),
        icon: const Icon(Icons.share),
        label: const Text('Share'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF111A2B), Color(0xFF090F1B)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(),
            children: [
              GlassCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('Total', style: TextStyle(color: Colors.white70)),
                        const Spacer(),
                        Text(
                          '₹$total',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Per Head', style: TextStyle(color: Colors.white70)),
                        const Spacer(),
                        Text(
                          '₹$perHead',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF77FFD8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'Progress',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const Spacer(),
                        Text(
                          '${(paidProgress * 100).round()}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3ED9A6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 10,
                        value: paidProgress,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF3ED9A6),
                        ),
                      ),
                    ),
                    if (tracker.amount == null) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: totalController,
                        keyboardType: TextInputType.number,
                        readOnly: !editingTotal,
                        decoration: InputDecoration(
                          labelText: 'Update total',
                          prefixText: '₹ ',
                          suffixIcon: IconButton(
                            icon: Icon(editingTotal ? Icons.check : Icons.edit),
                            onPressed: () {
                              setState(() {
                                if (editingTotal) {
                                  total = int.tryParse(totalController.text) ?? total;
                                  persist();
                                }
                                editingTotal = !editingTotal;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _miniStat(
                      title: 'Paid',
                      value: '$paidCount',
                      subValue: '₹$paidAmount',
                      tint: const Color(0xFF3ED9A6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _miniStat(
                      title: 'Pending',
                      value: '$pendingCount',
                      subValue: '₹$pendingAmount',
                      tint: const Color(0xFFFFB85C),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _miniStat(
                      title: 'Due',
                      value: _dueText(daysRemaining),
                      subValue: '${due!.day}/${due!.month}',
                      tint: daysRemaining < 0
                          ? const Color(0xFFFF6E6E)
                          : const Color(0xFF8CCBFF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: totalUsers == 0
                          ? null
                          : () => setAllPaid(!allPaid),
                      icon: Icon(
                        allPaid
                            ? Icons.restart_alt_rounded
                            : Icons.done_all_rounded,
                      ),
                      label: Text(allPaid ? 'Reset all' : 'Paid all'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...tracker.users.map((u) {
                final isPaid = paid[u] == true;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    onTap: () {
                      setState(() => paid[u] = !paid[u]!);
                      persist();
                    },
                    child: Row(
                      children: [
                        Icon(
                          isPaid
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isPaid
                              ? const Color(0xFF3ED9A6)
                              : Colors.white54,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isPaid ? 'Paid' : 'Pending',
                                style: TextStyle(
                                  color: isPaid
                                      ? const Color(0xFF3ED9A6)
                                      : const Color(0xFFFFB85C),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹$perHead',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 88),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat({
    required String title,
    required String value,
    required String subValue,
    required Color tint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tint.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(subValue, style: TextStyle(color: tint, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _dueText(int daysRemaining) {
    if (daysRemaining == 0) return 'Today';
    if (daysRemaining == 1) return '1 day';
    if (daysRemaining > 1) return '$daysRemaining days';
    if (daysRemaining == -1) return 'Over 1d';
    return 'Over ${daysRemaining.abs()}d';
  }
}
