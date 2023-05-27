import 'package:flutter/material.dart';
import 'package:hunt_stats/HuntBundle.dart';
import 'package:hunt_stats/db/stats_db.dart';
import 'package:hunt_stats/tracker.dart';

void main() async {
  final db = StatsDb();
  final tracker = TrackerEngine(db);

  runApp(MyApp(engine: tracker));

  await tracker.start();
}

class MyApp extends StatelessWidget {
  final TrackerEngine engine;

  const MyApp({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(engine: engine),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final TrackerEngine engine;

  const MyHomePage({super.key, required this.engine});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<HuntBundle?>(
        stream: widget.engine.lastMatch,
        builder: (cntx, snapshot) {
          final hundle = snapshot.data;

          if (hundle == null) {
            return const Center(
              child: Text('Awaiting for hunt data'),
            );
          }

          return Container();
        },
      ),
    );
  }
}
