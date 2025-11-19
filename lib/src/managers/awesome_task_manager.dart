import 'package:awesome_task_manager/src/logs/log_listener.dart';

import '../../awesome_task_manager.dart';
import 'awesome_task_manager_impl.dart';

abstract class AwesomeTaskManager {
  static AwesomeTaskManager? _instance;
  factory AwesomeTaskManager() => _instance ??= AwesomeTaskManagerImpl();

  Stream<TaskStatus> getTaskStatusStream({String? taskId});

  SharedResultManager createSharedResultManager();

  SequentialQueueManager createSequentialQueueManager();

  TaskPoolManager createTaskPoolManager({int poolSize = 2});

  RejectedAfterThresholdManager createRejectedAfterThresholdManager(
      {int taskThreshold = 1});

  CancelPreviousTaskManager createCancelPreviousTaskManager(
      {int maximumParallelTasks = 1});

  void registerLogListener(LogListener listener);
  void unregisterLogListener(LogListener listener);

  void log(
    String message, {
    DateTime? time,
    int? sequenceNumber,
    int level = 0,
    String name = '',
    Object? error,
    StackTrace? stackTrace,
  });
}
