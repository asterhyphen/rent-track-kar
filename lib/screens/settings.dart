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
          padding: const EdgeInsets.all(16),
          children: [
            _sectionCard(
              title: 'Appearance',
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'system', label: Text('System')),
                  ButtonSegment(value: 'light', label: Text('Light')),
                  ButtonSegment(value: 'dark', label: Text('Dark')),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (selected) {
                  _save(settings.copyWith(themeMode: selected.first));
                },
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Tracker Defaults',
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
              title: 'Behavior',
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
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Clear monthly records'),
                    subtitle: const Text('Trackers remain unchanged'),
                    trailing: const Icon(Icons.delete_outline),
                    onTap: _clearMonthlyData,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
