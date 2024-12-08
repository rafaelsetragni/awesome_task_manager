import '../../awesome_task_manager.dart';
import 'awesome_task_manager_impl.dart';

abstract class AwesomeTaskManager {

  static AwesomeTaskManager? _instance;
  factory AwesomeTaskManager() =>
      _instance ??= AwesomeTaskManagerImpl();

  Stream<TaskStatus> getTaskStatusStream({String? taskId}) ;

  SharedResultManager createSharedResultManager();

  SequentialQueueManager createSequentialQueueManager();

  TaskPoolManager createTaskPoolManager({
    int poolSize = 2
  });

  RejectedAfterThresholdManager createRejectedAfterThresholdManager({
    int taskThreshold = 1
  });

  CancelPreviousTaskManager createCancelPreviousTaskManager({
    int maximumParallelTasks = 1
  });

}