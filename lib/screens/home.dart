import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../services/notification_service.dart';
import '../widgets/app_alert.dart';
import '../widgets/glass_card.dart';
import 'app_settings.dart';
import 'cycle.dart';
import 'models.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final box = Hive.box('app');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final raw = box.get('trackers', defaultValue: {}) as Map;
    final trackers = raw.values
        .map((e) => Tracker.fromMap(e))
        .where((tracker) => !tracker.archived)
        .toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    final settings = AppSettings.fromMap(box.get('settings'));
    final monthKey = '${DateTime.now().year}-${DateTime.now().month}';
    final totalMembers = _userCount(trackers);
    final paidMembers = _paidUserCount(trackers, monthKey);
    final activeTrackers = _activeCount(trackers, monthKey);

    return Container(
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
        top: false,
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
                                  color: colorScheme.primary.withValues(
                                    alpha: isDark ? 0.18 : 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.analytics_outlined,
                                  color: isDark
                                      ? const Color(0xFF77FFD8)
                                      : colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Rent Track Kar',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Track this month at a glance',
                                      style: TextStyle(
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.62,
                                        ),
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
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.white.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : const Color(0xFFD9E6EF),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : colorScheme.primary.withValues(
                                            alpha: 0.10,
                                          ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.task_alt,
                                    color: isDark
                                        ? const Color(0xFF77FFD8)
                                        : colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'This month collection',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.62),
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
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFF77FFD8)
                                        : colorScheme.primary,
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
                        padding: const EdgeInsets.only(bottom: 24),
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
                                NotificationService.instance.syncForAllTrackers(
                                  box,
                                );
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: active
                                                ? colorScheme.primary
                                                : (isDark
                                                      ? Colors.white10
                                                      : const Color(
                                                          0xFFE8EFF5,
                                                        )),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Icon(
                                            IconData(
                                              tracker.iconCode,
                                              fontFamily: 'MaterialIcons',
                                            ),
                                            color: active
                                                ? colorScheme.onPrimary
                                                : colorScheme.onSurface
                                                    .withValues(alpha: 0.7),
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
                                                      ? (isDark
                                                            ? const Color(
                                                                0xFF77FFD8,
                                                              )
                                                            : colorScheme
                                                                  .primary)
                                                      : colorScheme.onSurface
                                                            .withValues(
                                                              alpha: 0.58,
                                                            ),
                                                  fontWeight: active
                                                      ? FontWeight.w600
                                                      : FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == 'archive') {
                                              _updateTracker(
                                                tracker.copyWith(
                                                  archived: true,
                                                ),
                                              );
                                            } else if (value == 'delete') {
                                              _deleteTracker(tracker.id);
                                            }
                                          },
                                          itemBuilder: (context) => const [
                                            PopupMenuItem<String>(
                                              value: 'archive',
                                              child: Text('Archive'),
                                            ),
                                            PopupMenuItem<String>(
                                              value: 'delete',
                                              child: Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        _chipLabel(
                                          context: context,
                                          icon: Icons.people_alt_outlined,
                                          label:
                                              '$totalCount member${totalCount == 1 ? '' : 's'}',
                                        ),
                                      ],
                                    ),
                                    if (active) ...[
                                      const SizedBox(height: 14),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        child: LinearProgressIndicator(
                                          minHeight: 8,
                                          value: progress,
                                          backgroundColor: isDark
                                              ? Colors.white12
                                              : const Color(0xFFD8E4EC),
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
    );
  }

  void _updateTracker(Tracker tracker) {
    final all = box.get('trackers', defaultValue: {}) as Map;
    all[tracker.id] = tracker.toMap();
    box.put('trackers', all);
    NotificationService.instance.syncForAllTrackers(box);
    setState(() {});
    showAppAlert(context, message: '${tracker.title} moved to archive.');
  }

  void _deleteTracker(String trackerId) {
    final all = box.get('trackers', defaultValue: {}) as Map;
    final tracker = all[trackerId] != null ? Tracker.fromMap(all[trackerId]) : null;
    all.remove(trackerId);
    box.put('trackers', all);
    NotificationService.instance.syncForAllTrackers(box);
    setState(() {});
    showAppAlert(
      context,
      message: tracker == null ? 'Tracker deleted.' : '${tracker.title} deleted.',
      icon: Icons.delete_outline,
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
    required BuildContext context,
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : const Color(0xFFD7E3EB),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    Colors.white.withValues(alpha: 0.10),
                    Colors.white.withValues(alpha: 0.03),
                  ]
                : [
                    Colors.white,
                    const Color(0xFFF2F7FB),
                  ],
          ),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : const Color(0xFFD9E6EF),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.28)
                  : const Color(0xFF8FA8BA).withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(
                  alpha: isDark ? 0.18 : 0.12,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.track_changes_rounded,
                size: 34,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Welcome to RentTrackKar',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Create your first tracker using the ',
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFEAF1F6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFD5E2EA),
                        ),
                      ),
                      child: Text(
                        '+',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' icon.'),
                ],
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
