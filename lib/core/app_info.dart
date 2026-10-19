/// Keep in sync with `version:` in pubspec.yaml.
const kAppVersion = '1.2.0';

/// `owner/name` of the GitHub repository whose releases «Controlla
/// aggiornamenti» reads. Empty = the feature is hidden (no repository yet).
const kReleaseRepo = '';

/// How to reach whoever runs this app: an e-mail, a web address or a wiki user
/// name. Sent in the `User-Agent` of every request to the online services,
/// which is what Wikimedia and MusicBrainz ask of automated clients; with it
/// Wikimedia allows 200 requests a minute instead of 10. Empty = not sent.
/// It is public: put in it only what you are happy to show those services.
const kApiContact = '';
