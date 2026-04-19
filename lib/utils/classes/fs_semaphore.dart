import 'dart:async';
import 'dart:collection';

// ---------------------------------------------------------------------------
// FsSemaphore — permit-based concurrency limiter
// ---------------------------------------------------------------------------

/// Limits concurrent async operations to a fixed number of permits.
///
/// Callers [acquire] a permit before starting I/O and [release] it in a
/// `finally` block when the I/O completes (or throws).
class FsSemaphore {
  FsSemaphore(int permits) : _availablePermits = permits;

  int _availablePermits;
  final Queue<Completer<void>> _waiters = Queue();

  /// Acquires a permit. If no permits are available, waits until one is
  /// released by another caller.
  Future<void> acquire() {
    if (_availablePermits > 0) {
      _availablePermits--;
      return Future.value();
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    return completer.future;
  }

  /// Releases a previously acquired permit, waking the oldest waiter if any.
  void release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeFirst().complete();
    } else {
      _availablePermits++;
    }
  }
}
