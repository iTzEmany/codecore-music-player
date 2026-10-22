import '../../l10n/app_localizations.dart';
import 'release_checker.dart';

/// The words of the notification for new releases.
typedef ReleaseNotificationText = ({String title, String body});

/// «Nuova uscita: X di Y» for one release, «3 nuove uscite: A, B e altri 1»
/// for more. Only artists that are not muted count; null when nothing is left.
ReleaseNotificationText? releaseNotificationText(
  List<FreshRelease> fresh,
  AppLocalizations l,
) {
  final audible = [
    for (final f in fresh)
      if (!f.artist.muted) f,
  ];
  if (audible.isEmpty) return null;
  final title = l.newReleasesTitle;
  if (audible.length == 1) {
    final f = audible.single;
    return (
      title: title,
      body: l.releaseNotifyOne(f.release.release.title, f.artist.name),
    );
  }
  final names = <String>[];
  for (final f in audible) {
    if (!names.contains(f.artist.name)) names.add(f.artist.name);
  }
  final n = audible.length;
  final body = switch (names.length) {
    1 => l.releaseNotifyMany1(n, names[0]),
    2 => l.releaseNotifyMany2(n, names[0], names[1]),
    _ => l.releaseNotifyManyMore(n, names[0], names[1], names.length - 2),
  };
  return (title: title, body: body);
}
