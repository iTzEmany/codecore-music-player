import '../../../l10n/app_localizations.dart';
import '../../../services/podcast/podcast_models.dart';

/// Why a podcast operation failed, in words.
String podcastErrorText(AppLocalizations l, PodcastErrorKind kind) => switch (kind) {
  PodcastErrorKind.invalidUrl => l.podcastErrInvalidUrl,
  PodcastErrorKind.tooLarge => l.podcastErrTooLarge,
  PodcastErrorKind.network => l.podcastErrNetwork,
  PodcastErrorKind.notFeed => l.podcastErrNotFeed,
  PodcastErrorKind.unsupportedFormat => l.podcastErrUnsupportedFormat,
};
