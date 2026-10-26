import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_log.dart';
import '../services/covers/cover_store.dart';
import '../services/online/http_client.dart';
import 'online_providers.dart';

/// Each proposal is a download of a big image: few per source.
const coverProposalsPerSource = 6;

/// An online cover already downloaded: its size is the decoded one, not the declared one.
class CoverProposal {
  const CoverProposal(this.label, this.bytes, this.width, this.height);

  final String label;
  final Uint8List bytes;
  final int width, height;
}

Future<CoverProposal?> _load(WebClient web, ({String title, String url}) f, CancelToken cancel) async {
  try {
    final bytes = await web.getBytes(f.url, maxBytes: CoverStore.maxBytes, cancel: cancel);
    if (bytes == null) return null;
    final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    final codec = await ui.instantiateImageCodec(data);
    try {
      final frame = await codec.getNextFrame();
      final p = CoverProposal(f.title, data, frame.image.width, frame.image.height);
      frame.image.dispose();
      return p;
    } finally {
      codec.dispose();
    }
  } on Object catch (e, st) {
    AppLog.w('cover proposal skipped: ${f.url}', e, st);
    return null;
  }
}

/// Searched only when the picker opens (the user asked), whatever «Metadati da
/// Deezer» says. A failing source does not take the other one away.
final coverProposalsProvider = FutureProvider.autoDispose
    .family<List<CoverProposal>, ({String album, String artist})>((ref, q) async {
  final web = ref.watch(webClientProvider);
  final deezer = ref.watch(deezerClientProvider);
  final itunes = ref.watch(itunesClientProvider);
  // The sheet closed: the pending downloads stop.
  final cancel = CancelToken();
  ref.onDispose(cancel.cancel);
  Future<List<CoverProposal>> source(Future<List<({String title, String url})>> search) async {
    try {
      final found = await search;
      final loaded = await Future.wait([for (final f in found.take(coverProposalsPerSource)) _load(web, f, cancel)]);
      return [for (final c in loaded) ?c];
    } on Object catch (e, st) {
      AppLog.w('cover proposals failed', e, st);
      return const [];
    }
  }

  final r = await Future.wait([
    source(deezer.albumCovers(q.album, q.artist, cancel: cancel)),
    source(itunes.albumCovers(q.album, q.artist, cancel: cancel)),
  ]);
  return [...r[0], ...r[1]];
});
