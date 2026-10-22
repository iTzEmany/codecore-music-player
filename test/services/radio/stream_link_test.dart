import 'package:codecore/services/radio/stream_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<String> fetching(String body) => Future.value(body);

  StreamLinkError? errorOf(String text) {
    try {
      parseStreamLink(text);
    } on StreamLinkException catch (e) {
      return e.reason;
    }
    return null;
  }

  test('an http or https address is direct; an .m3u8 (HLS) too', () {
    expect(parseStreamLink(' https://a.example/live.mp3 ').url, 'https://a.example/live.mp3');
    expect(parseStreamLink('http://a.example:8000/stream'), isA<DirectLink>());
    expect(parseStreamLink('https://a.example/hls/index.m3u8'), isA<DirectLink>());
  });

  test('.pls and .m3u addresses are playlist files, whatever the case or query', () {
    expect(parseStreamLink('http://a.example/radio.PLS?x=1'), isA<PlaylistLink>());
    expect(parseStreamLink('https://a.example/radio.m3u'), isA<PlaylistLink>());
  });

  test('text that is not a usable address says why', () {
    expect(errorOf(''), StreamLinkError.empty);
    expect(errorOf('radio uno'), StreamLinkError.notAnAddress);
    expect(errorOf('radiouno.it'), StreamLinkError.notAnAddress);
    expect(errorOf('ftp://a.example/x'), StreamLinkError.badScheme);
    expect(errorOf('file:///home/x.mp3'), StreamLinkError.badScheme);
    expect(errorOf('http://'), StreamLinkError.notAnAddress);
  });

  test('a .pls gives its File1 entry, not the titles or lengths', () async {
    const pls = '[playlist]\nNumberOfEntries=2\nTitle1=http://wrong\nFile1=http://s.example/one\n'
        'Length1=-1\nFile2=http://s.example/two\nVersion=2\n';
    expect(await resolveStreamLink('http://a.example/r.pls', (_) => fetching(pls)),
        'http://s.example/one');
  });

  test('an .m3u gives its first http entry, skipping comments and relative lines', () async {
    const m3u = '#EXTM3U\r\n#EXTINF:-1,Radio\r\n\r\nlocal/file.mp3\r\nhttps://s.example/live\r\n';
    expect(await resolveStreamLink('https://a.example/r.m3u', (_) => fetching(m3u)),
        'https://s.example/live');
  });

  test('a playlist file without entries, too big or not downloadable is an error', () async {
    Future<StreamLinkError?> err(Future<String> Function(Uri) fetch) async {
      try {
        await resolveStreamLink('http://a.example/r.pls', fetch);
      } on StreamLinkException catch (e) {
        return e.reason;
      }
      return null;
    }

    expect(await err((_) => fetching('[playlist]\nNumberOfEntries=0\n')), StreamLinkError.noEntries);
    expect(await err((_) => fetching('x' * (kMaxPlaylistBytes + 1))), StreamLinkError.tooBig);
    expect(await err((_) => throw Exception('offline')), StreamLinkError.fetchFailed);
  });

  test('a direct address is not downloaded', () async {
    final url = await resolveStreamLink('http://a.example/s', (_) => throw StateError('no'));
    expect(url, 'http://a.example/s');
  });
}
