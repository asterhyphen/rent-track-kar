import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../services/notification_service.dart';
import '../widgets/app_alert.dart';
import '../widgets/glass_card.dart';
import 'models.dart';

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key});

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  final box = Hive.box('app');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final raw = box.get('trackkars', defaultValue: {}) as Map;
    final trackkars = raw.values
        .map((e) => Tracker.fromMap(e))
        .where((tracker) => tracker.archived)
        .toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    return Scaffold(
      appBar: AppBar(title: const Text('Archive')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF111A2B), Color(0xFF090F1B)]
                : const [Color(0xFFF9FCFE), Color(0xFFEAF2F7)],
          ),
        ),
        child: SafeArea(
          child: trackkars.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No archived trackkars yet.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: trackkars.length,
                  itemBuilder: (context, index) {
                    final tracker = trackkars[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white10
                                    : const Color(0xFFE8EFF5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                IconData(
                                  tracker.iconCode,
                                  fontFamily: 'MaterialIcons',
                                ),
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.72,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tracker.title,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${tracker.users.length} member${tracker.users.length == 1 ? '' : 's'}',
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.64,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : const Color(0xFFF1F6FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : const Color(0xFFD9E6EF),
                                  ),
                                ),
                                child: Icon(
                                  Icons.more_horiz,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.76,
                                  ),
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              color: isDark
                                  ? const Color(0xFF142033)
                                  : Colors.white,
                              onSelected: (value) {
                                if (value == 'restore') {
                                  _updateTracker(
                                    tracker.copyWith(archived: false),
                                  );
                                } else if (value == 'delete') {
                                  _deleteTracker(tracker.id);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem<String>(
                                  value: 'restore',
                                  child: Text('Restore'),
                                ),
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  void _updateTracker(Tracker tracker) {
    final all = box.get('trackkars', defaultValue: {}) as Map;
    all[tracker.id] = tracker.toMap();
    box.put('trackkars', all);
    NotificationService.instance.syncForAllTrackers(box);
    setState(() {});
    showAppAlert(context, message: '${tracker.title} restored.');
  }

  void _deleteTracker(String trackerId) {
    final all = box.get('trackkars', defaultValue: {}) as Map;
    final tracker = all[trackerId] != null ? Tracker.fromMap(all[trackerId]) : null;
    all.remove(trackerId);
    box.put('trackkars', all);
    NotificationService.instance.syncForAllTrackers(box);
    setState(() {});
    showAppAlert(
      context,
      message: tracker == null ? 'Tracker deleted.' : '${tracker.title} deleted.',
      icon: Icons.delete_outline,
    );
  }
}
