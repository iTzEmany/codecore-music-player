import 'package:codecore/providers/online_providers.dart';
import 'package:codecore/services/online/enrichment_service.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
