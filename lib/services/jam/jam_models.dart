const maxJamItems = 200;

/// Host included.
const maxJamParticipants = 5;

/// With several outputs playback starts this far in the future so that every
/// output can be in position when the Jam clock gets there.
const jamStartLeadMs = 1500;
const maxJamText = 200;
const jamExts = {
  'mp3', 'flac', 'wav', 'ogg', 'oga', 'opus', 'm4a', 'aac', 'aiff', 'aif',
  'wma', 'webm',
};

/// A track in the shared queue. The file stays on [ownerDeviceId].
class JamItem {
  const JamItem({
    required this.id,
    required this.ownerDeviceId,
    required this.title,
    this.artist,
    this.album,
    this.durationMs = 0,
    required this.ext,
    this.sizeBytes = 0,
    this.available = true,
    this.ref,
    this.inherited = false,
  });

  /// Assigned by the host; unique within a session.
  final int id;
  final String ownerDeviceId;
  final String title;
  final String? artist, album;
  final int durationMs;
  final String ext;
  final int sizeBytes;

  /// False once the owner became unreachable and nothing is cached.
  final bool available;

  /// Opaque key meaningful only to the owner (maps to a local file).
  final String? ref;

  /// Part of the host's seed queue: tracks added later are placed before it.
  final bool inherited;

  JamItem copyWith({int? id, bool? available, bool? inherited}) => JamItem(
        id: id ?? this.id,
        ownerDeviceId: ownerDeviceId,
        title: title,
        artist: artist,
        album: album,
        durationMs: durationMs,
        ext: ext,
        sizeBytes: sizeBytes,
        available: available ?? this.available,
        ref: ref,
        inherited: inherited ?? this.inherited,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'owner': ownerDeviceId,
        'title': title,
        if (artist != null) 'artist': artist,
        if (album != null) 'album': album,
        'dur': durationMs,
        'ext': ext,
        'size': sizeBytes,
        'ok': available,
        if (ref != null) 'ref': ref,
        if (inherited) 'inh': true,
      };

  /// Strict parser: returns null for anything malformed.
  static JamItem? tryParse(Object? j) {
    if (j is! Map) return null;
    final id = j['id'], owner = j['owner'], title = j['title'], ext = j['ext'];
    if (id is! int || id < 0) return null;
    if (owner is! String || owner.isEmpty || owner.length > 64) return null;
    if (title is! String || title.isEmpty || title.length > maxJamText) {
      return null;
    }
    if (ext is! String || !jamExts.contains(ext.toLowerCase())) return null;
    String? opt(Object? v) =>
        v is String && v.isNotEmpty && v.length <= maxJamText ? v : null;
    final dur = j['dur'], size = j['size'];
    return JamItem(
      id: id,
      ownerDeviceId: owner,
      title: title.replaceAll(RegExp(r'[\x00-\x1f]'), ' '),
      artist: opt(j['artist']),
      album: opt(j['album']),
      durationMs: dur is int && dur >= 0 ? dur : 0,
      ext: ext.toLowerCase(),
      sizeBytes: size is int && size >= 0 ? size : 0,
      available: j['ok'] is bool ? j['ok'] as bool : true,
      ref: opt(j['ref']),
      inherited: j['inh'] == true,
    );
  }
}

/// A device taking part in the Jam. [host] is empty for the Jam host itself
/// ("the address you reached me at").
class JamParticipant {
  const JamParticipant({
    required this.id,
    required this.name,
    this.host = '',
    this.port = 0,
  });

  final String id, name, host;
  final int port;

  Map<String, Object?> toJson() =>
      {'id': id, 'name': name, 'host': host, 'port': port};

  static JamParticipant? tryParse(Object? j) {
    if (j is! Map) return null;
    final id = j['id'], name = j['name'], host = j['host'], port = j['port'];
    if (id is! String || id.isEmpty || id.length > 64) return null;
    if (name is! String || name.length > 60) return null;
    if (host is! String || host.length > 64) return null;
    if (port is! int || port < 0 || port > 65535) return null;
    return JamParticipant(id: id, name: name, host: host, port: port);
  }
}

class JamState {
  const JamState({
    this.version = 0,
    this.items = const [],
    this.participants = const [],
    this.currentIndex = -1,
    this.playing = false,
    this.positionMs = 0,
    this.positionAt = 0,
    this.volume = 1.0,
    required this.hostDeviceId,
    required this.outputDeviceId,
    this.outputDeviceIds = const [],
    this.nextItemId = 1,
    this.ended = false,
  });

  final int version;
  final List<JamItem> items;
  final List<JamParticipant> participants;
  final int currentIndex;
  final bool playing;

