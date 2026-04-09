import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/task.dart';
import 'models/task_list.dart';
import 'screens/neo_home_page.dart';
import 'utils/neo_brutalism.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TaskPriorityAdapter());
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(TaskListAdapter());
  await Hive.openBox<Task>('tasks');
  await Hive.openBox<TaskList>('taskLists');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LiTasker',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: NeoBrutalism.background,
        colorScheme: const ColorScheme.light(
          primary: NeoBrutalism.yellow,
          secondary: NeoBrutalism.cyan,
          tertiary: NeoBrutalism.pink,
          surface: NeoBrutalism.background,
          onSurface: NeoBrutalism.ink,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NeoHomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 148,
                height: 148,
                decoration: NeoBrutalism.card(color: NeoBrutalism.yellow),
                child: const Icon(Icons.task_alt, size: 72, color: NeoBrutalism.ink),
              ),
              const SizedBox(height: 24),
              const Text(
                'LITASKER',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: NeoBrutalism.ink,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'PLAN HARD. FINISH LOUD.',
                style: TextStyle(
                  fontSize: 14,
                  color: NeoBrutalism.ink,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 48),
              Container(
                width: 220,
                height: 18,
                decoration: NeoBrutalism.flatCard(color: NeoBrutalism.paper),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(width: 132, color: NeoBrutalism.cyan),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
