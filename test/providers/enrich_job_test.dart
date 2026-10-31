import 'package:codecore/providers/online_providers.dart';
import 'package:codecore/services/online/enrichment_service.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Breaking extends _Service {
  _Breaking() : super(const BatchProgress());

  @override
  Stream<BatchProgress> enrichMany(List<int> ids,
          {CancelToken? cancel,
          bool includeLyrics = true,
          bool includeCuriosities = false,
          bool includeMetadata = true,
          bool force = false}) async* {
    yield const BatchProgress(done: 2, total: 5, updated: 1, notFound: 1);
    throw StateError('boom');
  }
}

class _Service implements EnrichmentService {
  _Service(this.last);

  final BatchProgress last;

  @override
  Stream<BatchProgress> enrichMany(List<int> ids,
          {CancelToken? cancel,
          bool includeLyrics = true,
          bool includeCuriosities = false,
          bool includeMetadata = true,
          bool force = false}) =>
      Stream.value(last);

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

void main() {
  Future<int> finishedCalls(BatchProgress last) async {
    final c = ProviderContainer(overrides: [enrichmentServiceProvider.overrideWithValue(_Service(last))]);
    addTearDown(c.dispose);
    var calls = 0;
    c.read(enrichJobProvider.notifier).start([1], onFinished: () => calls++);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    return calls;
  }

  test('onFinished runs when the job ends, not when it was cancelled', () async {
    expect(await finishedCalls(const BatchProgress(finished: true)), 1);
    expect(await finishedCalls(const BatchProgress(finished: true, cancelled: true)), 0);
  });

  test('a job that breaks keeps its counts, is marked failed and does not finish', () async {
    final c = ProviderContainer(overrides: [enrichmentServiceProvider.overrideWithValue(_Breaking())]);
    addTearDown(c.dispose);
    var calls = 0;
    c.read(enrichJobProvider.notifier).start([1, 2, 3, 4, 5], onFinished: () => calls++);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    final s = c.read(enrichJobProvider);
    expect([s.running, s.failed, s.result?.updated, s.result?.notFound], [false, true, 1, 1]);
    expect(calls, 0);
  });
}
