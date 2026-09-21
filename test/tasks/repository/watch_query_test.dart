import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:santian/tasks/repository/watch_query.dart';

void main() {
  late StreamController<void> changes;

  setUp(() => changes = StreamController<void>.broadcast());
  tearDown(() => changes.close());

  test('emits a first read as soon as it is listened to', () async {
    final stream = watchQuery(changes.stream, () async => 1);

    expect(await stream.first, 1);
  });

  test('reads again on every change', () async {
    var n = 0;
    final seen = <int>[];
    final sub = watchQuery(changes.stream, () async => ++n).listen(seen.add);
    await pumpEventQueue();

    changes.add(null);
    await pumpEventQueue();
    changes.add(null);
    await pumpEventQueue();

    expect(seen, [1, 2, 3]);
    await sub.cancel();
  });

  test('a change that arrives during a read is not lost', () async {
    // The first read is slow and a change lands while it runs.
    final firstRead = Completer<int>();
    var reads = 0;
    final seen = <int>[];
    final sub = watchQuery(changes.stream, () {
      reads++;
      return reads == 1 ? firstRead.future : Future.value(reads);
    }).listen(seen.add);
    await pumpEventQueue();

    changes.add(null);
    await pumpEventQueue();
    firstRead.complete(1);
    await pumpEventQueue();

    expect(seen.last, 2, reason: 'the read after the change must be emitted last');
    await sub.cancel();
  });

  test('reads never overlap, and a burst of changes costs one extra read', () async {
    var active = 0;
    var maxActive = 0;
    var reads = 0;
    final gate = Completer<void>();
    final sub = watchQuery(changes.stream, () async {
      reads++;
      active++;
      if (active > maxActive) maxActive = active;
      if (reads == 1) await gate.future;
      active--;
      return reads;
    }).listen((_) {});
    await pumpEventQueue();

    for (var i = 0; i < 5; i++) {
      changes.add(null);
    }
    await pumpEventQueue();
    gate.complete();
    await pumpEventQueue();

    expect(maxActive, 1);
    expect(reads, 2, reason: 'the initial read plus one for the whole burst');
    await sub.cancel();
  });

  test('cancelling stops emissions and stops listening for changes', () async {
    var reads = 0;
    final seen = <int>[];
    final sub = watchQuery(changes.stream, () async => ++reads).listen(seen.add);
    await pumpEventQueue();
    await sub.cancel();

    changes.add(null);
    await pumpEventQueue();

    expect(seen, [1]);
    expect(reads, 1);
    expect(changes.hasListener, isFalse);
  });

  test('a failing read is reported and the stream keeps working', () async {
    var reads = 0;
    final values = <int>[];
    final errors = <Object>[];
    final sub = watchQuery(changes.stream, () async {
      reads++;
      if (reads == 1) throw StateError('boom');
      return reads;
    }).listen(values.add, onError: errors.add);
    await pumpEventQueue();

    changes.add(null);
    await pumpEventQueue();

    expect(errors, hasLength(1));
    expect(values, [2]);
    await sub.cancel();
  });
}
