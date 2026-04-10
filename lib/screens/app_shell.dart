import 'package:flutter/material.dart';
import 'archive.dart';
import 'home.dart';
import 'settings.dart';
import 'tracker.dart';
import 'users.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  static const _titles = ['Trackers', 'Users', 'Settings'];
  static const _subtitles = [
    'Monitor collections and due cycles',
    'People directory coming next',
    'Tune appearance and defaults',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _titles[_currentIndex],
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              _subtitles[_currentIndex],
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
        actions: _currentIndex == 0
            ? [
                IconButton(
                  tooltip: 'Archive',
                  onPressed: _openArchive,
                  icon: const Icon(Icons.archive_outlined),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilledButton.icon(
                    onPressed: _openCreateTracker,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ),
              ]
            : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: theme.dividerColor.withValues(alpha: isDark ? 1 : 0.8),
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomePage(),
          UsersPage(),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people_alt_rounded),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateTracker() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrackerPage()),
    );

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openArchive() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ArchivePage()),
    );

    if (!mounted) return;
    setState(() {});
  }
}
