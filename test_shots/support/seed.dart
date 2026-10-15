import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:codecore/core/text_utils.dart';
import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/playlist_repository.dart';
import 'package:codecore/services/covers/cover_store.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/painting.dart';

class SeedAlbum {
  const SeedAlbum(this.artist, this.album, this.year, this.titles,
      {this.color = const Color(0xFF7A3FD0),
      this.discs = 1,
      this.compilation = false,
      this.noCover = false});

  final String artist, album;
  final int year;
  final List<String> titles;
  final Color color;
  final int discs;
  final bool compilation, noCover;
}

const longTitle =
    'Una canzone con un titolo davvero molto lungo che non sta mai in una riga sola, parte due';

const seedAlbums = [
  SeedAlbum('Lucio Dalla', 'Dalla', 1980,
      ['Futura', 'Balla balla ballerino', 'Cara', 'Anna e Marco', 'Meri Luis'],
      color: Color(0xFFE0882B)),
  SeedAlbum('Lucio Dalla', 'Canzoni', 1996,
      ['Canzone', 'Ciao', 'Attenti al lupo', 'Tu non mi basti mai'],
      color: Color(0xFFD94F5C)),
  SeedAlbum('Daft Punk', 'Random Access Memories', 2013,
      ['Give Life Back to Music', 'Instant Crush', 'Get Lucky', 'Lose Yourself to Dance'],
      color: Color(0xFFC8A64B)),
  SeedAlbum('Pink Floyd', 'The Wall', 1979,
      ['In the Flesh?', 'Another Brick in the Wall, Pt. 1', 'Mother', 'Comfortably Numb', longTitle],
      color: Color(0xFFF2F2F2), discs: 2),
  SeedAlbum('Nina Simone', 'Pastel Blues', 1965,
      ['Be My Husband', 'Strange Fruit', 'Sinnerman'],
      color: Color(0xFF1B2A4A)),
  SeedAlbum('Daft Punk', 'Discovery', 2001,
      ['One More Time', 'Digital Love', 'Harder, Better, Faster, Stronger'],
      color: Color(0xFF2FB5C9)),
  SeedAlbum('Vari', 'Estate italiana', 2019,
      ['Sarà perché ti amo', 'Felicità', 'Azzurro', 'Il ballo del qua qua'],
      color: Color(0xFF45C27A), compilation: true),
  SeedAlbum('Ludovico Einaudi', 'Nightbook', 2009,
      ['Lady Labyrinth', 'Una mattina', 'Eros'],
      color: Color(0xFF050505)),
  SeedAlbum('Ludovico Einaudi', 'I Giorni', 2001, ['I Giorni', 'Fuori dal mondo'],
      noCover: true),
];

/// Draws a diagonal gradient with a few circles: enough to tell covers apart.
Future<void> writeCover(Directory dir, String coverKey, Color base) async {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  const size = 240.0;
  final hsl = HSLColor.fromColor(base);
  final light = hsl.withLightness((hsl.lightness + 0.18).clamp(0, 1)).toColor();
  final dark = hsl.withLightness((hsl.lightness * 0.45).clamp(0, 1)).toColor();
  canvas.drawRect(
      const Rect.fromLTWH(0, 0, size, size),
      Paint()
        ..shader = ui.Gradient.linear(
            Offset.zero, const Offset(size, size), [light, dark]));
  final r = math.Random(coverKey.hashCode);
  for (var i = 0; i < 4; i++) {
    canvas.drawCircle(
        Offset(r.nextDouble() * size, r.nextDouble() * size),
        20 + r.nextDouble() * 50,
        Paint()..color = const Color(0x22FFFFFF));
  }
  final img = await rec.endRecording().toImage(size.toInt(), size.toInt());
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  await File('${dir.path}/$coverKey.png')
      .writeAsBytes(data!.buffer.asUint8List());
}

class SeedResult {
  SeedResult(this.trackIds, this.playlistIds, this.coverKeys);
  final List<int> trackIds;
  final List<int> playlistIds;
  final Map<String, String?> coverKeys;
}

/// Inserts ~40 realistic tracks, 3 artists with several albums, 2 playlists and
/// 6 favourites; covers are written to [coversDir].
Future<SeedResult> seedLibrary(AppDatabase db, Directory coversDir) async {
  final now = DateTime.now().millisecondsSinceEpoch;
  const day = 86400000;
  final ids = <int>[];
  final covers = <String, String?>{};
  var n = 0;
  for (final a in seedAlbums) {
    final key = computeAlbumKey(
        albumArtist: a.compilation ? 'Vari' : a.artist,
        artist: a.artist,
        album: a.album,
        directory: '/m/${a.album}');
    String? coverKey;
    if (!a.noCover) {
      coverKey = CoverStore.coverKeyFor(key);
      await writeCover(coversDir, coverKey, a.color);
    }
    covers[key] = coverKey;
    for (var i = 0; i < a.titles.length; i++) {
      final id = await db.into(db.tracks).insert(TracksCompanion.insert(
            path: '/m/${a.album}/${i + 1}.${n == 3 ? 'flac' : 'mp3'}',
            title: a.titles[i],
            albumKey: key,
            format: n == 3 ? 'flac' : 'mp3',
            sizeBytes: 5000000,
            mtimeMs: 1,
            addedAt: now - (n * 3) * day,
            artist: Value(a.compilation
                ? const ['Righeira', 'Toto Cutugno', 'Domenico Modugno', 'Carosone'][i % 4]
                : a.artist),
            albumArtist: Value(a.compilation ? 'Vari' : a.artist),
            album: Value(a.album),
            trackNumber: Value(i + 1),
            discNumber: Value(a.discs > 1 ? (i < a.titles.length / 2 ? 1 : 2) : 1),
            year: Value(a.year),
            genre: Value(const ['Pop', 'Rock', 'Elettronica', 'Jazz'][n % 4]),
            durationMs: Value(150000 + (n * 7919) % 120000),
            sampleRateHz: Value(n == 3 ? 96000 : 44100),
            bitDepth: Value(n == 3 ? 24 : null),
            bitrateKbps: Value(n == 3 ? null : 320),
            hasCover: Value(!a.noCover),
            coverKey: Value(coverKey),
            isFavorite: Value(const {0, 3, 7, 12, 20, 31}.contains(n)),
            playCount: Value((n * 5) % 17),
            lastPlayedAt: n % 3 == 0 ? Value(now - n * 3600000) : const Value.absent(),
            lyricsSynced: n == 2
                ? const Value('[00:01.00]Prima riga\n[00:05.00]Seconda riga\n[00:09.00]Terza riga')
                : const Value.absent(),
            curiosities: n == 2
                ? const Value(
                    'Brano registrato in studio a Milano nel 1980, con una sezione ritmica improvvisata.')
                : const Value.absent(),
          ));
      ids.add(id);
      n++;
    }
  }
  final pl = PlaylistRepository(db);
  final p1 = await pl.create('In macchina');
  await pl.addTracks(p1, ids.take(12).toList());
  final p2 = await pl.create('Notte');
  await pl.addTracks(p2, ids.skip(20).take(5).toList());
  return SeedResult(ids, [p1, p2], covers);
}
