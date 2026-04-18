# Skill: Worker Isolate Communication

**Applies when**: Creating or modifying code that spawns Dart isolates for background work (scanning, hashing, file comparison, bulk operations, export).

**Constitution references**: Principle II (Performance Engineering), Principle XIV (Worker Isolate Communication Protocol)

---

## Core Pattern: Main-Isolate Adapter + Worker Entrypoint

Every background operation follows a two-class pattern:

1. **Repository Impl** (main isolate) — `*_repository_impl.dart` in `lib/repository/`
   - Implements the abstract repository interface
   - Owns all `Isolate.spawn`, `SendPort`/`ReceivePort` wiring
   - Translates typed `Map<String, dynamic>` messages back into domain objects
   - The Cubit never sees isolates, ports, or raw messages

2. **Worker Entrypoint** (top-level function) — in the same file, below the class
   - MUST be a top-level function (Dart `Isolate.spawn` requirement)
   - Receives a single `Map<String, dynamic>` spawn message
   - Creates local instances of services, cache repositories, and cancel tokens
   - Sends results back via `SendPort`

---

## ObjectBox Sharing

```dart
// CORRECT — worker attaches to the main isolate's store
final Store? store = storePath.isNotEmpty
    ? Store.attach(getObjectBoxModel(), storePath)
    : null;

// WRONG — opens a competing store, causes file-lock contention on Windows
final store = Store(getObjectBoxModel(), directory: storePath); // NEVER DO THIS
```

**Rules**:

- Main isolate opens `Store` once in `main()` via `await openStore()`
- `storePath` (`String`) is passed in the spawn message
- Worker calls `Store.attach(getObjectBoxModel(), storePath)`
- If `storePath` is empty, fall back to a no-op cache implementation
- Worker MUST close the store in a `finally` block:

```dart
try {
  // ... pipeline work ...
} finally {
  store?.close(); // ALWAYS — even on cancellation or error
}
```

---

## Cancel Handshake Protocol

The two-phase handshake bridges `CancelToken.cancel()` from main isolate to worker:

### Step 1: Spawn message includes handshake port

```dart
final handshakeRp = ReceivePort();

await Isolate.spawn<Map<String, dynamic>>(_workerEntrypoint, {
  'cancelHandshakePort': handshakeRp.sendPort,
  'progressPort': resultRp.sendPort,
  // ... other params as primitives/strings/lists only ...
});
```

### Step 2: Worker sends back its cancel SendPort

```dart
Future<void> _workerEntrypoint(Map<String, dynamic> message) async {
  final localCancelToken = CancelToken();

  final cancelRp = ReceivePort();
  cancelRp.first.then((_) => localCancelToken.cancel());
  final handshakePort = message['cancelHandshakePort'] as SendPort;
  handshakePort.send(cancelRp.sendPort);

  // ... use localCancelToken throughout pipeline ...
}
```

### Step 3: Main isolate wires the bridge

```dart
final workerCancelSendPort = await handshakeRp.first as SendPort;
handshakeRp.close();

cancelToken.cancelFuture.then((_) => workerCancelSendPort.send('cancel'));
```

**Key**: The Cubit only calls `cancelToken.cancel()`. It MUST NOT touch ports.

---

## Message Format

All worker→main messages MUST be `Map<String, dynamic>` with a `'type'` discriminator:

```dart
// Worker sends:
progressPort.send({
  'type': 'progress',
  'stageTotal': p.stageTotal,
  'stageProcessed': p.stageProcessed,
  'stage': p.stage,
  'currentPath': p.currentPath,
});

progressPort.send({
  'type': 'group',
  'paths': group.paths,        // List<String> — serializable
  'sizes': sizes,              // List<int> — serializable
});

progressPort.send({
  'type': 'result',
  'groups': groups.map((g) => g.paths).toList(),
});

progressPort.send({
  'type': 'error',
  'cancelled': true,
  'message': e.message,
});
```

**Main isolate dispatches** using a switch on `msg['type']`:

```dart
resultRp.listen((raw) {
  final msg = raw as Map<String, dynamic>;
  switch (msg['type'] as String) {
    case 'progress':
      onProgress(ScanProgress(...));
    case 'group':
      onGroupFound?.call(group, sizes);
    case 'result':
      completer.complete(groups);
      resultRp.close();
    case 'error':
      completer.completeError(...);
      resultRp.close();
  }
});
```

**FORBIDDEN across isolate boundaries**: native pointers, `Store`, `Box<T>`, `File`, `RandomAccessFile`, `DynamicLibrary`.

---

## Semaphore-Guarded I/O

Concurrent file operations MUST be bounded by a permit-based semaphore:

```dart
class _Semaphore {
  _Semaphore(int permits) : _availablePermits = permits;
  int _availablePermits;
  final Queue<Completer<void>> _waiters = Queue();

  Future<void> acquire() { /* ... */ }
  void release() { /* ... */ }
}
```

**Usage pattern** — ALWAYS `try/finally`:

```dart
await _semaphore.acquire();
try {
  cancelToken.throwIfCancelled();
  final hash = HashUtils.partialHash(meta.path);
  return MapEntry(meta, hash);
} finally {
  _semaphore.release(); // ALWAYS — even on exception
}
```

Default concurrency limit: **4**. Configurable via constructor parameter.

---

## Checklist Before Submitting Isolate Code

- [ ] Worker uses `Store.attach()`, not `Store()`
- [ ] Worker closes `Store` in a `finally` block
- [ ] Cancel handshake follows the 3-step protocol
- [ ] All messages are `Map<String, dynamic>` with `'type'` discriminator
- [ ] No non-serializable objects cross the isolate boundary
- [ ] Every `_semaphore.acquire()` has a matching `release()` in `finally`
- [ ] `cancelToken.throwIfCancelled()` is called before every I/O operation
- [ ] The Cubit never touches `SendPort`/`ReceivePort` directly
