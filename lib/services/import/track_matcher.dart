import 'package:path/path.dart' as p;

import '../../core/import_row.dart';
import '../../core/text_utils.dart';
import '../online/query_cleaner.dart';
import '../online/youtube_service.dart';
import 'playlist_paths.dart';

final _remasterTail = RegExp(
    r'\s+[-–]\s+(\d{4}\s+)?(digital\s+)?remaster(ed)?\b.*$',
    caseSensitive: false);
final _remasterGroup = RegExp(r'[\(\[][^\)\]]*remaster[^\)\]]*[\)\]]',
    caseSensitive: false);
final _featGroup = RegExp(
    r'[\(\[]\s*(feat|ft|featuring|with)\b[^\)\]]*[\)\]]',
    caseSensitive: false);
final _featTail = RegExp(r'\s+[-–]\s+(feat|ft)\b.*$', caseSensitive: false);
final _editGroup = RegExp(
    r'[\(\[]\s*(radio edit|single version|album version|mono|stereo|explicit|remastered)\s*[\)\]]',
    caseSensitive: false);
final _editTail = RegExp(
    r'\s+[-–]\s+(radio edit|single version|album version|mono|stereo|mono version|stereo version)\s*$',
    caseSensitive: false);
final _nonWord = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

/// Apostrophe-like marks that Unicode files as letters (the Hawaiian ʻokina of
/// «Kamakawiwoʻole», the modifier apostrophe ʼ): they count as punctuation,
/// like the plain ' they stand for.
final _letterApostrophes = RegExp('[\u02B9-\u02BF]');

/// Lower-case, no accents, no punctuation. Used to compare two spellings of
/// the same name.
String matchKey(String s) => normalize(s.replaceAll('&', ' and '))
    .replaceAll(_letterApostrophes, ' ')
    .replaceAll(_nonWord, ' ')
    .trim();

/// [matchKey] of a title without the qualifiers that do not change the
/// recording (remaster year, feat., radio edit). `live`, `remix`... are kept.
String matchTitleKey(String title) => matchKey(title
    .replaceAll(_remasterGroup, ' ')
    .replaceAll(_featGroup, ' ')
    .replaceAll(_editGroup, ' ')
    .replaceAll(_remasterTail, '')
    .replaceAll(_featTail, '')
    .replaceAll(_editTail, ''));

String _artistKey(String artist) => matchKey(extractPrimaryArtist(artist));

/// `title|primary artist` -> library tracks; [find] is O(1) per row.
class LibraryIndex {
  LibraryIndex(Iterable<LibraryEntryLite> tracks) {
    for (final t in tracks) {
      _byKey
          .putIfAbsent('${matchTitleKey(t.title)}|${_artistKey(t.artist ?? '')}',
              () => [])
          .add(t);
      final path = t.path;
      if (path != null) {
        final key = pathKey(path);
        _byPath[key] = t;
        _byBase.putIfAbsent(basenameOf(key), () => []).add((key, t));
      }
    }
  }

  final Map<String, List<LibraryEntryLite>> _byKey = {};
  final Map<String, LibraryEntryLite> _byPath = {};
  final Map<String, List<(String, LibraryEntryLite)>> _byBase = {};

  /// The library track a playlist entry points to. Absolute paths match
  /// exactly; a path from another device or a relative one (to [baseDir], or
  /// to wherever the library is) matches by its trailing folders when that
  /// leaves a single candidate.
  LibraryEntryLite? findByPath(String location, {String? baseDir}) {
    final local = localPathFromLocation(location);
    if (local == null || local.isEmpty) return null;
    final key = pathKey(local);
    if (isAbsoluteLocalPath(local)) {
      return _byPath[key] ?? _bySuffix(key, minSegments: 2, maxSegments: 3);
    }
    if (baseDir != null) {
      final joined = p.posix.normalize(
          '${baseDir.replaceAll(r'\', '/')}/${local.replaceAll(r'\', '/')}');
      final hit = _byPath[joined.toLowerCase()];
      if (hit != null) return hit;
    }
    final clean = p.posix
        .normalize(key)
        .split('/')
        .where((s) => s != '..' && s != '.')
        .join('/');
    return _bySuffix(clean, minSegments: 1, maxSegments: 4);
  }

