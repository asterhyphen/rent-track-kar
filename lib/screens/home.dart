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
    final trackers = raw.values
       .map((e) => Tracker.fromMap(e))
       .toList()
     ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    final settings = AppSettings.fromMap(box.get('settings'));

    final monthKey = '${DateTime.now().year}-${DateTime.now().month}';

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
          setState(() {});
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
                ? const Center(
                    child: _EmptyState(),
                  )
                : Column(
                    children: [
                      GlassCard(
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
                            const SizedBox(height: 8),
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
                                  label: 'This Month',
                                  value: '${_activeCount(trackers, monthKey)}',
                                ),
                                const SizedBox(width: 12),
                                _statTile(
                                  context,
                                  label: 'Users',
                                  value: '${_userCount(trackers)}',
                                ),
                              ],
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
                            final t = trackers[i];
                            final active = box.containsKey('${t.id}_$monthKey');

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Dismissible(
                                key: ValueKey(t.id),
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
                                  all.remove(t.id);
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
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CyclePage(trackerId: t.id),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: active
                                              ? const Color(0xFF00B894)
                                              : Colors.white10,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          IconData(
                                            t.iconCode,
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
                                              t.title,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              active
                                                  ? 'Tracking current month'
                                                  : 'Not started this month',
                                              style: TextStyle(
                                                color: active
                                                    ? const Color(0xFF77FFD8)
                                                    : Colors.white54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right),
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
