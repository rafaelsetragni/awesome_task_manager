import 'package:awesome_task_manager/awesome_task_manager.dart';
import 'package:flutter/cupertino.dart';

/// A Flutter widget that rebuilds automatically whenever a task emits a new [TaskStatus].
///
/// The observer listens to either:
///  * a specific task via [taskId],
///  * a task manager domain via [managerId], or
///  * all tasks when neither is provided.
///
/// It provides the latest asynchronous status to the [builder] function, enabling
/// UI elements such as loading indicators, success states, error messages, or
/// progress visualization to update reactively.
///
/// Usage example:
/// ```
/// AwesomeTaskObserver.byTaskId(
///   taskId: 'fetch-user',
///   builder: (context, statusSnapshot) {
///     final status = statusSnapshot.data;
///     if (status?.isExecuting == true) return const CircularProgressIndicator();
///     if (status?.isError == true) return Text('Error: ${status?.lastException}');
///     return Text('Data loaded!');
///   },
/// );
/// ```
class AwesomeTaskObserver<T> extends StatefulWidget {
  final String? taskId, managerId;
  final AsyncWidgetBuilder<TaskStatus?> builder;

  /// Creates an observer that listens to all task activity globally.
  ///
  /// Typically used for dashboards or controller layers that watch multiple tasks.
  factory AwesomeTaskObserver({
    required AsyncWidgetBuilder<TaskStatus?> builder,
  }) =>
      AwesomeTaskObserver._(
        builder: builder,
        managerId: null,
        taskId: null,
      );

  /// Creates an observer that listens only to tasks associated with the given [managerId].
  ///
  /// Useful for independent functional domains such as modules or feature blocks.
  factory AwesomeTaskObserver.byManagerId({
    required AsyncWidgetBuilder<TaskStatus?> builder,
    required String managerId,
  }) =>
      AwesomeTaskObserver._(
        builder: builder,
        managerId: managerId,
        taskId: null,
      );

  /// Creates an observer that listens only to updates from a specific task identified by [taskId].
  ///
  /// Useful when binding the UI to a single task execution flow.
  factory AwesomeTaskObserver.byTaskId({
    required AsyncWidgetBuilder<TaskStatus?> builder,
    required String taskId,
  }) =>
      AwesomeTaskObserver._(
        builder: builder,
        managerId: null,
        taskId: taskId,
      );

  /// Private base constructor used by factory constructors to target specific task scopes.
  const AwesomeTaskObserver._({
    required this.managerId,
    required this.taskId,
    required this.builder,
    super.key,
  });

  @override
  State<AwesomeTaskObserver<T>> createState() => _AwesomeTaskObserverState<T>();
}

class _AwesomeTaskObserverState<T> extends State<AwesomeTaskObserver<T>> {
  late final Stream<TaskStatus?> stream;

  /// Initializes the status stream based on the provided task or manager configuration.
  @override
  void initState() {
    stream = widget.managerId != null
        ? AwesomeTaskManager()
            .getManagerTaskStatusStream(managerId: widget.managerId)
        : AwesomeTaskManager().getTaskStatusStream(taskId: widget.taskId);
    super.initState();
  }

  /// Builds and returns a [StreamBuilder] that responds to updates from the task status stream.
  ///
  /// Each rebuild logs a message for debugging visibility.
  @override
  Widget build(BuildContext context) => StreamBuilder<TaskStatus?>(
        stream: stream,
        builder: (context, snapshot) {
          AwesomeTaskManager()
              .log('AwesomeTaskObserver rebuilt for taskId: ${widget.taskId}');
          return widget.builder(context, snapshot);
        },
      );
}
