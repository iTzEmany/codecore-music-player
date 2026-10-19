import 'dart:isolate';

import 'package:xml/xml.dart';

import '../../core/text_utils.dart';
import 'podcast_models.dart';

/// Reads an RSS 2.0 podcast feed (with the `itunes:` tags) off the main
/// isolate. Anything that is not RSS (Atom, an HTML page) is a
/// [FormatException].
Future<PodcastFeed> parseFeed(String xml) => Isolate.run(() => parseFeedSync(xml));

PodcastFeed parseFeedSync(String xml) {
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(xml);
  } on XmlException catch (e) {
    throw FormatException('not a feed: ${e.message}');
  }
  final root = doc.rootElement;
  if (root.name.local != 'rss') throw const FormatException('not an RSS feed');
  final channel = root.getElement('channel');
  if (channel == null) throw const FormatException('RSS without a channel');

  final items = channel.findElements('item');
  var skipped = 0;
  final episodes = <PodcastEpisodeInfo>[];
  for (final item in items) {
    final e = _episode(item);
    if (e == null) {
      skipped++;
    } else {
      episodes.add(e);
    }
  }
  return PodcastFeed(
    title: _text(channel, 'title') ?? '',
    author: _text(channel, 'itunes:author') ?? _text(channel, 'author'),
    description: _plain(_text(channel, 'description') ?? _text(channel, 'itunes:summary')),
    imageUrl: channel.getElement('itunes:image')?.getAttribute('href') ??
        channel.getElement('image')?.getElement('url')?.innerText.trim(),
    language: _text(channel, 'language'),
    episodes: episodes,
    skipped: skipped,
  );
}

String? _text(XmlElement parent, String name) {
  final t = parent.getElement(name)?.innerText.trim();
  return (t == null || t.isEmpty) ? null : t;
}

const _audioExtensions = {'mp3', 'm4a', 'aac', 'ogg', 'oga', 'opus', 'wav', 'flac', 'mp4'};

bool _isAudio(String url, String? type) {
  final t = (type ?? '').toLowerCase();
  if (t.startsWith('audio/')) return true;
  if (t.startsWith('video/') && t != 'video/mp4') return false;
  final path = Uri.tryParse(url)?.path ?? url;
  final dot = path.lastIndexOf('.');
  return dot >= 0 && _audioExtensions.contains(path.substring(dot + 1).toLowerCase());
}

PodcastEpisodeInfo? _episode(XmlElement item) {
  final enclosure = item.getElement('enclosure');
  final url = enclosure?.getAttribute('url')?.trim();
  if (url == null || url.isEmpty) return null;
  final type = enclosure!.getAttribute('type')?.trim();
  if (!_isAudio(url, type)) return null;
  final guid = _text(item, 'guid') ?? url;
  return PodcastEpisodeInfo(
    guid: guid,
    title: _plain(_text(item, 'title')) ?? guid,
    audioUrl: url,
    publishedAt: parseRfc822(_text(item, 'pubDate')),
    duration: parseItunesDuration(_text(item, 'itunes:duration')),
    mimeType: type == null || type.isEmpty ? null : type,
    sizeBytes: int.tryParse(enclosure.getAttribute('length')?.trim() ?? ''),
    description: _plain(_text(item, 'description') ?? _text(item, 'itunes:summary') ?? _text(item, 'content:encoded')),
  );
}

/// `3600`, `45:10`, `1:02:03` (also `1:02:03.5`) → a duration; null if it is
/// none of those.
Duration? parseItunesDuration(String? raw) {
  if (raw == null) return null;
  final parts = raw.trim().split(':');
  if (parts.isEmpty || parts.length > 3) return null;
  final nums = [for (final p in parts) double.tryParse(p)];
  if (nums.any((n) => n == null || n < 0)) return null;
  var seconds = 0.0;
  for (final n in nums) {
    seconds = seconds * 60 + n!;
  }
  return Duration(milliseconds: (seconds * 1000).round());
}

const _months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
const _zones = {
  'ut': 0, 'utc': 0, 'gmt': 0, 'z': 0,
  'est': -5, 'edt': -4, 'cst': -6, 'cdt': -5, 'mst': -7, 'mdt': -6, 'pst': -8, 'pdt': -7,
};
final _rfc822 = RegExp(
    r'^(?:[A-Za-z]{3,9},?\s+)?(\d{1,2})\s+([A-Za-z]{3,9})\s+(\d{2,4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([+-]\d{4}|[A-Za-z]{1,4})?$');

/// `Mon, 18 Oct 2021 05:45:16 +0000` and its looser cousins, as UTC; null when
/// it does not read as a date.
DateTime? parseRfc822(String? raw) {
  if (raw == null) return null;
  final m = _rfc822.firstMatch(raw.trim());
  if (m == null) return null;
  final month = _months.indexOf(m[2]!.substring(0, 3).toLowerCase()) + 1;
  if (month == 0) return null;
  var year = int.parse(m[3]!);
  if (m[3]!.length == 2) year += year < 50 ? 2000 : 1900;
  final day = int.parse(m[1]!), hour = int.parse(m[4]!), minute = int.parse(m[5]!);
  final second = int.tryParse(m[6] ?? '0') ?? 0;
  if (day < 1 || day > 31 || hour > 23 || minute > 59 || second > 60) return null;
  var offset = Duration.zero;
  final z = m[7];
  if (z != null) {
    if (z.startsWith('+') || z.startsWith('-')) {
      final sign = z.startsWith('-') ? -1 : 1;
      offset = Duration(hours: sign * int.parse(z.substring(1, 3)), minutes: sign * int.parse(z.substring(3, 5)));
    } else {
      final h = _zones[z.toLowerCase()];
      if (h == null) return null;
      offset = Duration(hours: h);
    }
  }
  final utc = DateTime.utc(year, month, day, hour, minute, second);
  if (utc.month != month) return null; // 31 Feb and the like
  return utc.subtract(offset);
}

final _tag = RegExp(r'<[^>]*>');
final _breaks = RegExp(r'<\s*(?:br\s*/?|/p|/div|/li)\s*>', caseSensitive: false);

/// A description as plain text: tags out (breaks become newlines), entities
/// decoded, blank runs collapsed. Null for nothing.
String? _plain(String? html) {
  if (html == null) return null;
  var s = html.replaceAll(_breaks, '\n').replaceAll(_tag, '');
  s = htmlUnescape(s).replaceAll('&nbsp;', ' ').replaceAll(' ', ' ');
  s = s.replaceAll(RegExp(r'[ \t]+'), ' ').replaceAll(RegExp(r' ?\n ?'), '\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  return s.isEmpty ? null : s;
}
