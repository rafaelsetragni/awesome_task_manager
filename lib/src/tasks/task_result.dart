/// Represents the result of a task, which can either be a success or a failure.
///
/// This is an abstract class with two subclasses: [TaskSuccess] and [TaskFailure].
abstract class TaskResult<T> {
  /// Factory constructor to create a [TaskSuccess] or [TaskFailure] result.
  ///
  /// If [exception] is not null, it creates a [TaskFailure]; otherwise, it creates
  /// a [TaskSuccess] with the given [result].
  factory TaskResult({T? result, Exception? exception}) {
    if (exception != null) {
      return TaskFailure(exception);
    }
    return TaskSuccess(result as T);
  }

  /// Private constructor to prevent direct instantiation.
  const TaskResult._();

  /// Returns `true` if the task completed successfully.
  bool get isSuccess;

  /// Returns `true` if the task failed.
  bool get isFailure;

  /// Gets the result of a successful task. Returns `null` if the task failed.
  T? get value;

  /// Gets the exception of a failed task. Returns `null` if the task was successful.
  Exception? get exception;

  /// Folds this [TaskResult] into a single value.
  ///
  /// Takes two functions, [onSuccess] and [onFailure], and applies the
  /// appropriate one based on the state of the result.
  R fold<R>({
    required R Function(T result) onSuccess,
    required R Function(Exception exception) onFailure,
  });

  /// Maps a [TaskResult<T>] to [TaskResult<R>] by applying a function to a
  /// successful result.
  TaskResult<R> map<R>(R Function(T result) f);

  /// Maps a [TaskResult<T>] by applying a function to a failed result.
  TaskResult<T> mapError(Exception Function(Exception exception) f);

  /// Flat-maps a [TaskResult<T>] to [TaskResult<R>] by applying a function
  /// that returns a [TaskResult].
  TaskResult<R> flatMap<R>(TaskResult<R> Function(T result) f);
}

/// Represents a successful task result.
class TaskSuccess<T> extends TaskResult<T> {
  @override
  final T value;

  /// Creates a new [TaskSuccess] result with the given [result].
  const TaskSuccess(this.value) : super._();

  @override
  bool get isSuccess => true;

  @override
  bool get isFailure => false;

  @override
  Exception? get exception => null;

  @override
  R fold<R>({
    required R Function(T result) onSuccess,
    required R Function(Exception exception) onFailure,
  }) =>
      onSuccess(value);

  @override
  TaskResult<R> map<R>(R Function(T result) f) => TaskSuccess(f(value));

  @override
  TaskResult<T> mapError(Exception Function(Exception exception) f) => this;

  @override
  TaskResult<R> flatMap<R>(TaskResult<R> Function(T result) f) => f(value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskSuccess<T> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success(result: $value)';
}

/// Represents a failed task result.
class TaskFailure<T> extends TaskResult<T> {
  @override
  final Exception exception;

  /// Creates a new [TaskFailure] result with the given [exception].
  const TaskFailure(this.exception) : super._();

  @override
  bool get isSuccess => false;

  @override
  bool get isFailure => true;

  @override
  T? get value => null;

  @override
  R fold<R>({
    required R Function(T result) onSuccess,
    required R Function(Exception exception) onFailure,
  }) =>
      onFailure(exception);

  @override
  TaskResult<R> map<R>(R Function(T result) f) => TaskFailure(exception);

  @override
  TaskResult<T> mapError(Exception Function(Exception exception) f) =>
      TaskFailure(f(exception));

  @override
  TaskResult<R> flatMap<R>(TaskResult<R> Function(T result) f) =>
      TaskFailure(exception);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskFailure<T> &&
          runtimeType == other.runtimeType &&
          exception == other.exception;

  @override
  int get hashCode => exception.hashCode;

  @override
  String toString() => 'Failure(exception: $exception)';
}
