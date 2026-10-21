import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/track_deleter_providers.dart';
import 'confirm.dart';

/// «Elimina dal dispositivo»: confirms, then deletes the files and the library
/// rows of [tracks] and says what happened. True when at least one went.
Future<bool> confirmAndDeleteTracks(
  BuildContext outer,
  WidgetRef ref,
  List<Track> tracks,
) async {
  final l = outer.l10n;
  final messenger = ScaffoldMessenger.of(outer);
  final one = tracks.length == 1;
  final ok = await showConfirm(
    outer,
    title: one
        ? l.deleteTrackTitle(tracks.first.title)
        : l.deleteTracksTitle(tracks.length),
    body: one ? l.deleteTrackBody : l.deleteTracksBody,
    confirmLabel: l.deleteConfirm,
    destructive: true,
  );
  if (!ok) return false;
  final report = await ref.read(trackDeleterProvider).deleteTracks(tracks);
  final failed = report.failed.length;
  final String text;
  if (one) {
    text = failed == 0
        ? l.trackDeleted
        : l.trackDeleteFailed(report.failed.values.first);
  } else {
    text = failed == 0
        ? l.tracksDeleted(report.deleted.length)
        : l.tracksDeletedSome(report.deleted.length, failed);
  }
  messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(text)));
  return report.deleted.isNotEmpty;
}
