import 'dart:convert';
import 'dart:io';

import 'package:codecore/services/online/http_client.dart';
import 'package:codecore/services/online/musicbrainz_client.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_test/flutter_test.dart';

Object _fixture(String name) =>
    jsonDecode(File('test/fixtures/musicbrainz/$name.json').readAsStringSync()) as Object;

class _Web implements WebClient {
  _Web(this.votes);

  final int votes;
  final asked = <String>[];

  @override
  Future<Object?> getJson(String url, {Map<String, String>? query, CancelToken? cancel}) async {
    asked.add(url);
    if (url.endsWith('/recording')) return _fixture('recording_search_official');
    if (url.contains('/recording/')) {
      return {'genres': [{'name': 'folk rock', 'count': votes}]};
    }
    return _fixture('artist_genres');
  }

  @override
  Future<List<int>?> getBytes(String url, {int maxBytes = 0, CancelToken? cancel}) async => null;
}

MusicBrainzClient _mb(_Web w) => MusicBrainzClient(w, pause: (_) async {});

void main() {
  _masterTests();
  test('two votes on the recording: its own genre, capitalised', () async {
    final w = _Web(2);
    expect(await _mb(w).genreFor('Viva la Vida', 'Coldplay', 244000), 'Folk Rock');
    expect(w.asked.any((u) => u.contains('/artist/')), isFalse);
  });

  test('one vote on the recording: the artist\'s top genre stands in', () async {
    expect(await _mb(_Web(1)).genreFor('Viva la Vida', 'Coldplay', 244000), 'Alternative Rock');
  });

  test('a recording of another length is not used', () async {
    final w = _Web(2);
    await _mb(w).genreFor('Viva la Vida', 'Coldplay', 244000);
    expect(w.asked.any((u) => u.contains('b57c0ec1')), isFalse, reason: 'the 114 s one is far');
    expect(w.asked.any((u) => u.contains('70b12d65')), isTrue);
  });
}

class _MasterWeb implements WebClient {
  @override
  Future<Object?> getJson(String url, {Map<String, String>? query, CancelToken? cancel}) async {
    if (url.contains('/recording/')) {
      return {
        'releases': [
          {'release-group': {'id': 'comp', 'primary-type': 'Album', 'secondary-types': ['Compilation']}},
          {'release-group': {'id': 'album', 'primary-type': 'Album', 'secondary-types': []}},
        ]
      };
    }
    if (url.endsWith('/release-group/album')) {
      return {
        'relations': [
          {'type': 'discogs', 'url': {'resource': 'https://www.discogs.com/master/4242'}}
        ]
      };
    }
    throw StateError('compilation must not be asked: $url');
  }

  @override
  Future<List<int>?> getBytes(String url, {int maxBytes = 0, CancelToken? cancel}) async => null;
}

void _masterTests() {
  test('Discogs master: a compilation listed first is skipped', () async {
    expect(await MusicBrainzClient(_MasterWeb(), pause: (_) async {}).discogsMasterOf('r1'), 4242);
  });
}
