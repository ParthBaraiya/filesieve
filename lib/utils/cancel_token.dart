import 'dart:async';

class ScanCancelledException implements Exception {
  final String message;

  ScanCancelledException([this.message = 'Scan was cancelled']);

  @override
  String toString() => 'ScanCancelledException: $message';
}

class CancelToken {
  bool _isCancelled = false;
  final Completer<void> _cancelCompleter = Completer();

  bool get isCancelled => _isCancelled;

  Future<void> get cancelFuture => _cancelCompleter.future;

  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    _cancelCompleter.complete();
  }

  void throwIfCancelled() {
    if (_isCancelled) {
      throw ScanCancelledException();
    }
  }
}
