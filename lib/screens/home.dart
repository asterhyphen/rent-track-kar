import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../widgets/glass_card.dart';
import 'cycle.dart';
import 'models.dart';
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


    final monthKey = '${DateTime.now().year}-${DateTime.now().month}';

    return Scaffold(
      appBar: AppBar(title: const Text('Trackers')),
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

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: trackers.isEmpty
            ? const Center(
                child: Text(
                  '404 error\nNo trackers found. Click the + icon to create a new tracker',
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                itemCount: trackers.length,
                itemBuilder: (c, i) {
                  final t = trackers[i];
                  final active = box.containsKey('${t.id}_$monthKey');

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Dismissible(
                      key: ValueKey(t.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete tracker?'),
                            content: const Text(
                              'Are you sure you want to delete this tracker? This action is irreversible.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
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
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: GlassCard(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CyclePage(trackerId: t.id),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Icon(
                              IconData(t.iconCode, fontFamily: 'MaterialIcons'),
                              color: active
                                  ? Colors.greenAccent
                                  : Colors.white70,
                              size: 28,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                t.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
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
    );
  }
}
