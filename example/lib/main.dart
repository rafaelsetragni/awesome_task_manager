import 'dart:developer';

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

  void registerLogOnConsole(String message) {
    log(message, time: DateTime.now());
  }

  void increment() {
    taskManager
        .executeSequentialTask<int>(
          callerReference: 'CountActionController',
          taskId: 'increment',
          task: (taskStatus) async {
            await Future.delayed(fakeDelay);
            return ++_counter;
          },
        )
        .then((result) => result.fold(
              onSuccess: (value) {
                registerLogOnConsole('Value incremented: $value');
              },
              onFailure: (exception) {
                registerLogOnConsole('Error incrementing value: $exception');
              },
            ));
  }

  void decrement() {
    taskManager
        .executeSequentialTask<int>(
          callerReference: 'CountActionController',
          taskId: 'decrement',
          task: (taskStatus) async {
            await Future.delayed(fakeDelay);
            return --_counter;
          },
        )
        .then((result) => result.fold(
              onSuccess: (value) {
                registerLogOnConsole('Value decremented: $value');
              },
              onFailure: (exception) {
                registerLogOnConsole('Error decrementing value: $exception');
              },
            ));
  }

  void reset() {
    taskManager
        .executeSequentialTask<int>(
      callerReference: 'CountActionController',
      taskId: 'reset',
      task: (taskStatus) async {
        await Future.delayed(fakeDelay * 2);
        return _counter = 0;
      },
    )
        .then((taskResult) {
      if (taskResult is TaskSuccess) {
        registerLogOnConsole('Value decremented: ${taskResult.value}');
      }
      if (taskResult is TaskFailure) {
        registerLogOnConsole(
            'Error decrementing value: ${taskResult.exception}');
      }
    });
  }
}

class _MyHomePageState extends State<MyHomePage> {
  final countingController = CountActionController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AwesomeTaskObserver.byTaskId(
        taskId: 'reset',
        builder: (context, resetSnapshot) {
          bool isGlobalLoading =
              resetSnapshot.connectionState == ConnectionState.waiting ||
                  (resetSnapshot.data?.isExecuting ?? false);
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              title: Text(widget.title),
            ),
            body: Stack(
              children: [
                _buildMainPage(context, isGlobalLoading),
                if (isGlobalLoading) _buildLoadingScreen(context),
              ],
            ),
            floatingActionButton: buildFloatingButtons(
              isGlobalLoading,
            ), // This trailing comma makes auto-formatting nicer for build methods.
          );
        });
  }

  Column buildFloatingButtons(bool isGlobalLoading) {
    return Column(
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
        const SizedBox(height: 16),
        FloatingActionButton(
          onPressed: isGlobalLoading ? null : countingController.reset,
          tooltip: 'Reset',
          child: const Icon(Icons.clear),
        )
      ],
    );
  }

  Widget _buildMainPage(BuildContext context, bool isGlobalLoading) {
    return Center(
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
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.white70,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: CircularProgressIndicator(),
            ),
            Text('Resetting...'),
          ],
        ),
      ),
    );
  }
}
