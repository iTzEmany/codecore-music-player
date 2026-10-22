import '../../../l10n/app_localizations.dart';
import '../../../services/radio/radio_station.dart';
import '../../../services/radio/stream_link.dart';

/// Our own list of genres: the tag Radio Browser knows each one by. The
/// names shown come from the ARB files.
const kRadioGenreTags = <String>[
  'pop', 'rock', 'classic rock', 'jazz', 'blues', 'classical', 'dance', 'electronic',
  'house', 'hip hop', 'lo-fi', 'chillout', '60s', '70s', '80s', '90s', 'oldies', 'metal',
  'reggae', 'latin', 'soul', 'news', 'talk', 'sports', //
];

String radioGenreLabel(AppLocalizations l, String tag) => switch (tag) {
      'pop' => l.radioGenrePop,
      'rock' => l.radioGenreRock,
      'classic rock' => l.radioGenreClassicRock,
      'jazz' => l.radioGenreJazz,
      'blues' => l.radioGenreBlues,
      'classical' => l.radioGenreClassical,
      'dance' => l.radioGenreDance,
      'electronic' => l.radioGenreElectronic,
      'house' => l.radioGenreHouse,
      'hip hop' => l.radioGenreHipHop,
      'lo-fi' => l.radioGenreLoFi,
      'chillout' => l.radioGenreChillout,
      '60s' => l.radioGenreSixties,
      '70s' => l.radioGenreSeventies,
      '80s' => l.radioGenreEighties,
      '90s' => l.radioGenreNineties,
      'oldies' => l.radioGenreOldies,
      'metal' => l.radioGenreMetal,
      'reggae' => l.radioGenreReggae,
      'latin' => l.radioGenreLatin,
      'soul' => l.radioGenreSoul,
      'news' => l.radioGenreNews,
      'talk' => l.radioGenreTalk,
      'sports' => l.radioGenreSports,
      _ => tag,
    };

String streamLinkErrorText(AppLocalizations l, StreamLinkError e) => switch (e) {
      StreamLinkError.empty => l.radioLinkEmpty,
      StreamLinkError.notAnAddress => l.radioLinkNotAnAddress,
      StreamLinkError.badScheme => l.radioLinkBadScheme,
      StreamLinkError.noEntries => l.radioLinkNoEntries,
      StreamLinkError.tooBig => l.radioLinkTooBig,
      StreamLinkError.fetchFailed => l.radioLinkFetchFailed,
    };

/// «MP3 · 128 kbps», whatever is known.
String radioQualityLine(RadioStation s) => [
      if (s.codec.isNotEmpty && s.codec.toUpperCase() != 'UNKNOWN') s.codec.toUpperCase(),
      if (s.bitrate > 0) '${s.bitrate} kbps',
    ].join(' · ');

/// Megabytes used in an hour of listening at [bitrate] kbps (0 = unknown).
int radioMbPerHour(int bitrate) => bitrate <= 0 ? 0 : (bitrate * 3600 / 8 / 1024).round();
