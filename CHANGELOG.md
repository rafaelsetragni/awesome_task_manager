## 2.0.0

* Simplified status stream accessors: `getTaskStatusStream`, `getManagerTaskStatusStream`, and the internal `getStatusStream` now default to the global stream when no identifier is provided, making subscriptions easier to reason about.
* Updated examples and tests to align with the streamlined stream behavior.
* Introduced typed task outcomes via `TaskResult`, `TaskSuccess`, and `TaskFailure` for clearer result handling.
* Documented the task status streams (`getTaskStatusStream` and `getManagerTaskStatusStream`) reflecting the simplified API and providing usage examples in README.
* Updated example loading overlay to cover the entire screen while reset tasks run.

## 1.0.1

* Prepared for publishing on pub.dev with high documentation coverage.
* Fixed incorrect image and banner paths in README, ensuring assets render properly on pub.dev and GitHub.
* Added extensive documentation for all public classes, methods, streams, observers, resolvers and lifecycle internals.
* Fully documented core architecture (TaskState, TaskStatus, TaskResolver, CancelableTask, ObservableStream).

## 1.0.0

* **Initial release of Awesome Task Manager!**
* This release introduces a powerful and flexible way to manage background tasks in your Flutter applications.
* **Core Features:**
    * **Task Management:** A robust system for executing, canceling, and observing tasks.
    * **Task State Management:** Clear and predictable state management for tasks (`isExecuting`, `isCompleted`, `isCanceled`, `isError`).
    * **Observable Streams:** Get real-time updates on task status using streams.
* **Available Task Resolvers:**
    * `SharedResultResolver`: Avoids re-executing the same task by sharing the result among concurrent callers.
    * `SequentialQueueResolver`: Executes tasks one by one in a sequential queue.
    * `TaskPoolManager`: Manages a pool of tasks to control concurrency.
    * `CancelPreviousResolver`: Cancels the previous task when a new one with the same ID is executed.
    * `RejectAfterThresholdResolver`: Rejects new tasks when a certain threshold is reached.
* **Widgets:**
    * `AwesomeTaskObserver`: A widget that rebuilds when the status of a task changes.
* **Logging:**
    * A simple logging system to help to intercept and debug task executions.
