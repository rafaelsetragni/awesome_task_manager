import 'dart:async';

import '../exceptions/task_exceptions.dart';
import '../types/types.dart';
import 'task_state.dart';



class CancelableTask<T> extends TaskState<T> {
  final Duration? timeout;
  final Task<T> task;

  CancelableTask({
    required super.taskId,
    required this.task,
    this.timeout
  });

  bool cancel() {
    if (isCompleted) return false;
    try {
      completer
          .completeError(CancellationException(taskId: taskId));
      return isCanceled = true;
    } catch (_) {
      return false;
    }
  }

  Future<T> execute() async {
    if (isCompleted || executed) return future;
    executed = true;

    try {
      final timeout = this.timeout;
      late final Future<T> future;
      if (timeout == null) {
        future = task(status);
      } else {
        future = task(status)
            .timeout(
            timeout,
              onTimeout: () {
                isTimedOut = true;
                throw TimeoutException(taskId: taskId);
              }
            );
      }

      completer.complete(await future);

    } catch (error) {
      isError = !isTimedOut;
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    }
    return future;
  }
}
