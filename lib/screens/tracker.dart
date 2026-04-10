import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../services/notification_service.dart';
import '../widgets/app_alert.dart';
import 'models.dart';

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
  DateTime dueDate = DateTime.now();
  bool isConstantBill = false;

  int iconCode = Icons.receipt_long.codePoint;
  bool iconManuallySelected = false;

  List<String> get _savedUsers {
    final raw = Hive.box('app').get('savedUsers', defaultValue: <String>[]) as List;
    return normalizeNames(raw);
  }

  List<UserGroup> get _savedGroups {
    final raw =
        Hive.box('app').get('userGroups', defaultValue: <String, dynamic>{})
            as Map;
    return raw.values.map((value) => UserGroup.fromMap(value)).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final savedUsers = _savedUsers;
    final savedGroups = _savedGroups;
    final peopleCount = users.length;
    final baseAmount = isConstantBill ? int.tryParse(amountCtrl.text) ?? 0 : 0;
    final perHead = peopleCount == 0 ? 0 : (baseAmount / peopleCount).ceil();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Tracker')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF10192B), Color(0xFF090F1B)]
                : const [Color(0xFFF9FCFE), Color(0xFFEAF2F7)],
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Variable Bill'),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Constant Bill'),
                      ),
                    ],
                    selected: {isConstantBill},
                    multiSelectionEnabled: false,
                    showSelectedIcon: false,
                    onSelectionChanged: (selected) {
                      setState(() {
                        isConstantBill = selected.first;
                        if (!isConstantBill) {
                          amountCtrl.clear();
                        }
                      });
                    },
                  ),
                ),
                if (isConstantBill) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
                const SizedBox(height: 14),
                if (savedGroups.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        'Quick Add Groups',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: savedGroups.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final group = savedGroups[index];
                        final allAdded = group.members.every(users.contains);
                        return InkWell(
                          onTap: () => _addUsers(group.members),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: 180,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: allAdded
                                  ? colorScheme.primary.withValues(
                                      alpha: isDark ? 0.16 : 0.12,
                                    )
                                  : (isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : Colors.white.withValues(alpha: 0.82)),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: allAdded
                                    ? colorScheme.primary.withValues(alpha: 0.4)
                                    : (isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : const Color(0xFFD9E6EF)),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.groups_rounded,
                                      color: allAdded
                                          ? colorScheme.primary
                                          : colorScheme.onSurface,
                                    ),
                                    const Spacer(),
                                    Icon(
                                      allAdded
                                          ? Icons.check_circle
                                          : Icons.add_circle_outline,
                                      size: 18,
                                      color: allAdded
                                          ? colorScheme.primary
                                          : colorScheme.onSurface.withValues(
                                              alpha: 0.64,
                                            ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  group.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${group.members.length} member${group.members.length == 1 ? '' : 's'}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.68,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                if (savedUsers.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        'Pick Saved Users',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: savedUsers.map((savedUser) {
                      final added = users.contains(savedUser);
                      return FilterChip(
                        label: Text(savedUser),
                        selected: added,
                        onSelected: (selected) {
                          if (selected) {
                            _addUsers([savedUser]);
                          } else {
                            setState(() => users.remove(savedUser));
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                ],
                Row(
                  children: [
                    Expanded(
                      child: _dateTile(
                        context: context,
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
                        context: context,
                        icon: Icons.event,
                        label: 'Recurring Due Date',
                        value:
                            '${dueDate.day}/${dueDate.month}/${dueDate.year}',
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
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.white.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : const Color(0xFFD9E6EF),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Per Head'),
                      Text(
                        !isConstantBill
                            ? 'Set monthly total later'
                            : peopleCount == 0 || baseAmount == 0
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
                const SizedBox(height: 10),
                Text(
                  'The selected due date repeats automatically every month.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.66),
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
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : const Color(0xFFF0F5F9)),
                        ),
                        child: Icon(
                          e.value,
                          color: selected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
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
    final formatted = formatName(userCtrl.text);
    if (formatted.isEmpty) return;
    _addUsers([formatted], clearInput: true);
  }

  void _addUsers(List<String> newUsers, {bool clearInput = false}) {
    final merged = normalizeNames([...users, ...newUsers]);
    if (merged.length == users.length) {
      if (clearInput) {
        userCtrl.clear();
      }
      return;
    }

    setState(() {
      users
        ..clear()
        ..addAll(merged);
      if (clearInput) {
        userCtrl.clear();
      }
    });
  }

  Widget _dateTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : const Color(0xFFD9E6EF),
          ),
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
    if (titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a tracker name.')),
      );
      return;
    }

    if (isConstantBill && (int.tryParse(amountCtrl.text) ?? 0) <= 0) {
      showAppAlert(
        context,
        message: 'Enter an amount for a constant bill.',
        icon: Icons.info_outline,
      );
      return;
    }

    final box = Hive.box('app');
    // use timestamp to generate a more collision-resistant id
    final id = '${titleCtrl.text}_${DateTime.now().millisecondsSinceEpoch}';

    final tracker = Tracker(
      id: id,
      title: titleCtrl.text,
      amount: isConstantBill ? int.tryParse(amountCtrl.text) : null,
      startDate: startDate,
      dueDate: dueDate,
      users: List<String>.from(users)
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())),
      iconCode: iconCode,
      archived: false,
    );

    final all = box.get('trackers', defaultValue: {});
    all[id] = tracker.toMap();
    box.put('trackers', all);
    NotificationService.instance.syncForAllTrackers(box);
    showAppAlert(context, message: 'Tracker created.');
    Navigator.pop(context);
  }
}
