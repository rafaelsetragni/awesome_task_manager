import '../tasks/task_state.dart';

/// Represents the public read-only status of a task execution.
///
/// A [TaskStatus] provides consumers (UI, controllers, loggers, observers)
/// with real‑time metadata about task execution progress, errors, timeouts,
/// cancellation, and final result value. These values are derived from an
/// associated internal [TaskState] and exposed in a safe, immutable form.
///
/// Instances of [TaskStatus] are emitted through the task management streams
/// provided by [AwesomeTaskManager] and can be observed per‑task or globally.
abstract class TaskStatus<T> {
  /// Creates a concrete [TaskStatus] wrapping an internal [TaskState] reference.
  ///
  /// The returned implementation forwards all status properties to the
  /// underlying state while maintaining a consistent read‑only interface.
  factory TaskStatus(TaskState taskReference) =>
      CancelableTaskStatus<T>(taskReference);

  // factory TaskStatus.empty() => EmptyTaskStatus(managerId: '', taskId: '');

  /// Identifier of the manager the task belongs to.
  String get managerId;

  /// Identifier of the specific task instance.
  String get taskId;

  /// Hash code identifying the task reference in internal structures.
  int get taskHashcode;

  /// Whether the task has completed execution successfully.
  bool get isCompleted;

  /// Whether the task has been cancelled before completion.
  bool get isCanceled;

  /// Whether the task is currently executing.
  bool get isExecuting;

  /// Whether the task exceeded its allowed timeout duration.
  bool get isTimedOut;

  /// Whether the task finished with an error.
  bool get isError;

  /// The last recorded exception thrown by the task, if any.
  Exception? get lastException;

  /// The resolved value of the task if completed successfully.
  ///
  /// For error or cancelled states, this will be `null`.
  T? get result;
}

/// Default implementation of [TaskStatus] that forwards property access
/// directly to the underlying [TaskState] instance.
///
/// This is the value‑based snapshot that is published to observers.
class CancelableTaskStatus<T> implements TaskStatus<T> {
  /// Internal reference to the original mutable [TaskState] object.
  ///
  /// Not exposed externally to preserve read‑only guarantees.
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
