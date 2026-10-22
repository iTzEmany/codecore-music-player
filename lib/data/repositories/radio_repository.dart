import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../services/radio/radio_station.dart';
import '../db/app_database.dart';

extension SavedRadioStation on SavedRadio {
  /// The station as the player and the lists use it.
  RadioStation toStation() => RadioStation(
        id: stationId,
        name: name,
        streamUrl: streamUrl,
        homepage: homepage,
        faviconUrl: faviconUrl,
        countryCode: countryCode,
        state: state,
        tags: splitTags(tags),
        codec: codec,
        bitrate: bitrate,
        hls: hls,
        lastCheckOk: !unreachable,
      );
}

/// «Le mie radio». A saved station is never deleted by a refresh.
class RadioRepository {
  RadioRepository(this._db);

  final AppDatabase _db;

  Stream<List<SavedRadio>> watchAll() => (_db.select(_db.radioStations)
        ..orderBy([(r) => OrderingTerm.asc(r.position), (r) => OrderingTerm.asc(r.addedAt)]))
      .watch();

  Future<List<SavedRadio>> getAll() => (_db.select(_db.radioStations)
        ..orderBy([(r) => OrderingTerm.asc(r.position), (r) => OrderingTerm.asc(r.addedAt)]))
      .get();

  /// Adds [s] at the end; a station already saved is left as it is.
  Future<void> save(RadioStation s) => _db.transaction(() async {
        final exists = await (_db.select(_db.radioStations)
              ..where((r) => r.stationId.equals(s.id)))
            .getSingleOrNull();
        if (exists != null) return;
        await _db.into(_db.radioStations).insert(RadioStationsCompanion.insert(
              stationId: s.id,
              name: s.name,
              streamUrl: s.streamUrl,
              homepage: Value(s.homepage),
              faviconUrl: Value(s.faviconUrl),
              countryCode: Value(s.countryCode),
              state: Value(s.state),
              tags: Value(s.tags.join(',')),
              codec: Value(s.codec),
              bitrate: Value(s.bitrate),
              hls: Value(s.hls),
              position: await _nextPosition(),
              lastOkAt: Value(nowMs()),
            ));
      });

  Future<int> _nextPosition() async {
    final max = _db.radioStations.position.max();
    final row = await (_db.selectOnly(_db.radioStations)..addColumns([max])).getSingle();
    return (row.read(max) ?? -1) + 1;
  }

  Future<void> remove(String id) =>
      (_db.delete(_db.radioStations)..where((r) => r.stationId.equals(id))).go();

  /// [ids] in the new order; saved stations not listed follow, in their order.
  Future<void> reorder(List<String> ids) => _db.transaction(() async {
        final rest = [
          for (final r in await getAll())
            if (!ids.contains(r.stationId)) r.stationId,
        ];
        var position = 0;
        for (final id in [...ids, ...rest]) {
          await (_db.update(_db.radioStations)..where((r) => r.stationId.equals(id)))
              .write(RadioStationsCompanion(position: Value(position++)));
        }
      });

  /// A blank name is ignored.
  Future<void> rename(String id, String name) async {
    final n = name.trim();
    if (n.isEmpty) return;
    await (_db.update(_db.radioStations)..where((r) => r.stationId.equals(id)))
        .write(RadioStationsCompanion(name: Value(n)));
  }

  Future<void> touchPlayed(String id) =>
      (_db.update(_db.radioStations)..where((r) => r.stationId.equals(id)))
          .write(RadioStationsCompanion(lastPlayedAt: Value(nowMs())));

  /// Applies a re-read of the saved stations: [fresh] updates address and
  /// details of the ones found (the user's name stays), [missingIds] are marked
  /// unreachable. Nothing is deleted.
  Future<void> applyRefresh(List<RadioStation> fresh, List<String> missingIds) =>
      _db.transaction(() async {
        final now = nowMs();
        for (final s in fresh) {
          await (_db.update(_db.radioStations)..where((r) => r.stationId.equals(s.id))).write(
              RadioStationsCompanion(
                streamUrl: Value(s.streamUrl),
                homepage: Value(s.homepage),
                faviconUrl: Value(s.faviconUrl),
                countryCode: Value(s.countryCode),
                state: Value(s.state),
                tags: Value(s.tags.join(',')),
                codec: Value(s.codec),
                bitrate: Value(s.bitrate),
                hls: Value(s.hls),
                unreachable: Value(!s.lastCheckOk),
                lastOkAt: s.lastCheckOk ? Value(now) : const Value.absent(),
              ));
        }
        for (final id in missingIds) {
          await (_db.update(_db.radioStations)..where((r) => r.stationId.equals(id)))
              .write(const RadioStationsCompanion(unreachable: Value(true)));
        }
      });
}
