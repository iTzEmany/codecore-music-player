import 'dart:io';

import 'package:codecore/services/podcast/rss_parser.dart';
import 'package:flutter_test/flutter_test.dart';

String feed(String f) => File('test/fixtures/podcast_$f.xml').readAsStringSync();

String rss(String items, {String channel = '<title>Show</title>'}) =>
    '<?xml version="1.0"?><rss version="2.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" '
    'xmlns:content="http://purl.org/rss/1.0/modules/content/"><channel>$channel$items</channel></rss>';

String item(String body) => '<item>$body</item>';
const enc = '<enclosure url="https://x.org/a.mp3" type="audio/mpeg" length="123"/>';

void main() {
  group('the three real feeds', () {
    test('Morning (Italian, seconds, spreaker)', () async {
      final f = await parseFeed(feed('it_morning'));
      expect((f.title, f.author, f.language), ('Morning', 'Francesco Costa - Il Post', 'it'));
      expect(f.imageUrl, startsWith('https://'));
      expect(f.episodes, hasLength(50));
      final e = f.episodes.first;
      expect(e.title, 'Non il centesimo episodio e le altre storie di oggi');
      expect(e.guid, 'https://api.spreaker.com/episode/47008027');
      expect(e.publishedAt, DateTime.utc(2021, 10, 18, 5, 45, 16));
      expect(e.duration, const Duration(minutes: 2, seconds: 24));
      expect((e.mimeType, e.sizeBytes), ('audio/mpeg', 3463636));
    });

    test('Radiolab (hh:mm:ss, CDATA with HTML)', () async {
      final f = await parseFeed(feed('radiolab_seasons'));
      expect((f.title, f.language), ('Radiolab', 'en-us'));
      expect(f.episodes, hasLength(50));
      final e = f.episodes.first;
      expect(e.duration, const Duration(minutes: 43, seconds: 9));
      expect(e.description, isNot(contains('<')));
      expect(e.description, isNot(contains('&nbsp;')));
      expect(e.description, isNotEmpty);
    });

    test('In Our Time (urn guids, http enclosures)', () async {
      final f = await parseFeed(feed('bbc_inourtime'));
      expect(f.episodes, hasLength(50));
      expect(f.episodes.first.guid, 'urn:bbc:podcast:m0031jz3');
      expect(f.episodes.every((e) => e.guid.isNotEmpty), isTrue);
      expect(f.episodes.map((e) => e.guid).toSet().length, f.episodes.length, reason: 'unique');
    });
  });

  group('items', () {
    test('no guid: the enclosure address; no audio enclosure: skipped and counted', () {
      final f = parseFeedSync(rss(
        item('<title>A</title>$enc') +
            item('<title>Text only</title>') +
            item('<title>Video</title><enclosure url="https://x.org/v.mov" type="video/quicktime"/>') +
            item('<title>Typeless</title><enclosure url="https://x.org/t.m4a?x=1"/>'),
      ));
      expect(f.episodes.map((e) => e.title), ['A', 'Typeless']);
      expect(f.episodes.first.guid, 'https://x.org/a.mp3');
      expect(f.skipped, 2);
    });

    test('descriptions lose tags and decode entities', () {
      final f = parseFeedSync(rss(item('<title>A &amp; B</title>$enc<description><![CDATA[<p>Hello <b>world</b> &amp; co&nbsp;now</p><p>Second<br/>line</p>]]></description>')));
      expect(f.episodes.single.title, 'A & B');
      expect(f.episodes.single.description, 'Hello world & co now\nSecond\nline');
    });

    test('the image falls back to <image><url>; the author to nothing', () {
      final f = parseFeedSync(rss('', channel: '<title>S</title><image><url>https://i.org/c.png</url></image>'));
      expect(f.imageUrl, 'https://i.org/c.png');
      expect(f.author, isNull);
    });
  });

  group('durations', () {
    test('seconds, mm:ss, hh:mm:ss, fractions; junk is null', () {
      expect(parseItunesDuration('3600'), const Duration(hours: 1));
      expect(parseItunesDuration('45:10'), const Duration(minutes: 45, seconds: 10));
      expect(parseItunesDuration('1:02:03'), const Duration(hours: 1, minutes: 2, seconds: 3));
      expect(parseItunesDuration('1:02:03.5'), const Duration(hours: 1, minutes: 2, seconds: 3, milliseconds: 500));
      for (final bad in [null, '', 'abc', '1:2:3:4', '-5']) {
        expect(parseItunesDuration(bad), isNull, reason: '$bad');
      }
    });
  });

  group('dates', () {
    test('RFC 822 with offsets, zone names, short years and no weekday', () {
      expect(parseRfc822('Mon, 18 Oct 2021 05:45:16 +0000'), DateTime.utc(2021, 10, 18, 5, 45, 16));
      expect(parseRfc822('Tue, 19 Oct 2021 08:00:00 +0200'), DateTime.utc(2021, 10, 19, 6));
      expect(parseRfc822('Tue, 19 Oct 2021 08:00:00 -0500'), DateTime.utc(2021, 10, 19, 13));
      expect(parseRfc822('19 Oct 21 08:00 GMT'), DateTime.utc(2021, 10, 19, 8));
      expect(parseRfc822('Wed, 20 Oct 2021 08:00:00 EST'), DateTime.utc(2021, 10, 20, 13));
    });
    test('anything else is null instead of an error', () {
      for (final bad in [null, '', 'yesterday', '2021-10-18T05:45:16Z', 'Mon, 31 Feb 2021 10:00:00 +0000', 'Mon, 18 Foo 2021 05:45:16 +0000']) {
        expect(parseRfc822(bad), isNull, reason: '$bad');
      }
    });
  });

  group('not a podcast feed', () {
    test('Atom, HTML and plain text are a FormatException', () async {
      for (final bad in [
        '<feed xmlns="http://www.w3.org/2005/Atom"><title>x</title></feed>',
        '<!DOCTYPE html><html><body><p>hi</p></body></html>',
        'just text',
        '<rss version="2.0"></rss>',
      ]) {
        await expectLater(parseFeed(bad), throwsFormatException, reason: bad);
      }
    });
  });
}
