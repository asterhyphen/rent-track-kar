import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'app_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final Box<dynamic> box;
  late AppSettings settings;

  @override
  void initState() {
    super.initState();
    box = Hive.box('app');
    settings = AppSettings.fromMap(box.get('settings'));
  }

  void _save(AppSettings value) {
    setState(() => settings = value);
    box.put('settings', value.toMap());
  }

  Future<void> _clearMonthlyData() async {
    final shouldClear =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Clear monthly records?'),
            content: const Text(
              'This removes paid/pending records for all months, but keeps your trackers.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Clear'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldClear) return;

    final trackers = Map<String, dynamic>.from(
      box.get('trackers', defaultValue: <String, dynamic>{}) as Map,
    );
    final trackerIds = trackers.keys.toSet();

    for (final key in box.keys.toList()) {
      if (key is! String || key == 'trackers' || key == 'settings') continue;
      final idPart = key.split('_').first;
      if (trackerIds.contains(idPart)) {
        box.delete(key);
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Monthly records cleared.')));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF10192B), Color(0xFF090F1B)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.10),
                    Colors.white.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B894).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.tune,
                          color: Color(0xFF77FFD8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'App Preferences',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Personalize the look and tracker behavior.',
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
                  const SizedBox(height: 16),
                  _summaryPill(
                    icon: Icons.calendar_today_outlined,
                    title: 'Default due offset',
                    value:
                        '${settings.defaultDueDays} day${settings.defaultDueDays == 1 ? '' : 's'}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Tracker Defaults',
              icon: Icons.event_available_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Default due date offset: ${settings.defaultDueDays} day${settings.defaultDueDays == 1 ? '' : 's'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    min: 1,
                    max: 30,
                    divisions: 29,
                    value: settings.defaultDueDays.toDouble(),
                    onChanged: (value) {
                      _save(settings.copyWith(defaultDueDays: value.round()));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Appearance',
              icon: Icons.palette_outlined,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 340;
                  return SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'system', label: Text('System')),
                      ButtonSegment(value: 'light', label: Text('Light')),
                      ButtonSegment(value: 'dark', label: Text('Dark')),
                    ],
                    selected: {settings.themeMode},
                    multiSelectionEnabled: false,
                    showSelectedIcon: false,
                    direction: compact ? Axis.vertical : Axis.horizontal,
                    onSelectionChanged: (selected) {
                      _save(settings.copyWith(themeMode: selected.first));
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Behavior',
              icon: Icons.touch_app_outlined,
              child: SwitchListTile.adaptive(
                value: settings.confirmDelete,
                contentPadding: EdgeInsets.zero,
                title: const Text('Confirm before deleting tracker'),
                onChanged: (value) {
                  _save(settings.copyWith(confirmDelete: value));
                },
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Data',
              icon: Icons.storage_outlined,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Clear monthly records'),
                subtitle: const Text('Trackers remain unchanged'),
                trailing: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                ),
                onTap: _clearMonthlyData,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.065),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF77FFD8)),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _summaryPill({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF77FFD8)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