  /// Position at [positionAt] (epoch ms, host clock). While playing the real
  /// position is `positionMs + (now - positionAt)`.
  final int positionMs, positionAt;
  final double volume;
  final String hostDeviceId, outputDeviceId;

  /// All outputs when more than one device plays (empty = just [outputDeviceId]).
  final List<String> outputDeviceIds;
  final int nextItemId;
  final bool ended;

  JamParticipant? participant(String id) =>
      participants.where((p) => p.id == id).firstOrNull;

  /// Name to show for a device id ("" when unknown).
  String nameOf(String id) => participant(id)?.name ?? '';

  JamItem? get current =>
      currentIndex >= 0 && currentIndex < items.length ? items[currentIndex] : null;

  /// Devices that play, never empty.
  List<String> get outputs =>
      outputDeviceIds.isEmpty ? [outputDeviceId] : outputDeviceIds;

  bool get synced => outputs.length > 1;

  int positionAtTime(int nowMs) {
    if (!playing || nowMs < positionAt) return positionMs;
    final p = positionMs + (nowMs - positionAt);
    return p < 0 ? 0 : p;
  }

  JamState copyWith({
    int? version,
    List<JamItem>? items,
    List<JamParticipant>? participants,
    int? currentIndex,
    bool? playing,
    int? positionMs,
    int? positionAt,
    double? volume,
    String? outputDeviceId,
    List<String>? outputDeviceIds,
    int? nextItemId,
    bool? ended,
  }) =>
      JamState(
        version: version ?? this.version,
        items: items ?? this.items,
        participants: participants ?? this.participants,
        currentIndex: currentIndex ?? this.currentIndex,
        playing: playing ?? this.playing,
        positionMs: positionMs ?? this.positionMs,
        positionAt: positionAt ?? this.positionAt,
        volume: volume ?? this.volume,
        hostDeviceId: hostDeviceId,
        outputDeviceId: outputDeviceId ?? this.outputDeviceId,
        outputDeviceIds: outputDeviceIds ?? this.outputDeviceIds,
        nextItemId: nextItemId ?? this.nextItemId,
        ended: ended ?? this.ended,
      );

  Map<String, Object?> toJson() => {
        'version': version,
        'items': [for (final i in items) i.toJson()],
        'participants': [for (final p in participants) p.toJson()],
        'current': currentIndex,
        'playing': playing,
        'pos': positionMs,
        'at': positionAt,
        'volume': volume,
        'host': hostDeviceId,
        'output': outputDeviceId,
        if (outputDeviceIds.isNotEmpty) 'outputs': outputDeviceIds,
        'next': nextItemId,
        'ended': ended,
      };

  static JamState? tryParse(Object? j) {
    if (j is! Map) return null;
    final version = j['version'], rawItems = j['items'], host = j['host'];
    final output = j['output'];
    if (version is! int || rawItems is! List) return null;
    if (host is! String || output is! String) return null;
    if (rawItems.length > maxJamItems) return null;
    final items = <JamItem>[];
    for (final r in rawItems) {
      final i = JamItem.tryParse(r);
      if (i == null) return null;
      items.add(i);
    }
    final rawPeople = j['participants'];
    final people = <JamParticipant>[];
    if (rawPeople is List) {
      if (rawPeople.length > maxJamParticipants) return null;
      for (final r in rawPeople) {
        final p = JamParticipant.tryParse(r);
        if (p == null) return null;
        people.add(p);
      }
    }
    final rawOutputs = j['outputs'];
    final outputs = <String>[];
    if (rawOutputs is List) {
      if (rawOutputs.length > maxJamParticipants) return null;
      for (final o in rawOutputs) {
        if (o is! String || o.isEmpty || o.length > 64) return null;
        outputs.add(o);
      }
    }
    final cur = j['current'];
    final vol = j['volume'];
    return JamState(
      version: version,
      items: items,
      participants: people,
      currentIndex: cur is int && cur >= -1 && cur < items.length ? cur : -1,
      playing: j['playing'] == true,
      positionMs: j['pos'] is int && (j['pos'] as int) >= 0 ? j['pos'] as int : 0,
      positionAt: j['at'] is int ? j['at'] as int : 0,
      volume: vol is num ? vol.toDouble().clamp(0.0, 1.0) : 1.0,
      hostDeviceId: host,
      outputDeviceId: output,
      outputDeviceIds: outputs,
      nextItemId: j['next'] is int ? j['next'] as int : items.length + 1,
      ended: j['ended'] == true,
    );
  }
}

