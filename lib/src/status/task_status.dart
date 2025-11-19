import '../tasks/task_state.dart';

abstract class TaskStatus<T> {
  factory TaskStatus(TaskState taskReference) =>
      CancelableTaskStatus<T>(taskReference);

  factory TaskStatus.empty({required String? taskId}) =>
      EmptyTaskStatus(taskId);

  String? get taskId;

  int get taskHashcode;

  bool get isCompleted;

  bool get isCanceled;

  bool get isExecuting;

  bool get isTimedOut;

  bool get isError;

  Exception? get lastException;

  T? get result;
}

class EmptyTaskStatus<T> implements TaskStatus<T> {
  EmptyTaskStatus(this.taskId);

  @override
  final String? taskId;

  @override
  int get taskHashcode => hashCode;

  @override
  bool get isCompleted => false;

  @override
  bool get isCanceled => false;

  @override
  bool get isExecuting => false;

  @override
  bool get isTimedOut => false;

  @override
  bool get isError => false;

  @override
  Exception? get lastException => null;

  @override
  T? get result => null;
}

class CancelableTaskStatus<T> implements TaskStatus<T> {
  final TaskState _taskReference;

  CancelableTaskStatus(this._taskReference);

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
