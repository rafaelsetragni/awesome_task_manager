import 'package:awesome_task_manager/awesome_task_manager.dart';
import 'package:awesome_task_manager/src/logs/log_listener.dart';
import 'package:awesome_task_manager/src/managers/awesome_task_manager_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'awesome_task_manager_impl_test.mocks.dart';

@GenerateNiceMocks([MockSpec<LogListener>()])
void main() {
  group('AwesomeTaskManagerImpl', () {
    late AwesomeTaskManagerImpl taskManager;

    setUp(() {
      taskManager = AwesomeTaskManagerImpl();
    });

    group('Manager Creation', () {
      test('createSharedResultManager returns correct type', () {
        final manager =
            taskManager.createSharedResultManager(managerId: 'test');
        expect(manager, isA<SharedResultManager>());
        expect(manager.managerId, 'test');
      });

      test('createSequentialQueueManager returns correct type', () {
        final manager =
            taskManager.createSequentialQueueManager(managerId: 'test');
        expect(manager, isA<SequentialQueueManager>());
        expect(manager.managerId, 'test');
      });

      test('createTaskPoolManager returns correct type with correct poolSize',
          () {
        final manager =
            taskManager.createTaskPoolManager(managerId: 'test', poolSize: 5);
        expect(manager, isA<TaskPoolManager>());
        expect(manager.managerId, 'test');
        expect(manager.poolSize, 5);
      });

      test(
          'createRejectedAfterThresholdManager returns correct type with correct threshold',
          () {
        final manager = taskManager.createRejectedAfterThresholdManager(
            managerId: 'test', taskThreshold: 3);
        expect(manager, isA<RejectedAfterThresholdManager>());
        expect(manager.managerId, 'test');
        expect(manager.taskThreshold, 3);
      });

      test(
          'createCancelPreviousTaskManager returns correct type with correct parallel tasks',
          () {
        final manager = taskManager.createCancelPreviousTaskManager(
            managerId: 'test', maximumParallelTasks: 2);
        expect(manager, isA<CancelPreviousTaskManager>());
        expect(manager.managerId, 'test');
        expect(manager.maximumParallelTasks, 2);
      });
    });

    group('Logging', () {
      late MockLogListener mockListener;

      setUp(() {
        mockListener = MockLogListener();
      });

      test('registerLogListener adds a listener', () {
        taskManager.registerLogListener(mockListener);
        taskManager.log('test message');
        verify(mockListener.onNewLogEvent('test message',
                time: anyNamed('time'),
                sequenceNumber: anyNamed('sequenceNumber'),
                level: anyNamed('level'),
                name: anyNamed('name'),
                error: anyNamed('error'),
                stackTrace: anyNamed('stackTrace')))
            .called(1);
      });

      test('unregisterLogListener removes a listener', () {
        taskManager.registerLogListener(mockListener);
        taskManager.unregisterLogListener(mockListener);
        taskManager.log('test message');
        verifyNever(mockListener.onNewLogEvent(any,
            time: anyNamed('time'),
            sequenceNumber: anyNamed('sequenceNumber'),
            level: anyNamed('level'),
            name: anyNamed('name'),
            error: anyNamed('error'),
            stackTrace: anyNamed('stackTrace')));
      });

      test('log notifies registered listeners', () {
        final listener1 = MockLogListener();
        final listener2 = MockLogListener();

        taskManager.registerLogListener(listener1);
        taskManager.registerLogListener(listener2);

        taskManager.log('multi-listener test');

        verify(listener1.onNewLogEvent('multi-listener test',
                time: anyNamed('time'),
                sequenceNumber: anyNamed('sequenceNumber'),
                level: anyNamed('level'),
                name: anyNamed('name'),
                error: anyNamed('error'),
                stackTrace: anyNamed('stackTrace')))
            .called(1);
        verify(listener2.onNewLogEvent('multi-listener test',
                time: anyNamed('time'),
                sequenceNumber: anyNamed('sequenceNumber'),
                level: anyNamed('level'),
                name: anyNamed('name'),
                error: anyNamed('error'),
                stackTrace: anyNamed('stackTrace')))
            .called(1);
      });
    });
  });
}