enum JamCommandType {
  add,
  remove,
  move,
  play,
  pause,
  seek,
  volume,
  setOutput,
  setOutputs,
  next,
  jump,
  trackEnded,
  end,
}

class JamCommand {
  const JamCommand._(this.type,
      {this.item,
      this.itemId,
      this.toIndex,
      this.positionMs,
      this.volume,
      this.deviceId,
      this.deviceIds});

  const JamCommand.add(JamItem item) : this._(JamCommandType.add, item: item);
  const JamCommand.remove(int itemId)
      : this._(JamCommandType.remove, itemId: itemId);
  const JamCommand.move(int itemId, int toIndex)
      : this._(JamCommandType.move, itemId: itemId, toIndex: toIndex);
  const JamCommand.play() : this._(JamCommandType.play);
  const JamCommand.pause() : this._(JamCommandType.pause);
  const JamCommand.seek(int positionMs)
      : this._(JamCommandType.seek, positionMs: positionMs);
  const JamCommand.volume(double v) : this._(JamCommandType.volume, volume: v);
  const JamCommand.setOutput(String deviceId)
      : this._(JamCommandType.setOutput, deviceId: deviceId);
  const JamCommand.setOutputs(List<String> deviceIds)
      : this._(JamCommandType.setOutputs, deviceIds: deviceIds);
  const JamCommand.next() : this._(JamCommandType.next);
  const JamCommand.jump(int itemId) : this._(JamCommandType.jump, itemId: itemId);

  /// Sent by the output device when the current track finished by itself.
  const JamCommand.trackEnded(int itemId)
      : this._(JamCommandType.trackEnded, itemId: itemId);
  const JamCommand.end() : this._(JamCommandType.end);

  final JamCommandType type;
  final JamItem? item;
  final int? itemId, toIndex, positionMs;
  final double? volume;
  final String? deviceId;
  final List<String>? deviceIds;

  Map<String, Object?> toJson() => {
        'cmd': type.name,
        if (item != null) 'item': item!.toJson(),
        if (itemId != null) 'itemId': itemId,
        if (toIndex != null) 'to': toIndex,
        if (positionMs != null) 'pos': positionMs,
        if (volume != null) 'volume': volume,
        if (deviceId != null) 'device': deviceId,
        if (deviceIds != null) 'devices': deviceIds,
      };

  static JamCommand? tryParse(Object? j) {
    if (j is! Map) return null;
    final name = j['cmd'];
    if (name is! String) return null;
    final type = JamCommandType.values.where((t) => t.name == name).firstOrNull;
    if (type == null) return null;
    int? i(String k) => j[k] is int ? j[k] as int : null;
    switch (type) {
      case JamCommandType.add:
        final item = JamItem.tryParse(j['item']);
        return item == null ? null : JamCommand.add(item);
      case JamCommandType.remove:
        final id = i('itemId');
        return id == null ? null : JamCommand.remove(id);
      case JamCommandType.move:
        final id = i('itemId'), to = i('to');
        return id == null || to == null ? null : JamCommand.move(id, to);
      case JamCommandType.play:
        return const JamCommand.play();
      case JamCommandType.pause:
        return const JamCommand.pause();
      case JamCommandType.seek:
        final p = i('pos');
        return p == null ? null : JamCommand.seek(p);
      case JamCommandType.volume:
        final v = j['volume'];
        return v is num ? JamCommand.volume(v.toDouble()) : null;
      case JamCommandType.setOutput:
        final d = j['device'];
        return d is String && d.isNotEmpty && d.length <= 64
            ? JamCommand.setOutput(d)
            : null;
      case JamCommandType.setOutputs:
        final d = j['devices'];
        if (d is! List || d.isEmpty || d.length > maxJamParticipants) return null;
        final ids = <String>[];
        for (final e in d) {
          if (e is! String || e.isEmpty || e.length > 64) return null;
          ids.add(e);
        }
        return JamCommand.setOutputs(ids);
      case JamCommandType.next:
        return const JamCommand.next();
      case JamCommandType.jump:
        final id = i('itemId');
        return id == null ? null : JamCommand.jump(id);
      case JamCommandType.trackEnded:
        final id = i('itemId');
        return id == null ? null : JamCommand.trackEnded(id);
      case JamCommandType.end:
        return const JamCommand.end();
    }
  }
}

enum JamError {
  forbidden,
  notFound,
  invalid,
  full,
  ended,
}

class JamResult {
  const JamResult.ok(this.state) : error = null;
  const JamResult.fail(this.error) : state = null;

  final JamState? state;
  final JamError? error;
  bool get isOk => state != null;
}
