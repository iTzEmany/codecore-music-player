import 'dart:convert';
import 'dart:io';

import 'package:codecore/services/online/http_client.dart';
import 'package:codecore/services/online/musicbrainz_client.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_test/flutter_test.dart';

Object _fixture(String name) =>
    jsonDecode(File('test/fixtures/musicbrainz/$name.json').readAsStringSync()) as Object;

class _Web implements WebClient {
  _Web({this.isrcAnswer = 'isrc_two_recordings'});
  final String? isrcAnswer;
  final asked = <String>[];

  @override
  Future<Object?> getJson(String url, {Map<String, String>? query, CancelToken? cancel}) async {
    asked.add(url);
    if (url.contains('/isrc/')) {
      expect(query?['inc'], 'artist-credits');
      return isrcAnswer == null ? null : _fixture(isrcAnswer!);
    }
    if (url.endsWith('/recording')) return _fixture('recording_search_official');
    if (url.contains('/recording/')) {
      return {'genres': [{'name': 'rock', 'count': 5}]};
    }
    return null;
  }

  @override
  Future<List<int>?> getBytes(String url, {int maxBytes = 0, CancelToken? cancel}) async => null;
}

MusicBrainzClient _mb(_Web w) => MusicBrainzClient(w, pause: (_) async {});

void main() {
  test('two recordings with the ISRC: the one with the closest length first', () async {
    final recs = await _mb(_Web()).recordingsByIsrc('gbaye1000769', 187500, title: 'Imagine', artist: 'John Lennon');
    expect(recs.map((r) => r.id), ['d583f8f4-34bc-4f68-a72e-0a766382b96a', 'ec04e3c5-0548-4e73-bfc3-19a26108f302']);
  });

  test('genre with an ISRC: looked up by it, no text search', () async {
    final w = _Web();
    expect(await _mb(w).genreFor('Imagine', 'John Lennon', 184000, isrc: 'GBAYE1000769'), 'Rock');
    expect(w.asked.any((u) => u.endsWith('/isrc/GBAYE1000769')), isTrue);
    expect(w.asked.any((u) => u.endsWith('/recording')), isFalse);
    expect(w.asked.any((u) => u.contains('/recording/ec04e3c5')), isTrue);
  });

  test('genre without an ISRC: the text search as before', () async {
    final w = _Web();
    await _mb(w).genreFor('Viva la Vida', 'Coldplay', 244000);
    expect(w.asked.any((u) => u.contains('/isrc/')), isFalse);
    expect(w.asked.any((u) => u.endsWith('/recording')), isTrue);
  });

  test('unknown ISRC (404): asked once, then the text search', () async {
    final w = _Web(isrcAnswer: null);
    await _mb(w).genreFor('Viva la Vida', 'Coldplay', 244000, isrc: 'XX0000000000');
    expect(w.asked.where((u) => u.contains('/isrc/')).length, 1);
    expect(w.asked.any((u) => u.endsWith('/recording')), isTrue);
  });

  test('ISRC recording with another title and artist: rejected, text search', () async {
    final w = _Web();
    await _mb(w).genreFor('Viva la Vida', 'Coldplay', 187500, isrc: 'GBAYE1000769');
    expect(w.asked.any((u) => u.endsWith('/recording')), isTrue);
    expect(w.asked.any((u) => u.contains('/recording/ec04e3c5')), isFalse);
  });
}
