import 'dart:async';

import 'package:awesome_task_manager/awesome_task_manager.dart';
import 'package:awesome_task_manager/src/resolvers/task_resolver.dart';
import 'package:awesome_task_manager/src/tasks/cancelable_task.dart';
import 'package:awesome_task_manager/src/types/types.dart';

class RejectAfterThresholdResolver<T> extends TaskResolver<T> {
  final int taskThreshold;

  RejectAfterThresholdResolver({
    required super.managerId,
    required super.taskId,
    required this.taskThreshold,
  }) {
    validateMaximumParallelTasks(taskThreshold);
  }

  Future<TaskResult<T>> executeTask(
      {required String callerReference, required Task<T> task}) async {
    if (taskQueue.length >= taskThreshold) {
      AwesomeTaskManager().log('$taskId: task rejected', name: callerReference);
      return Future.value(
          (result: null, exception: TooManyTasksException(taskId)));
    }

    CancelableTask<T> completer = CancelableTask(
      managerId: managerId,
      taskId: taskId,
      task: task,
    );
    taskQueue.add(completer);

    return executeSingleTask(
      tag: callerReference,
      cancelableTaskReference: completer,
    ).whenComplete(() {
      fetchNextQueue(
        callerReference: callerReference,
        finishedTask: completer,
      );
    });
  }
}
