import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:awesome_task_manager/awesome_task_manager.dart';

import 'task_observer_widget_test.mocks.dart';

class MockTaskStatus implements TaskStatus<String> {

  MockTaskStatus({
    required this.isCanceled,
    required this.isCompleted,
    required this.isError,
    required this.isExecuting,
    required this.isTimedOut,
    required this.lastException,
    required this.result,
    required this.taskId,
  });

  factory MockTaskStatus.canceledStatus({
    required String taskId
  }) => MockTaskStatus(
    isCanceled: true,
    isCompleted: true,
    isError: false,
    isExecuting: false,
    isTimedOut: false,
    lastException: CancellationException(taskId: ''),
    result: null,
    taskId: taskId,
  );

  factory MockTaskStatus.running({
    required String taskId
  }) => MockTaskStatus(
    isCanceled: false,
    isCompleted: false,
    isError: false,
    isExecuting: true,
    isTimedOut: false,
    lastException: null,
    result: null,
    taskId: taskId,
  );

  factory MockTaskStatus.successful({
    required String taskId
  }) => MockTaskStatus(
    isCanceled: false,
    isCompleted: true,
    isError: false,
    isExecuting: true,
    isTimedOut: false,
    lastException: null,
    result: 'success',
    taskId: taskId,
  );

  @override
  bool isCanceled;

  @override
  bool isCompleted;

  @override
  bool isError;

  @override
  bool isExecuting;

  @override
  bool isTimedOut;

  @override
  Exception? lastException;

  @override
  String? result;

  @override
  int get taskHashcode => hashCode;

  @override
  String taskId;

  @override
  String toString() =>
      'MockTaskStatus: $taskId (${
          isCompleted ? '' : 'not '}completed)';
}


@GenerateNiceMocks([MockSpec<AwesomeTaskManager>()])
void main() {
  group('TaskObserver Tests', () {
    late MockAwesomeTaskManager mockTaskManager;
    late StreamController<TaskStatus<String>> controller;

    setUp(() {
      mockTaskManager = MockAwesomeTaskManager();
      controller = StreamController<TaskStatus<String>>();
      when(mockTaskManager.getTaskStatusStream(taskId: anyNamed('taskId')))
          .thenAnswer((_) => controller.stream);
    });

    tearDown(() {
      controller.close();
    });

    testWidgets('TaskObserver displays error state correctly', (WidgetTester tester) async {
      final mockErrorStatus = MockTaskStatus.canceledStatus(taskId: 'testId');

      await tester.pumpWidget(MaterialApp(
        home: AwesomeTaskObserver<String>(
          taskId: 'testId',
          builder: (BuildContext context, AsyncSnapshot<TaskStatus> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              return Text('Data: ${snapshot.data}');
            }
            return Container();
          },
        ),
      ));

      // Simulate error state
      controller.addError(mockErrorStatus);

      await tester.pump(); // Trigger a frame

      expect(find.text('Error: $mockErrorStatus'), findsOneWidget);
    });

    testWidgets('TaskObserver displays data state correctly', (WidgetTester tester) async {
      final mockSuccessStatus = MockTaskStatus.successful(taskId: 'testId');
      const circularProgressWidget = CircularProgressIndicator();

      await tester.pumpWidget(MaterialApp(
        home: AwesomeTaskObserver<String>(
          taskId: 'testId',
          builder: (BuildContext context, AsyncSnapshot<TaskStatus> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return circularProgressWidget;
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              return Text('Data: ${snapshot.data}');
            }
            return Container();
          },
        ),
      ));

      await tester.pump();

      expect(find.byWidget(circularProgressWidget), findsOneWidget);

      controller.add(mockSuccessStatus);
      expectLater(controller.stream, emits(mockSuccessStatus));
      
      await tester.pump(HumanDuration.oneSecond ~/ 2);

      expect(find.text('Data: $mockSuccessStatus'), findsOneWidget);
    });
  });
}
