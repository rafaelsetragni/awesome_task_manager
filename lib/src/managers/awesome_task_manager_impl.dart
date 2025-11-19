import 'dart:developer' as dev;

import 'package:awesome_task_manager/src/logs/log_listener.dart';

import '../../awesome_task_manager.dart';

class AwesomeTaskManagerImpl implements AwesomeTaskManager {
  final List<LogListener> _logListeners = [];

  @override
  Stream<TaskStatus> getTaskStatusStream({String? taskId}) =>
      TaskManager.getStatusStream(taskId: taskId);

  @override
  SharedResultManager createSharedResultManager() => SharedResultManager();

  @override
  SequentialQueueManager createSequentialQueueManager() =>
      SequentialQueueManager();

  @override
  TaskPoolManager createTaskPoolManager({int poolSize = 2}) =>
      TaskPoolManager(poolSize: poolSize);

  @override
  RejectedAfterThresholdManager createRejectedAfterThresholdManager(
          {int taskThreshold = 1}) =>
      RejectedAfterThresholdManager(taskThreshold: taskThreshold);

  @override
  CancelPreviousTaskManager createCancelPreviousTaskManager(
          {int maximumParallelTasks = 1}) =>
      CancelPreviousTaskManager(maximumParallelTasks: maximumParallelTasks);

  @override
  void registerLogListener(LogListener listener) {
    _logListeners.add(listener);
  }

  @override
  void unregisterLogListener(LogListener listener) {
    _logListeners.remove(listener);
  }

  @override
  void log(
    String message, {
    DateTime? time,
    int? sequenceNumber,
    int level = 0,
    String name = '',
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (_logListeners.isEmpty) {
      dev.log(message,
          time: time,
          sequenceNumber: sequenceNumber,
          level: level,
          name: name,
          error: error,
          stackTrace: stackTrace);
      return;
    }
    for (final listener in _logListeners) {
      listener.onNewLogEvent(message,
          time: time,
          sequenceNumber: sequenceNumber,
          level: level,
          name: name,
          error: error,
          stackTrace: stackTrace);
    }
  }
}
