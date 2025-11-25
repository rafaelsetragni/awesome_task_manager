import '../tasks/task_state.dart';

abstract class TaskStatus<T> {
  factory TaskStatus(TaskState taskReference) =>
      CancelableTaskStatus<T>(taskReference);

  // factory TaskStatus.empty() => EmptyTaskStatus(managerId: '', taskId: '');

  String get managerId;

  String get taskId;

  int get taskHashcode;

  bool get isCompleted;

  bool get isCanceled;

  bool get isExecuting;

  bool get isTimedOut;

  bool get isError;

  Exception? get lastException;

  T? get result;
}

class CancelableTaskStatus<T> implements TaskStatus<T> {
  final TaskState _taskReference;

  CancelableTaskStatus(this._taskReference);

  @override
  String get managerId => _taskReference.managerId;

  @override
  String get taskId => _taskReference.taskId;

  @override
  int get taskHashcode => _taskReference.hashCode;

  @override
  bool get isCompleted => _taskReference.isCompleted;

  @override
  bool get isCanceled => _taskReference.isCanceled;

  @override
  bool get isExecuting => _taskReference.isExecuting;

  @override
  bool get isTimedOut => _taskReference.isTimedOut;

  @override
  bool get isError => _taskReference.isError;

  @override
  Exception? get lastException => _taskReference.lastException;

  @override
  T? get result => _taskReference.result;
}
