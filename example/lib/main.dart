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

class CountActionController {
  final fakeDelay = const Duration(milliseconds: 1500);

  int get counter => _counter;
  int _counter = 0;

  final SequentialQueueManager taskManager =
      AwesomeTaskManager().createSequentialQueueManager(managerId: 'counter');

  Future<void> increment() async {
    await taskManager.executeSequentialTask<int>(
      callerReference: 'CountActionController',
      taskId: 'increment',
      task: (taskStatus) async {
        await Future.delayed(fakeDelay);
        return ++_counter;
      },
    );
  }

  Future<void> decrement() async {
    await taskManager.executeSequentialTask<int>(
      callerReference: 'CountActionController',
      taskId: 'decrement',
      task: (taskStatus) async {
        await Future.delayed(fakeDelay);
        return --_counter;
      },
    );
  }
}

Widget getCircularProgress() =>
    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator());

class _MyHomePageState extends State<MyHomePage> {
  final countingController = CountActionController();

  @override
  void initState() {
    super.initState();
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
            AwesomeTaskObserver.byManagerId(
                managerId: 'counter',
                builder: (context, snapshot) {
                  return Text(
                    '${countingController.counter}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  );
                }),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AwesomeTaskObserver.byTaskId(
              taskId: 'increment',
              builder: (context, snapshot) {
                bool isLoading =
                    snapshot.connectionState == ConnectionState.waiting ||
                        (snapshot.data?.isExecuting ?? false);
                return FloatingActionButton(
                  onPressed: isLoading ? null : countingController.increment,
                  tooltip: 'Increment',
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.plus_one),
                );
              }),
          const SizedBox(height: 16),
          AwesomeTaskObserver.byTaskId(
              taskId: 'decrement',
              builder: (context, snapshot) {
                bool isLoading =
                    snapshot.connectionState == ConnectionState.waiting ||
                        (snapshot.data?.isExecuting ?? false);
                return FloatingActionButton(
                  onPressed: isLoading ? null : countingController.decrement,
                  tooltip: 'Decrement',
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.exposure_minus_1),
                );
              }),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
