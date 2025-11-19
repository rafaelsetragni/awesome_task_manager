import 'dart:async';
import 'dart:developer' as dev;

import '../../awesome_task_manager.dart';

abstract class TaskState<T> {
  final String taskId;
  final Completer<T> completer;

  final void Function(
    String message, {
    DateTime? time,
    int? sequenceNumber,
    int level,
    String name,
    Zone? zone,
    Object? error,
    StackTrace? stackTrace,
  }) customDevLog;

  bool _isError = false;
  bool _executed = false;
  bool _isTimedOut = false;
  bool _isCanceled = false;
  Exception? _lastException;
  T? _result;

  late final TaskStatus<T> status;

  TaskState({required this.taskId, this.customDevLog = dev.log})
      : completer = Completer() {
    status = TaskStatus(this);
    completer.future
        // Capture the last value returned
        .then(onNewResult)
        // avoids the error to reach the highest level if
        // there is no listeners when canceled
        .catchError(
          onNewException,
          test: (_) => true,
        );
  }

  Future<T> get future => completer.future;

  bool get isCanceled => _isCanceled;
  bool get isTimedOut => _isTimedOut;
  bool get isExecuting => _executed && !isCompleted;
  bool get isError => _isError;

  bool get isCompleted =>
      completer.isCompleted || _isCanceled || _isTimedOut || _isError;

  Exception? get lastException => _lastException;

  T? get result => _result;

  set isError(bool value) {
    _isError = value;
    emitNewState();
  }

  set started(bool value) {
    _executed = value;
    emitNewState();
  }

  set isTimedOut(bool value) {
    _isTimedOut = value;
    emitNewState();
  }

  set isCanceled(bool value) {
    _isCanceled = value;
    emitNewState();
  }

  FutureOr<dynamic> onNewResult(T lastValue) {
    _result = lastValue;
    return null;
  }

  FutureOr<dynamic> onNewException(e) {
    if (e is Exception) {
      _lastException = e;
    }
    switch (e) {
      case TimeoutException():
      case CancellationException():
        customDevLog(e.toString(), name: taskId);
    }
    return null;
  }

  void emitNewState() => TaskManager.emitNewTaskState(taskStatus: status);

  @override
  String toString() => 'TaskState<$T>('
      'taskId: $taskId, '
      'isCanceled: $isCanceled, '
      'isTimedOut: $isTimedOut, '
      'isExecuting: $isExecuting, '
      'isError: $isError, '
      'lastException: ${_lastException?.toString() ?? "None"}, '
      'result: ${_result?.toString() ?? "None"}, '
      'isCompleted: $isCompleted'
      ')';
}
