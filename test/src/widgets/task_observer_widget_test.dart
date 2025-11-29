import 'package:awesome_task_manager/awesome_task_manager.dart';
import 'package:awesome_task_manager/src/streams/observable_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'task_observer_widget_test.mocks.dart';

// A simplified mock for TaskStatus for testing purposes.
class MockTaskStatus implements TaskStatus<String> {
  @override
  final String managerId;
  @override
  final String taskId;
  @override
  final String? result;
  @override
  final Exception? lastException;
  @override
  final bool isCompleted;

  MockTaskStatus({
    required this.managerId,
    required this.taskId,
    this.result,
    this.lastException,
    this.isCompleted = false,
  });

  // We don't need the other properties for these tests.
  @override
  bool get isCanceled => lastException is CancellationException;
  @override
  bool get isError => lastException != null && !isCanceled;
  @override
  bool get isExecuting => !isCompleted;
  @override
  bool get isTimedOut => lastException is TimeoutException;
  @override
  int get taskHashcode => hashCode;

  @override
  String toString() => 'MockTaskStatus: $taskId, result: $result';
}

@GenerateNiceMocks([MockSpec<AwesomeTaskManager>()])
void main() {
  late MockAwesomeTaskManager mockTaskManager;

  // Use setUpAll to create and register the mock instance once.
  setUpAll(() {
    mockTaskManager = MockAwesomeTaskManager();
    AwesomeTaskManager(mockedInstance: mockTaskManager);
  });

  // Use a top-level setUp to reset the mock before each test.
  setUp(() {
    reset(mockTaskManager);
  });

  group('AwesomeTaskObserver.byManagerId', () {
    late ObservableStream<TaskStatus?> managerController;
    const managerId = 'manager1';

    setUp(() {
      managerController = ObservableStream<TaskStatus?>();
      when(mockTaskManager.getTaskStatusStream(managerId: managerId))
          .thenAnswer((_) => managerController.stream);
    });

    tearDown(() {
      managerController.close();
    });

    testWidgets('should display data when stream emits a new status',
        (tester) async {
      final successStatus =
          MockTaskStatus(managerId: managerId, taskId: 't1', result: 'Success');

      await tester.pumpWidget(MaterialApp(
        home: AwesomeTaskObserver.byManagerId(
          managerId: managerId,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text('Data: ${snapshot.data?.result}');
            }
            return const Text('Waiting');
          },
        ),
      ));

      expect(find.text('Waiting'), findsOneWidget);

      managerController.add(successStatus);
      await tester.pump();

      // Corrected expectation to check for the result, not the object's toString().
      expect(find.text('Data: Success'), findsOneWidget);
    });
  });

  group('AwesomeTaskObserver.byTaskId', () {
    late ObservableStream<TaskStatus> taskController;
    const taskId = 'task1';

    setUp(() {
      taskController = ObservableStream<TaskStatus>();
      when(mockTaskManager.getTaskStatusStream(taskId: taskId))
          .thenAnswer((_) => taskController.stream);
    });

    tearDown(() {
      taskController.close();
    });

    testWidgets('should display data when stream emits a new status',
        (tester) async {
      final successStatus =
          MockTaskStatus(managerId: 'm1', taskId: taskId, result: 'Success');

      await tester.pumpWidget(MaterialApp(
        home: AwesomeTaskObserver.byTaskId(
          taskId: taskId,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text('Data: ${snapshot.data?.result}');
            }
            return const Text('Waiting');
          },
        ),
      ));

      expect(find.text('Waiting'), findsOneWidget);

      taskController.add(successStatus);
      await tester.pump();

      expect(find.text('Data: Success'), findsOneWidget);
    });
  });

  group('AwesomeTaskObserver (default)', () {
    late ObservableStream<TaskStatus> taskController;

    setUp(() {
      taskController = ObservableStream<TaskStatus>();
      when(mockTaskManager.getTaskStatusStream(taskId: null))
          .thenAnswer((_) => taskController.stream);
    });

    tearDown(() {
      taskController.close();
    });

    testWidgets('should display data when stream emits a new status',
        (tester) async {
      final successStatus =
          MockTaskStatus(managerId: 'm1', taskId: 't1', result: 'Success');

      await tester.pumpWidget(MaterialApp(
        home: AwesomeTaskObserver(
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text('Data: ${snapshot.data?.result}');
            }
            return const Text('Waiting');
          },
        ),
      ));

      expect(find.text('Waiting'), findsOneWidget);

      taskController.add(successStatus);
      await tester.pump();

      expect(find.text('Data: Success'), findsOneWidget);
    });
  });
}
