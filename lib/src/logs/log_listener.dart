/// Defines a listener interface for receiving log event notifications.
///
/// Implementations of this interface can subscribe to log-producing components
/// and respond to log activity such as debug information, warnings, or errors.
/// This is typically used to redirect logs to user interfaces, storage services,
/// or external monitoring systems.
abstract class LogListener {
  /// Called whenever a new log event is emitted.
  ///
  /// Parameters:
  /// [message] — Main textual content of the log entry.
  /// [time] — Optional timestamp of when the event occurred. If null, the caller
  ///          may assume its own clock time.
  /// [sequenceNumber] — Optional incremental number indicating event order.
  /// [level] — Logging severity level following Dart's `developer` package:
  ///           - `0` : debug or verbose (fine-grained internal information)
  ///           - `500` : info (high-level operational messages)
  ///           - `800` : warning (unexpected conditions but continuing execution)
  ///           - `1000` : error (operation failed but application continues)
  ///           - `1200` : critical / shout (serious failure requiring immediate attention)
  ///
  ///           See: `dart:developer` logging levels specification.
  /// [name] — Logical category or source of the event, such as a subsystem name.
  /// [error] — Optional error object if the log is related to an exception.
  /// [stackTrace] — Optional stack trace that supplements an error log.
  ///
  /// Implementers should avoid throwing exceptions during processing.
  void onNewLogEvent(
    String message, {
    DateTime? time,
    int? sequenceNumber,
    int level = 0,
    String name = '',
    Object? error,
    StackTrace? stackTrace,
  });
}
