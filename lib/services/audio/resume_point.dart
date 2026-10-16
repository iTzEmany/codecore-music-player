/// «Riprendi da qui»: only long tracks (audiobooks, DJ sets, recordings) are
/// worth remembering the position of.
const kResumeThreshold = Duration(minutes: 20);

/// Playing less than this from the start, or this close to the end, is not a
/// place to come back to.
const kResumeEdge = Duration(seconds: 30);

/// Resume a little before the saved point, to catch the sentence again.
const kResumeRewind = Duration(seconds: 5);

/// While playing, the position is saved at most this often.
const kResumeSaveEvery = Duration(seconds: 15);

/// The position to store for a track of [durationMs] at [position]; null means
/// «no bookmark» (short track, still at the start, or practically finished).
int? resumePointFor(Duration position, int durationMs) {
  if (durationMs <= 0) return null;
  final duration = Duration(milliseconds: durationMs);
  if (duration < kResumeThreshold) return null;
  if (position < kResumeEdge || position > duration - kResumeEdge) return null;
  return position.inMilliseconds;
}

/// Where to start a track with a saved point: a few seconds earlier.
Duration? resumeStartFor(int? savedMs) {
  if (savedMs == null || savedMs <= 0) return null;
  final start = Duration(milliseconds: savedMs) - kResumeRewind;
  return start < Duration.zero ? Duration.zero : start;
}
