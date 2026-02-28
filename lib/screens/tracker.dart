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
    final peopleCount = users.length;
    final baseAmount = int.tryParse(amountCtrl.text) ?? 0;
    final perHead = peopleCount == 0 ? 0 : (baseAmount / peopleCount).ceil();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Tracker')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF10192B), Color(0xFF090F1B)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(),
              children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tracker name',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (optional)',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _dateTile(
                      icon: Icons.calendar_month,
                      label: 'Start Date',
                      value:
                          '${startDate.day}/${startDate.month}/${startDate.year}',
                      onTap: () => pickDate(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dateTile(
                      icon: Icons.event,
                      label: 'Due Date',
                      value: '${dueDate.day}/${dueDate.month}/${dueDate.year}',
                      onTap: () => pickDate(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: userCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Add user',
                        prefixIcon: Icon(Icons.person_add_alt_1),
                      ),
                      onSubmitted: (_) => _addUser(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    icon: const Icon(Icons.add),
                    onPressed: _addUser,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: users
                    .map(
                      (u) => Chip(
                        label: Text(u),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => setState(() => users.remove(u)),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Per Head'),
                    Text(
                      peopleCount == 0 || baseAmount == 0
                          ? 'Add amount & users'
                          : '₹$perHead each',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Pick Icon',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: trackerIcons.entries.map((e) {
                  final selected = iconCode == e.value.codePoint;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        iconCode = e.value.codePoint;
                        iconManuallySelected = true;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: selected
                            ? const Color(0xFF00B894)
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                      child: Icon(
                        e.value,
                        color: selected ? Colors.black : Colors.white,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _createTracker,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Create Tracker'),
                ),
              ),
              const SizedBox(height: 24),
            ],
            ),
          ),
        ),
      ),
    );
  }

  void _addUser() {
    if (userCtrl.text.trim().isEmpty) return;
    final formatted = formatName(userCtrl.text);
    if (formatted.isEmpty || users.contains(formatted)) {
      userCtrl.clear();
      return;
    }

    setState(() {
      users.add(formatted);
      users.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      userCtrl.clear();
    });
  }

  Widget _dateTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  void _createTracker() {
    final box = Hive.box('app');
    final id = '${titleCtrl.text}_${Random().nextInt(9999)}';

    final tracker = Tracker(
      id: id,
      title: titleCtrl.text,
      amount: int.tryParse(amountCtrl.text),
      startDate: startDate,
      dueDate: dueDate,
      users: List<String>.from(
        users,
      )..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())),
      iconCode: iconCode,
    );

    final all = box.get('trackers', defaultValue: {});
    all[id] = tracker.toMap();
    box.put('trackers', all);
    Navigator.pop(context);
  }
}
