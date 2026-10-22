/// One radio station as Radio Browser describes it. Fields are read
/// defensively: the data is typed in by hand by the stations' own staff.
class RadioStation {
  const RadioStation({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.homepage = '',
    this.faviconUrl = '',
    this.countryCode = '',
    this.state = '',
    this.tags = const [],
    this.codec = '',
    this.bitrate = 0,
    this.hls = false,
    this.clickCount = 0,
    this.lastCheckOk = true,
  });

  /// `stationuuid`, or `manual:<uuid>` for an address added by hand.
  final String id;
  final String name, streamUrl, homepage, faviconUrl, countryCode, state, codec;
  final List<String> tags;
  final int bitrate, clickCount;
  final bool hls, lastCheckOk;

  bool get isHttps => streamUrl.startsWith('https:');

  /// Null when the entry has no id or no playable address.
  static RadioStation? fromApi(Map<dynamic, dynamic> j) {
    final id = _str(j['stationuuid']);
    final resolved = _str(j['url_resolved']);
    final url = resolved.isNotEmpty ? resolved : _str(j['url']);
    if (id.isEmpty || url.isEmpty) return null;
    final name = _str(j['name']);
    return RadioStation(
      id: id,
      name: name.isEmpty ? url : name,
      streamUrl: url,
      homepage: _str(j['homepage']),
      faviconUrl: _str(j['favicon']),
      countryCode: _str(j['countrycode']).toUpperCase(),
      state: _str(j['state']),
      tags: splitTags(_str(j['tags'])),
      codec: _str(j['codec']),
      bitrate: _int(j['bitrate']),
      hls: _flag(j['hls']),
      clickCount: _int(j['clickcount']),
      lastCheckOk: j.containsKey('lastcheckok') ? _flag(j['lastcheckok']) : true,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'streamUrl': streamUrl,
        'homepage': homepage,
        'faviconUrl': faviconUrl,
        'countryCode': countryCode,
        'state': state,
        'tags': tags,
        'codec': codec,
        'bitrate': bitrate,
        'hls': hls,
        'clickCount': clickCount,
        'lastCheckOk': lastCheckOk,
      };

  /// Reads what [toJson] wrote; null when it lacks an id or an address.
  static RadioStation? fromJson(Map<dynamic, dynamic> j) {
    final id = _str(j['id']), url = _str(j['streamUrl']);
    if (id.isEmpty || url.isEmpty) return null;
    return RadioStation(
      id: id,
      name: _str(j['name']),
      streamUrl: url,
      homepage: _str(j['homepage']),
      faviconUrl: _str(j['faviconUrl']),
      countryCode: _str(j['countryCode']),
      state: _str(j['state']),
      tags: [for (final t in (j['tags'] as List? ?? const [])) '$t'],
      codec: _str(j['codec']),
      bitrate: _int(j['bitrate']),
      hls: j['hls'] == true,
      clickCount: _int(j['clickCount']),
      lastCheckOk: j['lastCheckOk'] != false,
    );
  }

  RadioStation copyWith({String? name, String? streamUrl}) => RadioStation(
        id: id,
        name: name ?? this.name,
        streamUrl: streamUrl ?? this.streamUrl,
        homepage: homepage,
        faviconUrl: faviconUrl,
        countryCode: countryCode,
        state: state,
        tags: tags,
        codec: codec,
        bitrate: bitrate,
        hls: hls,
        clickCount: clickCount,
        lastCheckOk: lastCheckOk,
      );
}

/// «pop, rock» / «pop rock» / «pop,rock» as a list, without blanks.
List<String> splitTags(String raw) =>
    [for (final t in raw.split(',')) if (t.trim().isNotEmpty) t.trim()];

String _str(Object? v) => v is String ? v.trim() : (v == null ? '' : '$v');

int _int(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

bool _flag(Object? v) => v == true || v == 1 || v == '1';
