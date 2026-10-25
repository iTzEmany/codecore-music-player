import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/online/credits.dart';
import 'online_providers.dart';

typedef TrackCreditsData = ({List<TrackCredit> credits, TrackDetails? details});

/// Credits and details of one track, read on their own (not from the `tracks`
/// streams). Invalidate it after a refresh.
final trackCreditsProvider = FutureProvider.autoDispose
    .family<TrackCreditsData, int>(
      (ref, trackId) =>
          ref.watch(creditsRepositoryProvider).portableOf(trackId),
    );