  LibraryEntryLite? _bySuffix(String key,
      {required int minSegments, required int maxSegments}) {
    final candidates = _byBase[basenameOf(key)];
    if (candidates == null) return null;
    final parts = key.split('/').where((s) => s.isNotEmpty).toList();
    for (var n = parts.length < maxSegments ? parts.length : maxSegments;
        n >= minSegments && n >= 1;
        n--) {
      final suffix = '/${parts.sublist(parts.length - n).join('/')}';
      final hits = [for (final c in candidates) if (c.$1.endsWith(suffix)) c.$2];
      if (hits.length == 1) return hits.single;
      if (hits.length > 1) return null;
    }
    return null;
  }

  /// Same title and artist; when both lengths are known they must be within
  /// 5 s (the same recording is often a few seconds apart between services).
  LibraryEntryLite? find(ImportRow r, {String? baseDir}) {
    final loc = r.location;
    if (loc != null) {
      final byPath = findByPath(loc, baseDir: baseDir);
      if (byPath != null) return byPath;
    }
    final c = _byKey['${matchTitleKey(r.title)}|${_artistKey(r.primaryArtist)}'];
    if (c == null) return null;
    final want = r.durationMs;
    for (final t in c) {
      if (want == null || want <= 0 || t.durationMs <= 0) return t;
      if ((t.durationMs - want).abs() <= 5000) return t;
    }
    return null;
  }
}

enum MatchKind { sure, review, notFound }

class ScoredCandidate {
  const ScoredCandidate(this.result, this.score);

  final YtResult result;
  final double score;
}

class MatchDecision {
  const MatchDecision(this.kind, this.top);

  final MatchKind kind;

  /// Best first; at most 3.
  final List<ScoredCandidate> top;

  ScoredCandidate? get best => top.isEmpty ? null : top.first;
}

const sureThreshold = 0.80;
const reviewThreshold = 0.55;

// Versions that are a different recording; ignored when the CSV title asks for them.
const _otherVersions = [
  'live',
  'cover',
  'karaoke',
  'remix',
  'sped up',
  'speed up',
  'slowed',
  'nightcore',
  '8d',
  'instrumental',
  'reverb',
  '1 hour',
  'tribute',
  'acoustic',
  'mashup',
  'demo',
  'parody',
];

// What SoundCloud uploaders add to a title for their own version of a song.
const _soundCloudVersions = ['bootleg', 'edit', 'flip', 'rework', 'vip', 'refix', 'blend'];

bool _hasPhrase(String key, String phrase) => ' $key '.contains(' $phrase ');

Set<String> _tokens(String key) =>
    key.split(' ').where((w) => w.isNotEmpty).toSet();

double _titleScore(String want, String got) {
  final a = _tokens(want), b = _tokens(got);
  if (a.isEmpty || b.isEmpty) return 0;
  final common = a.intersection(b).length;
  final coverage = common / a.length;
  final precision = common / b.length;
  return coverage * (0.6 + 0.4 * precision);
}

double _durationScore(int? wantMs, Duration? got) {
  if (wantMs == null || wantMs <= 0 || got == null) return 0.5;
  final d = (got.inMilliseconds - wantMs).abs() / 1000;
  if (d <= 2) return 1;
  if (d >= 15) return 0;
  return 1 - (d - 2) / 13;
}

final _channelNoise = RegExp(r'\s*[-–]?\s*(topic|vevo|official)$');

