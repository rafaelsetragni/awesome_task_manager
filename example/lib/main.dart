import 'package:awesome_task_manager/awesome_task_manager.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class IncrementActionController {
  final fakeDelay = const Duration(milliseconds: 1500);

  int get counter => _counter;
  int _counter = 0;

  final SequentialQueueManager taskManager = AwesomeTaskManager()
      .createSequentialQueueManager();

  Future<int> increment() async {
    final result = await taskManager
        .executeSequentialTask<int>(
          callerReference: 'MyHomePage',
          taskId: 'CounterTask',
          task: (taskStatus) async {
            await Future.delayed(fakeDelay);
            return ++_counter;
          },
        );
    return counter;
  }

  Future<int> decrement() async {
    final result = await taskManager
        .executeSequentialTask(
          callerReference: 'MyHomePage',
          taskId: 'CounterTask',
          task: (taskStatus) async {
            await Future.delayed(fakeDelay);
            return --_counter;
          },
        );
    return counter;
  }
}

class _MyHomePageState extends State<MyHomePage> {
  final incrementActionController = IncrementActionController();
  late final RejectedAfterThresholdManager taskManager;

  @override
  void initState() {
    super.initState();
    taskManager = AwesomeTaskManager()
        .createRejectedAfterThresholdManager();
  }

  void _incrementCounter() =>
    taskManager.executeRejectingAfterThreshold(
      callerReference: 'MyHomePage',
      taskId: 'userTap',
      task: (taskStatus) async {
        final result = await incrementActionController
            .increment();
      },
    );

  void _decrementCounter() {
    taskManager.executeRejectingAfterThreshold(
      callerReference: 'MyHomePage',
      taskId: 'userTap',
      task: (taskStatus) async {
        final result = await incrementActionController
            .increment();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: AwesomeTaskObserver(
        taskId: 'changeCounter',
        builder: (context, snapshot) {
          late Widget incrementIcon, decrementIcon;
          late VoidCallback? incrementMethod, decrementMethod;

          bool isLoading =
              snapshot.connectionState == ConnectionState.waiting ||
              (snapshot.data?.isExecuting ?? false);

          if (isLoading) {
            incrementIcon = decrementIcon = const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator()
            );
            incrementMethod = decrementMethod = null;
          } else {
            incrementIcon = const Icon(Icons.plus_one);
            decrementIcon = const Icon(Icons.exposure_minus_1);
            incrementMethod = _incrementCounter;
            decrementMethod = _decrementCounter;
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                onPressed: incrementMethod,
                tooltip: 'Increment',
                child: incrementIcon,
              ),
              const SizedBox(height: 16),
              FloatingActionButton(
                onPressed: decrementMethod,
                tooltip: 'Decrement',
                child: decrementIcon,
              ),
            ],
          );
        }
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
