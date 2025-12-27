import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../widgets/glass_card.dart';
import 'cycle.dart';
import 'models.dart';
import 'new_tracker.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('app');
    final raw = box.get('trackers', defaultValue: {}) as Map;
    final trackers =
        raw.values.map((e) => Tracker.fromMap(e)).toList();

    final monthKey = '${DateTime.now().year}-${DateTime.now().month}';

    return Scaffold(
      appBar: AppBar(title: const Text('House Tracker')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewTrackerPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: trackers.isEmpty
            ? const Center(child: Text('No trackers yet'))
            : Column(
                children: trackers.map((t) {
                  final active =
                      box.containsKey('${t.id}_$monthKey');

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
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
                          Icon(
                            active
                                ? Icons.check_circle
                                : Icons.schedule,
                            color: active
                                ? Colors.greenAccent
                                : Colors.white70,
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
                  );
                }).toList(),
              ),
      ),
    );
  }
}
