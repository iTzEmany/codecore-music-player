import '../../data/db/app_database.dart';
import 'credits_enricher.dart';
import 'itunes_client.dart';
import 'lrclib_client.dart';
import 'wikipedia_client.dart' show Curiosity;

class EnrichmentProposal {
  const EnrichmentProposal({
    required this.track,
    this.meta,
    this.lyrics,
    this.curiosity,
    this.credits,
    this.disc,
    this.isrc,
    this.source,
    this.limited = false,
  });

  final Track track;
  final ItunesMatch? meta;

  /// From Deezer only; written when the track has none.
  final int? disc;
  final String? isrc;

  /// Where [meta] came from: `deezer`, `itunes` or `deezer+itunes`.
  final String? source;
  final LyricsResult? lyrics;
  final Curiosity? curiosity;

  /// Only with «Credits and details» on; [EnrichmentService.propose] already
  /// saved them for a stored track (a shadow row saves them via [EnrichmentService.saveCredits]).
  /// Not part of [isEmpty]: credits never change the enrich status (K-AR-01).
  final CreditsPart? credits;

  /// A source refused («too many requests») while it was read: the proposal may lack its part.
  final bool limited;

  String? get coverUrl => meta?.artworkUrl;
  bool get isEmpty =>
      meta == null && (lyrics == null || lyrics!.isEmpty) && curiosity == null;
}

