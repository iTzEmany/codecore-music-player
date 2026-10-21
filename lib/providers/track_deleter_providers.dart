import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/platform.dart';
import '../services/android/media_deleter.dart';
import '../services/library/track_deleter.dart';
import 'database_providers.dart';
import 'player_providers.dart';

/// «Elimina dal dispositivo». Tests replace it with a fake file system.
final trackDeleterProvider = Provider<TrackDeleter>(
  (ref) => TrackDeleter(
    tracks: ref.watch(trackRepositoryProvider),
    removeFromQueue: ref.read(playerControllerProvider).removeTracks,
    platform: isAndroid ? deleteWithSystemDialog : null,
  ),
);
