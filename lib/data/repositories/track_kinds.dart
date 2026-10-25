/// `tracks.kind` values. Library views filter `kind = 0`; history and stats
/// use [listenKinds]; a shadow row (a streamed track cached for playback) is
/// never shown in the library.
const kMusicKind = 0;
const kEpisodeKind = 1;
const kStreamKind = 2;
const listenKinds = [kMusicKind, kStreamKind];
