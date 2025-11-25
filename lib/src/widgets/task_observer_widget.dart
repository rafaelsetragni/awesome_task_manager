import 'package:awesome_task_manager/awesome_task_manager.dart';
import 'package:flutter/cupertino.dart';

class AwesomeTaskObserver<T> extends StatefulWidget {
  final String? taskId, managerId;
  final AsyncWidgetBuilder<TaskStatus?> builder;

  factory AwesomeTaskObserver({
    required AsyncWidgetBuilder<TaskStatus?> builder,
  }) =>
      AwesomeTaskObserver._(
        builder: builder,
        managerId: null,
        taskId: null,
      );

  factory AwesomeTaskObserver.byManagerId({
    required AsyncWidgetBuilder<TaskStatus?> builder,
    required String managerId,
  }) =>
      AwesomeTaskObserver._(
        builder: builder,
        managerId: managerId,
        taskId: null,
      );

  factory AwesomeTaskObserver.byTaskId({
    required AsyncWidgetBuilder<TaskStatus?> builder,
    required String taskId,
  }) =>
      AwesomeTaskObserver._(
        builder: builder,
        managerId: null,
        taskId: taskId,
      );

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

  @override
  void initState() {
    stream = widget.managerId != null
        ? AwesomeTaskManager()
            .getManagerTaskStatusStream(managerId: widget.managerId)
        : AwesomeTaskManager().getTaskStatusStream(taskId: widget.taskId);
    super.initState();
  }

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
