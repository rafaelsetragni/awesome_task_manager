import 'package:awesome_task_manager/awesome_task_manager.dart';
import 'package:awesome_task_manager/src/resolvers/task_resolver.dart';
import 'package:awesome_task_manager/src/tasks/cancelable_task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'reject_after_threshold_test.dart';
import 'task_resolver_test.mocks.dart';

typedef TimeExecutionTracker = ({
  String taskId,
  DateTime startTime,
  DateTime endTime
});
Future<TimeExecutionTracker> simpleExecutionTracker({
  required String taskId,
  Duration fakeDelay = const Duration(milliseconds: 250),
}) async {
  final start = DateTime.now();
  await Future.delayed(fakeDelay);
  final end = DateTime.now();
  return (
    taskId: taskId,
    startTime: start,
    endTime: end,
  );
}

class MockTaskResolver<T> extends TaskResolver<T> {
  final MockStopwatch? mockStopwatch;

  MockTaskResolver({this.mockStopwatch})
      : super(managerId: 'test', taskId: '1');

  @override
  Stopwatch getStopwatch() => mockStopwatch ?? super.getStopwatch();
}

@GenerateNiceMocks([
  MockSpec<Stopwatch>(),
  MockSpec<CancelableTask>(),
])
void main() {
  late MockStopwatch mockStopwatch;
  late MockTaskResolver resolver;

  setUpAll(() {
    mockStopwatch = MockStopwatch();
    resolver = MockTaskResolver(mockStopwatch: mockStopwatch);

    when(mockStopwatch.start()).thenAnswer((_) {});
    when(mockStopwatch.stop()).thenAnswer((_) {});
    when(mockStopwatch.elapsed).thenReturn(Duration.zero);
  });

  group('validateTaskThreshold', () {
    test('should throw an exception if maximumParallelTasks is less than 1',
        () {
      expect(() => MockTaskResolver().validateMaximumParallelTasks(0),
          throwsA(isA<InvalidTasksParameterException>()));
    });

    test('should not throw an exception if maximumParallelTasks is 1 or more',
        () {
      expect(() => MockTaskResolver().validateMaximumParallelTasks(1),
          returnsNormally);
    });
  });

  group('getStopWatch', () {
    test('should return a valid instance of StopWatch', () async {
      final instance = MockTaskResolver().getStopwatch();
      expect(instance, isA<Stopwatch>());
    });
  });

  group('executeSingleTask', () {
    test('should complete with result on successful execution', () async {
      final resolver = MockTaskResolver();
      final result = await resolver.executeSingleTask(
          tag: 'testTag',
          cancelableTaskReference: CancelableTask(
              managerId: 'test',
              taskId: 'testTag',
              task: (status) async => 'Test Result'));
      expect(result.result, 'Test Result');
      expect(result.exception, isNull);
    });

    test('should complete with exception on task failure', () async {
      final resolver = MockTaskResolver();
      final result = await resolver.executeSingleTask(
          tag: 'testTag',
          cancelableTaskReference: CancelableTask(
              managerId: 'test',
              taskId: 'testTag',
              task: (status) async => throw Exception('Test Exception')));

      expect(result.result, isNull);
      expect(result.exception, isNotNull);
    });
  });

  group('fetchNextQueue', () {
    test('should correctly clean the past queue', () async {
      final TaskResolver<TimeExecutionTracker> resolver = MockTaskResolver();
      final CancelableTask<TimeExecutionTracker> completer1 = CancelableTask(
        managerId: 'test',
        taskId: 'testTag',
        task: (status) => simpleExecutionTracker(taskId: '1'),
      );

      resolver.taskQueue.add(completer1);
      await resolver.executeSingleTask(
          tag: 'testTag', cancelableTaskReference: completer1);

      expect(resolver.taskQueue.isEmpty, false);
      await resolver.fetchNextQueue(
        callerReference: 'fetchNextQueue',
        finishedTask: completer1,
      );
      expect(resolver.taskQueue.isEmpty, true);
    });

    test('should correctly clean the past queue if cancelled', () async {
      final TaskResolver<TimeExecutionTracker> resolver = MockTaskResolver();
      final CancelableTask<TimeExecutionTracker> completer1 = CancelableTask(
          managerId: 'test',
          taskId: 'testTag',
          task: (status) => simpleExecutionTracker(taskId: '1'));

      resolver.taskQueue.add(completer1);
      await resolver.executeSingleTask(
          tag: 'testTag', cancelableTaskReference: completer1);

      expect(resolver.taskQueue.isEmpty, false);
      await resolver.fetchNextQueue(
        callerReference: 'fetchNextQueue',
        finishedTask: completer1,
      );
      expect(resolver.taskQueue.isEmpty, true);
    });

    test('should correctly clean the past queue', () async {
      final TaskResolver<TimeExecutionTracker> resolver = MockTaskResolver();
      final CancelableTask<TimeExecutionTracker> completer1 = CancelableTask(
              managerId: 'test',
              taskId: 'testTag',
              task: (status) => simpleExecutionTracker(taskId: '1')),
          completer2 = CancelableTask(
              managerId: 'test',
              taskId: 'testTag',
              task: (status) => simpleExecutionTracker(
                    taskId: '2',
                    fakeDelay: const Duration(milliseconds: 500),
                  ));

      resolver.taskQueue.add(completer1);
      await resolver.executeSingleTask(
          tag: 'testTag', cancelableTaskReference: completer1);

      resolver.taskQueue.add(completer2);
      expect(resolver.taskQueue.length, 2);

      await resolver.fetchNextQueue(
        callerReference: 'fetchNextQueue',
        finishedTask: completer1,
      );
      expect(resolver.taskQueue.length, 1);
      expect(resolver.taskQueue.first, completer2);
    });

    test('should correctly clean the past queue', () async {
      const taskId = 'fetchNextQueueTest 1';
      final TaskResolver<TimeExecutionTracker> resolver = MockTaskResolver();
      final CancelableTask<TimeExecutionTracker> completer1 = CancelableTask(
              managerId: 'test',
              taskId: taskId,
              task: (status) => simpleExecutionTracker(
                  taskId: 'completer 1', fakeDelay: taskDuration)),
          completer2 = CancelableTask(
              managerId: 'test',
              taskId: taskId,
              task: (status) => simpleExecutionTracker(
                  taskId: 'completer 2', fakeDelay: taskDuration * 2)),
          completer3 = CancelableTask(
              managerId: 'test',
              taskId: taskId,
              task: (status) => simpleExecutionTracker(
                  taskId: 'completer 3', fakeDelay: taskDuration * 3));

      resolver.taskQueue.add(completer1);
      resolver.taskQueue.add(completer2);
      resolver.taskQueue.add(completer3);

      resolver.executeSingleTask(
        tag: 'fetchNextQueue',
        cancelableTaskReference: completer1,
      );

      resolver.executeSingleTask(
        tag: 'fetchNextQueue',
        cancelableTaskReference: completer2,
      );

      resolver.executeSingleTask(
        tag: 'fetchNextQueue',
        cancelableTaskReference: completer3,
      );

      await completer1.future;

      expect(resolver.taskQueue.length, 3);
      await resolver.fetchNextQueue(
        callerReference: 'fetchNextQueue',
        finishedTask: completer1,
      );

      expect(resolver.taskQueue.length, 2);
      expect(resolver.taskQueue.first, completer2);
      expect(resolver.taskQueue.last, completer3);

      await completer2.future;
      await resolver.fetchNextQueue(
        callerReference: 'fetchNextQueue',
        finishedTask: completer2,
      );

      expect(resolver.taskQueue.length, 1);
      expect(resolver.taskQueue.first, completer3);
    });
  });

  group('description', () {
    test('should stop the stopwatch on successful execution', () async {
      mockStopwatch.reset();

      final result = await resolver.executeSingleTask(
        tag: 'testTag',
        cancelableTaskReference: CancelableTask(
            managerId: 'test',
            taskId: 'testTag',
            task: (status) async => 'Test Result'),
      );

      expect(result.result, 'Test Result');
      expect(result.exception, isNull);
      verify(mockStopwatch.start()).called(1);
      verify(mockStopwatch.stop()).called(1);
    });

    test('should stop the stopwatch on task failure with Exception', () async {
      mockStopwatch.reset();

      final TaskResult result = await resolver.executeSingleTask(
          tag: 'testTag',
          cancelableTaskReference: CancelableTask(
              managerId: 'test',
              taskId: 'testTag',
              task: (status) async {
                throw Exception('Test Exception');
              }));

      expect(result.result, isNull);
      expect(result.exception, isNotNull);

      verify(mockStopwatch.start()).called(1);
      verify(mockStopwatch.stop()).called(1);
    });

    test('should stop the stopwatch on task failure with non-Exception error',
        () async {
      mockStopwatch.reset();

      final result = await resolver.executeSingleTask(
        tag: 'testTag',
        cancelableTaskReference: CancelableTask(
            managerId: 'test',
            taskId: 'testTag',
            task: (status) async {
              throw 'Non-Exception Error';
            }),
      );

      expect(result.result, isNull);
      expect(result.exception, isNotNull);

      verify(mockStopwatch.start()).called(1);
      verify(mockStopwatch.stop()).called(1);
    });
  });

  group('cancel method', () {
    test('cancel with taskId not matching', () {
      mockStopwatch = MockStopwatch();
      resolver = MockTaskResolver(mockStopwatch: mockStopwatch);

      expect(resolver.cancelTask(taskId: '1'), isFalse);

      final task1 = MockCancelableTask<String>();
      final task2 = MockCancelableTask<String>();
      final task3 = MockCancelableTask<String>();

      when(task1.taskId).thenReturn('1');
      when(task1.taskId).thenReturn('2');
      when(task1.taskId).thenReturn('3');

      resolver.taskQueue.add(task1);
      resolver.taskQueue.add(task2);
      resolver.taskQueue.add(task3);

      expect(resolver.cancelTask(taskId: '4'), isFalse);
    });
    test('cancel with taskId matching', () {
      mockStopwatch = MockStopwatch();
      resolver = MockTaskResolver(mockStopwatch: mockStopwatch);

      final task = MockCancelableTask<String>();
      when(task.taskId).thenReturn('1');
      resolver.taskQueue.add(task);

      when(task.cancel()).thenReturn(true);
      expect(resolver.cancelTask(taskId: '1'), isTrue);

      when(task.cancel()).thenReturn(false);
      expect(resolver.cancelTask(taskId: '1'), isFalse);
    });
  });
}
