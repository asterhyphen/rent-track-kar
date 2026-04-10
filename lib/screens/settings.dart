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

  Future<void> _editMessageTemplate() async {
    final controller = TextEditingController(text: settings.messageTemplate);

    final updatedTemplate =
        await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Edit message template'),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    maxLines: 14,
                    minLines: 10,
                    decoration: const InputDecoration(
                      alignLabelWithHint: true,
                      labelText: 'Template',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Available placeholders: {title}, {dueDate}, {daysRemaining}, {total}, {perHead}, {paidCount}, {paidAmount}, {paidUsers}, {pendingCount}, {pendingAmount}, {pendingUsers}',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => controller.text = AppSettings.defaultMessageTemplate,
                child: const Text('Reset default'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, controller.text),
                child: const Text('Save'),
              ),
            ],
          ),
        ) ??
        '';

    if (updatedTemplate.trim().isEmpty) return;
    _save(settings.copyWith(messageTemplate: updatedTemplate));
  }

  Future<void> _clearMonthlyData() async {
    final shouldClear =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Clear monthly records?'),
            content: const Text(
              'This removes paid and pending records for all months, but keeps your trackers.',
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF10192B), Color(0xFF090F1B)]
              : const [Color(0xFFF9FCFE), Color(0xFFEAF2F7)],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.10),
                        Colors.white.withValues(alpha: 0.04),
                      ]
                    : [
                        Colors.white,
                        const Color(0xFFF1F7FB),
                      ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : const Color(0xFFD9E6EF),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.24)
                      : const Color(0xFF8FA8BA).withValues(alpha: 0.16),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
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
                        color: colorScheme.primary.withValues(
                          alpha: isDark ? 0.16 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.tune,
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
                          Text(
                            'App Preferences',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Personalize the look and tracker behavior.',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.66,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _summaryPill(
                  context: context,
                  icon: Icons.palette_outlined,
                  title: 'Theme mode',
                  value: settings.themeMode.toUpperCase(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            context: context,
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
            context: context,
            title: 'Behavior',
            icon: Icons.touch_app_outlined,
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: settings.confirmDelete,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Confirm before deleting tracker'),
                  onChanged: (value) {
                    _save(settings.copyWith(confirmDelete: value));
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Default message template'),
                  subtitle: const Text('Edit the text used for share messages'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _editMessageTemplate,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            context: context,
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
    );
  }

  Widget _sectionCard({
    required BuildContext context,
    required String title,
    required Widget child,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.065)
            : Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
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
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFF1F6FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isDark
                      ? const Color(0xFF77FFD8)
                      : theme.colorScheme.primary,
                ),
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
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFD9E6EF),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? const Color(0xFF77FFD8) : theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
