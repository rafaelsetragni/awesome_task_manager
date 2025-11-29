/// Structured tuple returned after a task completes.
///
/// Contains either a [result] of type [T] on success, or an [exception] when execution fails.
/// Only one of these fields is expected to be non-null at a time.
class TaskResult<T> {
  final T? result;
  final Exception? exception;

  TaskResult({this.result, this.exception});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskResult &&
          runtimeType == other.runtimeType &&
          result == other.result &&
          exception == other.exception;

  @override
  int get hashCode => result.hashCode ^ exception.hashCode;

  @override
  String toString() => 'TaskResult(result: $result, exception: $exception)';
}
