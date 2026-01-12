import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../widgets/glass_card.dart';
import 'cycle.dart';
import 'models.dart';
import 'new_tracker.dart';

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
    final trackers =
        raw.values.map((e) => Tracker.fromMap(e)).toList();

    final monthKey = '${DateTime.now().year}-${DateTime.now().month}';

    return Scaffold(
      appBar: AppBar(title: const Text('Trackers')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewTrackerPage()),
          );
          setState(() {});
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: trackers.isEmpty
            ? const Center(child: Text('No trackers yet'))
            : ListView.builder(
                itemCount: trackers.length,
                itemBuilder: (c, i) {
                  final t = trackers[i];
                  final active =
                      box.containsKey('${t.id}_$monthKey');

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
  onLongPress: () {
    final all = box.get('trackers');
    all.remove(t.id);
    box.put('trackers', all);
    setState(() {});
  },
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
          color: active ? Colors.greenAccent : Colors.white70,
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
                    )
                    );
                },
              ),
      ),
    );
  }
}
