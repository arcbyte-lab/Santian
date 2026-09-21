import 'dart:async';

/// A stream of [read]'s result that re-reads whenever [changes] fires.
///
/// Isar's own `query.watch()` registers its native watcher at the moment it is
/// called, and a watcher registered while a write is in flight can miss that
/// write entirely: its first read predates the commit and the commit's
/// notification never arrives (measured: 38 misses in 40 tries, against none
/// when the watcher was registered first). Repositories therefore register one
/// long-lived collection watcher when they are created and pass it here as
/// [changes]. Each subscriber subscribes to it before its first read, so a
/// write can no longer fall between the two.
///
/// Reads never overlap. A change that arrives during a read schedules exactly
/// one more read, so the last value emitted always reflects the last change.
Stream<T> watchQuery<T>(Stream<void> changes, Future<T> Function() read) {
  late final StreamController<T> controller;
  StreamSubscription<void>? subscription;
  var canceled = false;
  var reading = false;
  var readAgain = false;

  Future<void> refresh() async {
    if (reading) {
      readAgain = true;
      return;
    }
    reading = true;
    try {
      do {
        readAgain = false;
        try {
          final value = await read();
          if (!canceled) controller.add(value);
        } catch (error, stackTrace) {
          if (!canceled) controller.addError(error, stackTrace);
        }
      } while (readAgain && !canceled);
    } finally {
      reading = false;
    }
  }

  controller = StreamController<T>(
    onListen: () {
      subscription = changes.listen((_) => refresh());
      refresh();
    },
    onCancel: () {
      canceled = true;
      return subscription?.cancel();
    },
  );
  return controller.stream;
}
