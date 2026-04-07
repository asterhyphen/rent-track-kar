import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../widgets/glass_card.dart';
import 'app_settings.dart';
import 'cycle.dart';
import 'models.dart';
import 'settings.dart';
import 'tracker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final box = Hive.box('app');

  @override
  Widget build(BuildContext context) {
    final raw = box.get('trackers', defaultValue: {}) as Map;
    final trackers = raw.values.map((e) => Tracker.fromMap(e)).toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    final settings = AppSettings.fromMap(box.get('settings'));
    final monthKey = '${DateTime.now().year}-${DateTime.now().month}';
    final totalMembers = _userCount(trackers);
    final paidMembers = _paidUserCount(trackers, monthKey);
    final activeTrackers = _activeCount(trackers, monthKey);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trackers',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Tracker'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TrackerPage()),
          );
          if (mounted) setState(() {});
        },
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF111A2B), Color(0xFF090F1B)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: trackers.isEmpty
                ? const Center(child: _EmptyState())
                : Column(
                    children: [
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF00B894,
                                    ).withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.analytics_outlined,
                                    color: Color(0xFF77FFD8),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Rent Track Kar',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Track this month at a glance',
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                _statTile(
                                  context,
                                  label: 'Total',
                                  value: '${trackers.length}',
                                ),
                                const SizedBox(width: 12),
                                _statTile(
                                  context,
                                  label: 'Live',
                                  value: '$activeTrackers',
                                ),
                                const SizedBox(width: 12),
                                _statTile(
                                  context,
                                  label: 'Users',
                                  value: '$totalMembers',
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.08,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.task_alt,
                                      color: Color(0xFF77FFD8),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'This month collection',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.white60,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$paidMembers/$totalMembers paid',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    totalMembers == 0
                                        ? '0%'
                                        : '${((paidMembers / totalMembers) * 100).round()}%',
                                    style: const TextStyle(
                                      color: Color(0xFF77FFD8),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: trackers.length,
                          padding: const EdgeInsets.only(bottom: 88),
                          itemBuilder: (c, i) {
                            final tracker = trackers[i];
                            final monthlyKey = '${tracker.id}_$monthKey';
                            final active = box.containsKey(monthlyKey);
                            final monthlyData = active
                                ? Map<String, dynamic>.from(box.get(monthlyKey))
                                : null;
                            final paidCount = monthlyData == null
                                ? 0
                                : Map<String, dynamic>.from(
                                    monthlyData['paid'] ?? <String, dynamic>{},
                                  ).values.where((value) => value == true).length;
                            final totalCount = tracker.users.length;
                            final progress = totalCount == 0
                                ? 0.0
                                : paidCount / totalCount;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Dismissible(
                                key: ValueKey(tracker.id),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (_) async {
                                  if (!settings.confirmDelete) return true;
                                  return await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Delete tracker?'),
                                          content: const Text(
                                            'Are you sure you want to delete this tracker? This action is irreversible.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      ) ??
                                      false;
                                },
                                onDismissed: (_) {
                                  final all = box.get('trackers');
                                  all.remove(tracker.id);
                                  box.put('trackers', all);
                                  setState(() {});
                                },
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 24),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                child: GlassCard(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CyclePage(trackerId: tracker.id),
                                      ),
                                    );
                                    if (mounted) setState(() {});
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 52,
                                            height: 52,
                                            decoration: BoxDecoration(
                                              color: active
                                                  ? const Color(
                                                      0xFF00B894,
                                                    ).withValues(alpha: 0.95)
                                                  : Colors.white10,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Icon(
                                              IconData(
                                                tracker.iconCode,
                                                fontFamily: 'MaterialIcons',
                                              ),
                                              color: active
                                                  ? Colors.black
                                                  : Colors.white70,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  tracker.title,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  active
                                                      ? '$paidCount/$totalCount paid'
                                                      : 'Not started this month',
                                                  style: TextStyle(
                                                    color: active
                                                        ? const Color(
                                                            0xFF77FFD8,
                                                          )
                                                        : Colors.white54,
                                                    fontWeight: active
                                                        ? FontWeight.w600
                                                        : FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.chevron_right),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          _chipLabel(
                                            icon: Icons.people_alt_outlined,
                                            label:
                                                '$totalCount member${totalCount == 1 ? '' : 's'}',
                                          ),
                                          const SizedBox(width: 8),
                                          _chipLabel(
                                            icon: Icons.calendar_month_outlined,
                                            label: active ? 'Active' : 'Pending',
                                            highlighted: active,
                                          ),
                                        ],
                                      ),
                                      if (active) ...[
                                        const SizedBox(height: 14),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          child: LinearProgressIndicator(
                                            minHeight: 8,
                                            value: progress,
                                            backgroundColor: Colors.white12,
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                  Color
                                                >(Color(0xFF3ED9A6)),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  int _activeCount(List<Tracker> trackers, String monthKey) {
    return trackers.where((t) => box.containsKey('${t.id}_$monthKey')).length;
  }

  int _userCount(List<Tracker> trackers) {
    return trackers.fold<int>(0, (sum, t) => sum + t.users.length);
  }

  int _paidUserCount(List<Tracker> trackers, String monthKey) {
    var total = 0;

    for (final tracker in trackers) {
      final monthlyData = box.get('${tracker.id}_$monthKey');
      if (monthlyData == null) continue;

      final paidMap = Map<String, dynamic>.from(
        monthlyData['paid'] ?? <String, dynamic>{},
      );
      total += paidMap.values.where((value) => value == true).length;
    }

    return total;
  }

  Widget _statTile(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipLabel({
    required IconData icon,
    required String label,
    bool highlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted
            ? const Color(0xFF00B894).withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlighted
              ? const Color(0xFF00E0B2).withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: highlighted ? const Color(0xFF77FFD8) : Colors.white70,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: highlighted ? const Color(0xFF77FFD8) : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.track_changes_outlined, size: 54, color: Colors.white70),
        SizedBox(height: 10),
        Text(
          'No trackers yet.\nTap Add Tracker to get started.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
