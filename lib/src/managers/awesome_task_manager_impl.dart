import '../../awesome_task_manager.dart';

class AwesomeTaskManagerImpl implements AwesomeTaskManager {

  @override
  Stream<TaskStatus> getTaskStatusStream({String? taskId}) =>
      TaskManager.getStatusStream(taskId: taskId);

  @override
  SharedResultManager createSharedResultManager() =>
      SharedResultManager();

  @override
  SequentialQueueManager createSequentialQueueManager() =>
      SequentialQueueManager();

  @override
  TaskPoolManager createTaskPoolManager({
    int poolSize = 2
  }) =>
      TaskPoolManager(
          poolSize: poolSize
      );

  @override
  RejectedAfterThresholdManager createRejectedAfterThresholdManager({
    int taskThreshold = 1
  }) =>
      RejectedAfterThresholdManager(
          taskThreshold: taskThreshold
      );

  @override
  CancelPreviousTaskManager createCancelPreviousTaskManager({
    int maximumParallelTasks = 1
  }) =>
      CancelPreviousTaskManager(
          maximumParallelTasks: maximumParallelTasks
      );

}