double _artistScore(ImportRow r, YtResult c, String titleKey) {
  final want = [for (final a in r.artists) _artistKey(a)]
      .where((a) => a.isNotEmpty)
      .toList();
  if (want.isEmpty) return 0.5;
  final got = <String>{
    for (final a in c.artists) _artistKey(a),
    matchKey(c.channel).replaceFirst(_channelNoise, '').trim(),
  }..remove('');
  if (got.contains(want.first)) return 1;
  if (want.skip(1).any(got.contains)) return 0.8;
  // Plain YouTube uploads: "Artist - Title" in the title or the channel name.
  final hay = ' $titleKey ${matchKey(c.channel)} ';
  if (want.any((a) => hay.contains(' $a '))) return 0.6;
  return 0;
}

double _bonus(ImportRow r, YtResult c) {
  var b = 0.0;
  final channel = matchKey(c.channel);
  final soundcloud = c.source == MediaSource.soundcloud;
  // «- Topic» and VEVO are YouTube's own labels: SoundCloud has no such thing.
  if (!soundcloud) {
    if (channel.endsWith(' topic')) b += 0.08;
    if (channel.endsWith('vevo')) b += 0.04;
  }
  if (r.artists.isNotEmpty) {
    final uploader = channel.replaceFirst(_channelNoise, '').trim();
    final artist = matchKey(r.primaryArtist);
    if (uploader == artist) {
      b += 0.04;
    } else if (soundcloud && artist.isNotEmpty && _hasPhrase(uploader, artist)) {
      // «Daft Punk Archive», «Daft Punk Music»: probably theirs.
      b += 0.03;
    }
  }
  final album = r.album, got = c.album;
  if (album != null &&
      got != null &&
      matchTitleKey(album) == matchTitleKey(got)) {
    b += 0.04;
  }
  return b > 0.10 ? 0.10 : b;
}

/// 0..1: how likely [c] is the recording described by [r].
double scoreCandidate(ImportRow r, YtResult c) {
  final wantTitle = matchTitleKey(r.title);
  final gotTitle = matchTitleKey(c.title);
  final title = _titleScore(wantTitle, gotTitle);
  final artist = _artistScore(r, c, gotTitle);
  final duration = _durationScore(r.durationMs, c.duration);
  var score = 0.45 * duration + 0.35 * title + 0.20 * artist + _bonus(r, c);
  final versions = [
    ..._otherVersions,
    if (c.source == MediaSource.soundcloud) ..._soundCloudVersions,
  ];
  for (final w in versions) {
    if (_hasPhrase(gotTitle, w) && !_hasPhrase(wantTitle, w)) {
      score *= 0.4;
      break;
    }
  }
  return score.clamp(0.0, 1.0).toDouble();
}

/// The two cut-offs the user may move in the advanced settings; [review] must
/// stay at least [minGap] under [sure].
class MatchThresholds {
  const MatchThresholds({this.sure = sureThreshold, this.review = reviewThreshold});

  static const minGap = 0.05;
  static const limits = (min: 0.30, max: 0.98);

  final double sure, review;

  /// Keeps both inside the limits and [review] below [sure] by [minGap].
  MatchThresholds clamped() {
    final s = sure.clamp(limits.min + minGap, limits.max).toDouble();
    final r = review.clamp(limits.min, s - minGap).toDouble();
    return MatchThresholds(sure: s, review: r);
  }
}

MatchDecision decide(ImportRow r, List<YtResult> candidates,
    {MatchThresholds thresholds = const MatchThresholds()}) {
  final scored = [
    for (final c in candidates) ScoredCandidate(c, scoreCandidate(r, c)),
  ]..sort((a, b) => b.score.compareTo(a.score));
  final top = scored.take(3).toList();
  final best = top.isEmpty ? 0.0 : top.first.score;
  if (best >= thresholds.sure) return MatchDecision(MatchKind.sure, top);
  if (best >= thresholds.review) return MatchDecision(MatchKind.review, top);
  return MatchDecision(MatchKind.notFound, const []);
}
