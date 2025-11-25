import 'dart:async';

/// A lightweight observable stream wrapper that supports value replay and listener tracking.
///
/// [ObservableStream] stores the latest emitted value and immediately delivers
/// it to new listeners upon subscription. It also tracks active listener count
/// and optionally triggers [onZeroListeners] when the last listener disconnects.
///
/// Useful for UI bindings, state propagation, and real-time monitoring channels.
class ObservableStream<T> {
  /// Internal broadcast stream controller responsible for event delivery.
  ///
  /// Broadcast mode allows multiple listeners to receive events simultaneously.
  final _controller = StreamController<T>.broadcast();

  /// Holds the most recent emitted value, if any, enabling replay behavior for new subscribers.
  T? _currentValue;

  /// Tracks how many listeners are currently subscribed to the stream.
  int _listenerCount = 0;

  /// Optional callback invoked when the last active listener unsubscribes.
  ///
  /// Useful for resource cleanup, auto-closing connections, or task disposal.
  final void Function()? onZeroListeners;

  /// Creates an observable stream with an optional initial value and cleanup callback.
  ///
  /// [initialValue] is emitted immediately upon subscription.
  /// [onZeroListeners] is called when no listeners remain.
  ObservableStream({T? initialValue, this.onZeroListeners})
      : _currentValue = initialValue;

  /// Increases the internal listener tracking counter.
  void _incrementListenerCount() {
    _listenerCount++;
  }

  /// Decreases the listener count and triggers [onZeroListeners] when it reaches zero.
  void _decrementListenerCount() {
    _listenerCount--;
    if (_listenerCount == 0) {
      onZeroListeners?.call();
    }
  }

  /// Number of currently active stream listeners.
  int get listenerCount => _listenerCount;

  /// The most recently emitted value, or `null` if none has been emitted.
  T? get valueOrNull => _currentValue;

  /// Emits a new event and updates the stored replay value.
  void add(T value) {
    _currentValue = value;
    _controller.add(value);
  }

  /// Emits an error event to all active listeners.
  void addError(Object error, [StackTrace? stackTrace]) {
    _controller.addError(error, stackTrace);
  }

  /// Returns a stream that:
  ///  * immediately emits the latest stored value (if any)
  ///  * yields all subsequent values from the internal controller
  ///  * tracks listener count and invokes cleanup when the listener disconnects
  Stream<T?> get stream async* {
    _incrementListenerCount();
    yield _currentValue;

    try {
      // Yield all events from the controller's stream
      yield* _controller.stream;
    } finally {
      _decrementListenerCount();
    }
  }

  /// Closes the underlying stream controller.
  ///
  /// Once closed, no further events can be emitted.
  Future<void> close() => _controller.close();

  /// Indicates whether the stream has been closed.
  bool get isClosed => _controller.isClosed;
}
