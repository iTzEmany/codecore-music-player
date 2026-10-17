import 'package:codecore/core/import_row.dart';
import 'package:codecore/services/import/track_matcher.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:flutter_test/flutter_test.dart';

ImportRow row(String title, List<String> artists, {int? ms}) =>
    ImportRow(index: 0, title: title, artists: artists, durationMs: ms);

YtResult sc(String id, String title, String uploader, {int? seconds}) => YtResult(
  id: id,
  title: title,
  channel: uploader,
  duration: seconds == null ? null : Duration(seconds: seconds),
  source: MediaSource.soundcloud,
  webpageUrl: 'https://soundcloud.com/x/$id',
);

YtResult yt(String id, String title, String channel, {int? seconds}) => YtResult(
  id: id,
  title: title,
  channel: channel,
  duration: seconds == null ? null : Duration(seconds: seconds),
);

void main() {
  final want = row('One More Time', ['Daft Punk'], ms: 320000);

  test('an upload by the artist is accepted', () {
    final d = decide(want, [sc('official', 'One More Time', 'Daft Punk', seconds: 320)]);
    expect(d.kind, MatchKind.sure);
  });

  test('an uploader that contains the artist name ("Daft Punk Official") counts as the artist', () {
    final official = scoreCandidate(want, sc('a', 'One More Time', 'Daft Punk Official', seconds: 320));
    final stranger = scoreCandidate(want, sc('b', 'One More Time', 'some dj', seconds: 320));
    expect(official, greaterThan(stranger));
    expect(decide(want, [sc('a', 'One More Time', 'Daft Punk Official', seconds: 320)]).kind, MatchKind.sure);
  });

  test('a repost by someone else is below the official upload but can still be offered for review', () {
    final d = decide(want, [
      sc('repost', 'Daft Punk - One More Time', 'HOUZ', seconds: 320),
      sc('official', 'One More Time', 'Daft Punk', seconds: 320),
    ]);
    expect(d.best!.result.id, 'official');
    expect(d.top.last.score, lessThan(d.top.first.score));
  });

  test('a bootleg is not chosen when the CSV did not ask for one', () {
    final plain = scoreCandidate(want, sc('a', 'One More Time', 'Daft Punk', seconds: 320));
    final bootleg = scoreCandidate(want, sc('b', 'One More Time (Bootleg)', 'Daft Punk', seconds: 320));
    expect(bootleg, lessThan(plain * 0.5));
    expect(decide(want, [sc('b', 'One More Time (Bootleg)', 'Daft Punk', seconds: 320)]).kind, isNot(MatchKind.sure));
  });

  test('an edit by another artist is penalised like a remix, but asked for by the CSV it is not', () {
    final edit = scoreCandidate(want, sc('a', 'Daft Punk - One More Time (Valmer Edit)', 'HOUZ', seconds: 314));
    final plain = scoreCandidate(want, sc('b', 'Daft Punk - One More Time', 'HOUZ', seconds: 314));
    expect(edit, lessThan(plain));
    final wantEdit = row('One More Time (Valmer Edit)', ['Daft Punk'], ms: 314000);
    expect(
      scoreCandidate(wantEdit, sc('a', 'Daft Punk - One More Time (Valmer Edit)', 'HOUZ', seconds: 314)),
      greaterThan(edit),
    );
  });

  test('"(Original Mix)" with the same length is still the song', () {
    final d = decide(want, [sc('om', 'One More Time (Original Mix)', 'Daft Punk', seconds: 320)]);
    expect(d.kind, MatchKind.sure);
  });

  test('the 30 s preview scores far below the full track', () {
    final preview = scoreCandidate(want, sc('p', 'One More Time', 'Daft Punk', seconds: 30));
    final full = scoreCandidate(want, sc('f', 'One More Time', 'Daft Punk', seconds: 320));
    expect(preview, lessThan(0.6));
    expect(full, greaterThan(preview));
  });

  test('no «- Topic» or VEVO bonus for SoundCloud, the same channel name keeps it on YouTube', () {
    final r = row('Obscure Song', ['Some Band']);
    final onYoutube = scoreCandidate(r, yt('a', 'Obscure Song', 'Some Band - Topic'));
    final onSoundcloud = scoreCandidate(r, sc('a', 'Obscure Song', 'Some Band - Topic'));
    expect(onYoutube, greaterThan(onSoundcloud));
    final vevoYoutube = scoreCandidate(r, yt('b', 'Obscure Song', 'SomeBandVEVO'));
    final vevoSc = scoreCandidate(r, sc('b', 'Obscure Song', 'SomeBandVEVO'));
    expect(vevoYoutube, greaterThanOrEqualTo(vevoSc));
  });

  test('YouTube scores do not change', () {
    final r = row('Felicità', ['Lucio Dalla'], ms: 345360);
    expect(
      scoreCandidate(r, yt('topic', 'Felicità', 'Lucio Dalla - Topic', seconds: 345)),
      closeTo(scoreCandidate(r, yt('topic2', 'Felicità', 'Lucio Dalla - Topic', seconds: 345)), 1e-9),
    );
    expect(decide(r, [yt('topic', 'Felicità', 'Lucio Dalla - Topic', seconds: 345)]).kind, MatchKind.sure);
  });
}
