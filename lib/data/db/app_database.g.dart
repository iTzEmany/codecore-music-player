// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TracksTable extends Tracks with TableInfo<$TracksTable, Track> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<int> folderId = GeneratedColumn<int>(
    'folder_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _albumArtistMeta = const VerificationMeta(
    'albumArtist',
  );
  @override
  late final GeneratedColumn<String> albumArtist = GeneratedColumn<String>(
    'album_artist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<String> album = GeneratedColumn<String>(
    'album',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _albumKeyMeta = const VerificationMeta(
    'albumKey',
  );
  @override
  late final GeneratedColumn<String> albumKey = GeneratedColumn<String>(
    'album_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackNumberMeta = const VerificationMeta(
    'trackNumber',
  );
  @override
  late final GeneratedColumn<int> trackNumber = GeneratedColumn<int>(
    'track_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _discNumberMeta = const VerificationMeta(
    'discNumber',
  );
  @override
  late final GeneratedColumn<int> discNumber = GeneratedColumn<int>(
    'disc_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
    'genre',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sampleRateHzMeta = const VerificationMeta(
    'sampleRateHz',
  );
  @override
  late final GeneratedColumn<int> sampleRateHz = GeneratedColumn<int>(
    'sample_rate_hz',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bitDepthMeta = const VerificationMeta(
    'bitDepth',
  );
  @override
  late final GeneratedColumn<int> bitDepth = GeneratedColumn<int>(
    'bit_depth',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bitrateKbpsMeta = const VerificationMeta(
    'bitrateKbps',
  );
  @override
  late final GeneratedColumn<int> bitrateKbps = GeneratedColumn<int>(
    'bitrate_kbps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _channelsMeta = const VerificationMeta(
    'channels',
  );
  @override
  late final GeneratedColumn<int> channels = GeneratedColumn<int>(
    'channels',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mtimeMsMeta = const VerificationMeta(
    'mtimeMs',
  );
  @override
  late final GeneratedColumn<int> mtimeMs = GeneratedColumn<int>(
    'mtime_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hasCoverMeta = const VerificationMeta(
    'hasCover',
  );
  @override
  late final GeneratedColumn<bool> hasCover = GeneratedColumn<bool>(
    'has_cover',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_cover" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _coverKeyMeta = const VerificationMeta(
    'coverKey',
  );
  @override
  late final GeneratedColumn<String> coverKey = GeneratedColumn<String>(
    'cover_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lyricsPlainMeta = const VerificationMeta(
    'lyricsPlain',
  );
  @override
  late final GeneratedColumn<String> lyricsPlain = GeneratedColumn<String>(
    'lyrics_plain',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lyricsSyncedMeta = const VerificationMeta(
    'lyricsSynced',
  );
  @override
  late final GeneratedColumn<String> lyricsSynced = GeneratedColumn<String>(
    'lyrics_synced',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _curiositiesMeta = const VerificationMeta(
    'curiosities',
  );
  @override
  late final GeneratedColumn<String> curiosities = GeneratedColumn<String>(
    'curiosities',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enrichStatusMeta = const VerificationMeta(
    'enrichStatus',
  );
  @override
  late final GeneratedColumn<int> enrichStatus = GeneratedColumn<int>(
    'enrich_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _userEditedMeta = const VerificationMeta(
    'userEdited',
  );
  @override
  late final GeneratedColumn<bool> userEdited = GeneratedColumn<bool>(
    'user_edited',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("user_edited" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _missingMeta = const VerificationMeta(
    'missing',
  );
  @override
  late final GeneratedColumn<bool> missing = GeneratedColumn<bool>(
    'missing',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("missing" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playCountMeta = const VerificationMeta(
    'playCount',
  );
  @override
  late final GeneratedColumn<int> playCount = GeneratedColumn<int>(
    'play_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _replayGainDbMeta = const VerificationMeta(
    'replayGainDb',
  );
  @override
  late final GeneratedColumn<double> replayGainDb = GeneratedColumn<double>(
    'replay_gain_db',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resumePositionMsMeta = const VerificationMeta(
    'resumePositionMs',
  );
  @override
  late final GeneratedColumn<int> resumePositionMs = GeneratedColumn<int>(
    'resume_position_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastPlayedAtMeta = const VerificationMeta(
    'lastPlayedAt',
  );
  @override
  late final GeneratedColumn<int> lastPlayedAt = GeneratedColumn<int>(
    'last_played_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    path,
    folderId,
    title,
    artist,
    albumArtist,
    album,
    albumKey,
    trackNumber,
    discNumber,
    year,
    genre,
    durationMs,
    format,
    sampleRateHz,
    bitDepth,
    bitrateKbps,
    channels,
    sizeBytes,
    mtimeMs,
    hasCover,
    coverKey,
    isFavorite,
    lyricsPlain,
    lyricsSynced,
    curiosities,
    enrichStatus,
    userEdited,
    missing,
    sha256,
    addedAt,
    playCount,
    replayGainDb,
    resumePositionMs,
    lastPlayedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Track> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    }
    if (data.containsKey('album_artist')) {
      context.handle(
        _albumArtistMeta,
        albumArtist.isAcceptableOrUnknown(
          data['album_artist']!,
          _albumArtistMeta,
        ),
      );
    }
    if (data.containsKey('album')) {
      context.handle(
        _albumMeta,
        album.isAcceptableOrUnknown(data['album']!, _albumMeta),
      );
    }
    if (data.containsKey('album_key')) {
      context.handle(
        _albumKeyMeta,
        albumKey.isAcceptableOrUnknown(data['album_key']!, _albumKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_albumKeyMeta);
    }
    if (data.containsKey('track_number')) {
      context.handle(
        _trackNumberMeta,
        trackNumber.isAcceptableOrUnknown(
          data['track_number']!,
          _trackNumberMeta,
        ),
      );
    }
    if (data.containsKey('disc_number')) {
      context.handle(
        _discNumberMeta,
        discNumber.isAcceptableOrUnknown(data['disc_number']!, _discNumberMeta),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('genre')) {
      context.handle(
        _genreMeta,
        genre.isAcceptableOrUnknown(data['genre']!, _genreMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('sample_rate_hz')) {
      context.handle(
        _sampleRateHzMeta,
        sampleRateHz.isAcceptableOrUnknown(
          data['sample_rate_hz']!,
          _sampleRateHzMeta,
        ),
      );
    }
    if (data.containsKey('bit_depth')) {
      context.handle(
        _bitDepthMeta,
        bitDepth.isAcceptableOrUnknown(data['bit_depth']!, _bitDepthMeta),
      );
    }
    if (data.containsKey('bitrate_kbps')) {
      context.handle(
        _bitrateKbpsMeta,
        bitrateKbps.isAcceptableOrUnknown(
          data['bitrate_kbps']!,
          _bitrateKbpsMeta,
        ),
      );
    }
    if (data.containsKey('channels')) {
      context.handle(
        _channelsMeta,
        channels.isAcceptableOrUnknown(data['channels']!, _channelsMeta),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('mtime_ms')) {
      context.handle(
        _mtimeMsMeta,
        mtimeMs.isAcceptableOrUnknown(data['mtime_ms']!, _mtimeMsMeta),
      );
    } else if (isInserting) {
      context.missing(_mtimeMsMeta);
    }
    if (data.containsKey('has_cover')) {
      context.handle(
        _hasCoverMeta,
        hasCover.isAcceptableOrUnknown(data['has_cover']!, _hasCoverMeta),
      );
    }
    if (data.containsKey('cover_key')) {
      context.handle(
        _coverKeyMeta,
        coverKey.isAcceptableOrUnknown(data['cover_key']!, _coverKeyMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('lyrics_plain')) {
      context.handle(
        _lyricsPlainMeta,
        lyricsPlain.isAcceptableOrUnknown(
          data['lyrics_plain']!,
          _lyricsPlainMeta,
        ),
      );
    }
    if (data.containsKey('lyrics_synced')) {
      context.handle(
        _lyricsSyncedMeta,
        lyricsSynced.isAcceptableOrUnknown(
          data['lyrics_synced']!,
          _lyricsSyncedMeta,
        ),
      );
    }
    if (data.containsKey('curiosities')) {
      context.handle(
        _curiositiesMeta,
        curiosities.isAcceptableOrUnknown(
          data['curiosities']!,
          _curiositiesMeta,
        ),
      );
    }
    if (data.containsKey('enrich_status')) {
      context.handle(
        _enrichStatusMeta,
        enrichStatus.isAcceptableOrUnknown(
          data['enrich_status']!,
          _enrichStatusMeta,
        ),
      );
    }
    if (data.containsKey('user_edited')) {
      context.handle(
        _userEditedMeta,
        userEdited.isAcceptableOrUnknown(data['user_edited']!, _userEditedMeta),
      );
    }
    if (data.containsKey('missing')) {
      context.handle(
        _missingMeta,
        missing.isAcceptableOrUnknown(data['missing']!, _missingMeta),
      );
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('play_count')) {
      context.handle(
        _playCountMeta,
        playCount.isAcceptableOrUnknown(data['play_count']!, _playCountMeta),
      );
    }
    if (data.containsKey('replay_gain_db')) {
      context.handle(
        _replayGainDbMeta,
        replayGainDb.isAcceptableOrUnknown(
          data['replay_gain_db']!,
          _replayGainDbMeta,
        ),
      );
    }
    if (data.containsKey('resume_position_ms')) {
      context.handle(
        _resumePositionMsMeta,
        resumePositionMs.isAcceptableOrUnknown(
          data['resume_position_ms']!,
          _resumePositionMsMeta,
        ),
      );
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
        _lastPlayedAtMeta,
        lastPlayedAt.isAcceptableOrUnknown(
          data['last_played_at']!,
          _lastPlayedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Track map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Track(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}folder_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      ),
      albumArtist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_artist'],
      ),
      album: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album'],
      ),
      albumKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_key'],
      )!,
      trackNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_number'],
      ),
      discNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}disc_number'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      genre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
      sampleRateHz: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sample_rate_hz'],
      ),
      bitDepth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bit_depth'],
      ),
      bitrateKbps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bitrate_kbps'],
      ),
      channels: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}channels'],
      ),
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      mtimeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mtime_ms'],
      )!,
      hasCover: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_cover'],
      )!,
      coverKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_key'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      lyricsPlain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lyrics_plain'],
      ),
      lyricsSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lyrics_synced'],
      ),
      curiosities: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}curiosities'],
      ),
      enrichStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}enrich_status'],
      )!,
      userEdited: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}user_edited'],
      )!,
      missing: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}missing'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      ),
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_at'],
      )!,
      playCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}play_count'],
      )!,
      replayGainDb: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}replay_gain_db'],
      ),
      resumePositionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resume_position_ms'],
      ),
      lastPlayedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_played_at'],
      ),
    );
  }

  @override
  $TracksTable createAlias(String alias) {
    return $TracksTable(attachedDatabase, alias);
  }
}

class Track extends DataClass implements Insertable<Track> {
  final int id;
  final String path;
  final int? folderId;
  final String title;
  final String? artist;
  final String? albumArtist;
  final String? album;
  final String albumKey;
  final int? trackNumber;
  final int? discNumber;
  final int? year;
  final String? genre;
  final int durationMs;
  final String format;
  final int? sampleRateHz;
  final int? bitDepth;
  final int? bitrateKbps;
  final int? channels;
  final int sizeBytes;
  final int mtimeMs;
  final bool hasCover;
  final String? coverKey;
  final bool isFavorite;
  final String? lyricsPlain;
  final String? lyricsSynced;
  final String? curiosities;
  final int enrichStatus;
  final bool userEdited;
  final bool missing;
  final String? sha256;
  final int addedAt;
  final int playCount;
  final double? replayGainDb;

  /// «Riprendi da qui»: where a long track (≥ 20 min) was left; null = none.
  final int? resumePositionMs;
  final int? lastPlayedAt;
  const Track({
    required this.id,
    required this.path,
    this.folderId,
    required this.title,
    this.artist,
    this.albumArtist,
    this.album,
    required this.albumKey,
    this.trackNumber,
    this.discNumber,
    this.year,
    this.genre,
    required this.durationMs,
    required this.format,
    this.sampleRateHz,
    this.bitDepth,
    this.bitrateKbps,
    this.channels,
    required this.sizeBytes,
    required this.mtimeMs,
    required this.hasCover,
    this.coverKey,
    required this.isFavorite,
    this.lyricsPlain,
    this.lyricsSynced,
    this.curiosities,
    required this.enrichStatus,
    required this.userEdited,
    required this.missing,
    this.sha256,
    required this.addedAt,
    required this.playCount,
    this.replayGainDb,
    this.resumePositionMs,
    this.lastPlayedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['path'] = Variable<String>(path);
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<int>(folderId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || artist != null) {
      map['artist'] = Variable<String>(artist);
    }
    if (!nullToAbsent || albumArtist != null) {
      map['album_artist'] = Variable<String>(albumArtist);
    }
    if (!nullToAbsent || album != null) {
      map['album'] = Variable<String>(album);
    }
    map['album_key'] = Variable<String>(albumKey);
    if (!nullToAbsent || trackNumber != null) {
      map['track_number'] = Variable<int>(trackNumber);
    }
    if (!nullToAbsent || discNumber != null) {
      map['disc_number'] = Variable<int>(discNumber);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || genre != null) {
      map['genre'] = Variable<String>(genre);
    }
    map['duration_ms'] = Variable<int>(durationMs);
    map['format'] = Variable<String>(format);
    if (!nullToAbsent || sampleRateHz != null) {
      map['sample_rate_hz'] = Variable<int>(sampleRateHz);
    }
    if (!nullToAbsent || bitDepth != null) {
      map['bit_depth'] = Variable<int>(bitDepth);
    }
    if (!nullToAbsent || bitrateKbps != null) {
      map['bitrate_kbps'] = Variable<int>(bitrateKbps);
    }
    if (!nullToAbsent || channels != null) {
      map['channels'] = Variable<int>(channels);
    }
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['mtime_ms'] = Variable<int>(mtimeMs);
    map['has_cover'] = Variable<bool>(hasCover);
    if (!nullToAbsent || coverKey != null) {
      map['cover_key'] = Variable<String>(coverKey);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || lyricsPlain != null) {
      map['lyrics_plain'] = Variable<String>(lyricsPlain);
    }
    if (!nullToAbsent || lyricsSynced != null) {
      map['lyrics_synced'] = Variable<String>(lyricsSynced);
    }
    if (!nullToAbsent || curiosities != null) {
      map['curiosities'] = Variable<String>(curiosities);
    }
    map['enrich_status'] = Variable<int>(enrichStatus);
    map['user_edited'] = Variable<bool>(userEdited);
    map['missing'] = Variable<bool>(missing);
    if (!nullToAbsent || sha256 != null) {
      map['sha256'] = Variable<String>(sha256);
    }
    map['added_at'] = Variable<int>(addedAt);
    map['play_count'] = Variable<int>(playCount);
    if (!nullToAbsent || replayGainDb != null) {
      map['replay_gain_db'] = Variable<double>(replayGainDb);
    }
    if (!nullToAbsent || resumePositionMs != null) {
      map['resume_position_ms'] = Variable<int>(resumePositionMs);
    }
    if (!nullToAbsent || lastPlayedAt != null) {
      map['last_played_at'] = Variable<int>(lastPlayedAt);
    }
    return map;
  }

  TracksCompanion toCompanion(bool nullToAbsent) {
    return TracksCompanion(
      id: Value(id),
      path: Value(path),
      folderId: folderId == null && nullToAbsent
          ? const Value.absent()
          : Value(folderId),
      title: Value(title),
      artist: artist == null && nullToAbsent
          ? const Value.absent()
          : Value(artist),
      albumArtist: albumArtist == null && nullToAbsent
          ? const Value.absent()
          : Value(albumArtist),
      album: album == null && nullToAbsent
          ? const Value.absent()
          : Value(album),
      albumKey: Value(albumKey),
      trackNumber: trackNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(trackNumber),
      discNumber: discNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(discNumber),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      genre: genre == null && nullToAbsent
          ? const Value.absent()
          : Value(genre),
      durationMs: Value(durationMs),
      format: Value(format),
      sampleRateHz: sampleRateHz == null && nullToAbsent
          ? const Value.absent()
          : Value(sampleRateHz),
      bitDepth: bitDepth == null && nullToAbsent
          ? const Value.absent()
          : Value(bitDepth),
      bitrateKbps: bitrateKbps == null && nullToAbsent
          ? const Value.absent()
          : Value(bitrateKbps),
      channels: channels == null && nullToAbsent
          ? const Value.absent()
          : Value(channels),
      sizeBytes: Value(sizeBytes),
      mtimeMs: Value(mtimeMs),
      hasCover: Value(hasCover),
      coverKey: coverKey == null && nullToAbsent
          ? const Value.absent()
          : Value(coverKey),
      isFavorite: Value(isFavorite),
      lyricsPlain: lyricsPlain == null && nullToAbsent
          ? const Value.absent()
          : Value(lyricsPlain),
      lyricsSynced: lyricsSynced == null && nullToAbsent
          ? const Value.absent()
          : Value(lyricsSynced),
      curiosities: curiosities == null && nullToAbsent
          ? const Value.absent()
          : Value(curiosities),
      enrichStatus: Value(enrichStatus),
      userEdited: Value(userEdited),
      missing: Value(missing),
      sha256: sha256 == null && nullToAbsent
          ? const Value.absent()
          : Value(sha256),
      addedAt: Value(addedAt),
      playCount: Value(playCount),
      replayGainDb: replayGainDb == null && nullToAbsent
          ? const Value.absent()
          : Value(replayGainDb),
      resumePositionMs: resumePositionMs == null && nullToAbsent
          ? const Value.absent()
          : Value(resumePositionMs),
      lastPlayedAt: lastPlayedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedAt),
    );
  }

  factory Track.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Track(
      id: serializer.fromJson<int>(json['id']),
      path: serializer.fromJson<String>(json['path']),
      folderId: serializer.fromJson<int?>(json['folderId']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String?>(json['artist']),
      albumArtist: serializer.fromJson<String?>(json['albumArtist']),
      album: serializer.fromJson<String?>(json['album']),
      albumKey: serializer.fromJson<String>(json['albumKey']),
      trackNumber: serializer.fromJson<int?>(json['trackNumber']),
      discNumber: serializer.fromJson<int?>(json['discNumber']),
      year: serializer.fromJson<int?>(json['year']),
      genre: serializer.fromJson<String?>(json['genre']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      format: serializer.fromJson<String>(json['format']),
      sampleRateHz: serializer.fromJson<int?>(json['sampleRateHz']),
      bitDepth: serializer.fromJson<int?>(json['bitDepth']),
      bitrateKbps: serializer.fromJson<int?>(json['bitrateKbps']),
      channels: serializer.fromJson<int?>(json['channels']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      mtimeMs: serializer.fromJson<int>(json['mtimeMs']),
      hasCover: serializer.fromJson<bool>(json['hasCover']),
      coverKey: serializer.fromJson<String?>(json['coverKey']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      lyricsPlain: serializer.fromJson<String?>(json['lyricsPlain']),
      lyricsSynced: serializer.fromJson<String?>(json['lyricsSynced']),
      curiosities: serializer.fromJson<String?>(json['curiosities']),
      enrichStatus: serializer.fromJson<int>(json['enrichStatus']),
      userEdited: serializer.fromJson<bool>(json['userEdited']),
      missing: serializer.fromJson<bool>(json['missing']),
      sha256: serializer.fromJson<String?>(json['sha256']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
      playCount: serializer.fromJson<int>(json['playCount']),
      replayGainDb: serializer.fromJson<double?>(json['replayGainDb']),
      resumePositionMs: serializer.fromJson<int?>(json['resumePositionMs']),
      lastPlayedAt: serializer.fromJson<int?>(json['lastPlayedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'path': serializer.toJson<String>(path),
      'folderId': serializer.toJson<int?>(folderId),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String?>(artist),
      'albumArtist': serializer.toJson<String?>(albumArtist),
      'album': serializer.toJson<String?>(album),
      'albumKey': serializer.toJson<String>(albumKey),
      'trackNumber': serializer.toJson<int?>(trackNumber),
      'discNumber': serializer.toJson<int?>(discNumber),
      'year': serializer.toJson<int?>(year),
      'genre': serializer.toJson<String?>(genre),
      'durationMs': serializer.toJson<int>(durationMs),
      'format': serializer.toJson<String>(format),
      'sampleRateHz': serializer.toJson<int?>(sampleRateHz),
      'bitDepth': serializer.toJson<int?>(bitDepth),
      'bitrateKbps': serializer.toJson<int?>(bitrateKbps),
      'channels': serializer.toJson<int?>(channels),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'mtimeMs': serializer.toJson<int>(mtimeMs),
      'hasCover': serializer.toJson<bool>(hasCover),
      'coverKey': serializer.toJson<String?>(coverKey),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'lyricsPlain': serializer.toJson<String?>(lyricsPlain),
      'lyricsSynced': serializer.toJson<String?>(lyricsSynced),
      'curiosities': serializer.toJson<String?>(curiosities),
      'enrichStatus': serializer.toJson<int>(enrichStatus),
      'userEdited': serializer.toJson<bool>(userEdited),
      'missing': serializer.toJson<bool>(missing),
      'sha256': serializer.toJson<String?>(sha256),
      'addedAt': serializer.toJson<int>(addedAt),
      'playCount': serializer.toJson<int>(playCount),
      'replayGainDb': serializer.toJson<double?>(replayGainDb),
      'resumePositionMs': serializer.toJson<int?>(resumePositionMs),
      'lastPlayedAt': serializer.toJson<int?>(lastPlayedAt),
    };
  }

  Track copyWith({
    int? id,
    String? path,
    Value<int?> folderId = const Value.absent(),
    String? title,
    Value<String?> artist = const Value.absent(),
    Value<String?> albumArtist = const Value.absent(),
    Value<String?> album = const Value.absent(),
    String? albumKey,
    Value<int?> trackNumber = const Value.absent(),
    Value<int?> discNumber = const Value.absent(),
    Value<int?> year = const Value.absent(),
    Value<String?> genre = const Value.absent(),
    int? durationMs,
    String? format,
    Value<int?> sampleRateHz = const Value.absent(),
    Value<int?> bitDepth = const Value.absent(),
    Value<int?> bitrateKbps = const Value.absent(),
    Value<int?> channels = const Value.absent(),
    int? sizeBytes,
    int? mtimeMs,
    bool? hasCover,
    Value<String?> coverKey = const Value.absent(),
    bool? isFavorite,
    Value<String?> lyricsPlain = const Value.absent(),
    Value<String?> lyricsSynced = const Value.absent(),
    Value<String?> curiosities = const Value.absent(),
    int? enrichStatus,
    bool? userEdited,
    bool? missing,
    Value<String?> sha256 = const Value.absent(),
    int? addedAt,
    int? playCount,
    Value<double?> replayGainDb = const Value.absent(),
    Value<int?> resumePositionMs = const Value.absent(),
    Value<int?> lastPlayedAt = const Value.absent(),
  }) => Track(
    id: id ?? this.id,
    path: path ?? this.path,
    folderId: folderId.present ? folderId.value : this.folderId,
    title: title ?? this.title,
    artist: artist.present ? artist.value : this.artist,
    albumArtist: albumArtist.present ? albumArtist.value : this.albumArtist,
    album: album.present ? album.value : this.album,
    albumKey: albumKey ?? this.albumKey,
    trackNumber: trackNumber.present ? trackNumber.value : this.trackNumber,
    discNumber: discNumber.present ? discNumber.value : this.discNumber,
    year: year.present ? year.value : this.year,
    genre: genre.present ? genre.value : this.genre,
    durationMs: durationMs ?? this.durationMs,
    format: format ?? this.format,
    sampleRateHz: sampleRateHz.present ? sampleRateHz.value : this.sampleRateHz,
    bitDepth: bitDepth.present ? bitDepth.value : this.bitDepth,
    bitrateKbps: bitrateKbps.present ? bitrateKbps.value : this.bitrateKbps,
    channels: channels.present ? channels.value : this.channels,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    mtimeMs: mtimeMs ?? this.mtimeMs,
    hasCover: hasCover ?? this.hasCover,
    coverKey: coverKey.present ? coverKey.value : this.coverKey,
    isFavorite: isFavorite ?? this.isFavorite,
    lyricsPlain: lyricsPlain.present ? lyricsPlain.value : this.lyricsPlain,
    lyricsSynced: lyricsSynced.present ? lyricsSynced.value : this.lyricsSynced,
    curiosities: curiosities.present ? curiosities.value : this.curiosities,
    enrichStatus: enrichStatus ?? this.enrichStatus,
    userEdited: userEdited ?? this.userEdited,
    missing: missing ?? this.missing,
    sha256: sha256.present ? sha256.value : this.sha256,
    addedAt: addedAt ?? this.addedAt,
    playCount: playCount ?? this.playCount,
    replayGainDb: replayGainDb.present ? replayGainDb.value : this.replayGainDb,
    resumePositionMs: resumePositionMs.present
        ? resumePositionMs.value
        : this.resumePositionMs,
    lastPlayedAt: lastPlayedAt.present ? lastPlayedAt.value : this.lastPlayedAt,
  );
  Track copyWithCompanion(TracksCompanion data) {
    return Track(
      id: data.id.present ? data.id.value : this.id,
      path: data.path.present ? data.path.value : this.path,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      albumArtist: data.albumArtist.present
          ? data.albumArtist.value
          : this.albumArtist,
      album: data.album.present ? data.album.value : this.album,
      albumKey: data.albumKey.present ? data.albumKey.value : this.albumKey,
      trackNumber: data.trackNumber.present
          ? data.trackNumber.value
          : this.trackNumber,
      discNumber: data.discNumber.present
          ? data.discNumber.value
          : this.discNumber,
      year: data.year.present ? data.year.value : this.year,
      genre: data.genre.present ? data.genre.value : this.genre,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      format: data.format.present ? data.format.value : this.format,
      sampleRateHz: data.sampleRateHz.present
          ? data.sampleRateHz.value
          : this.sampleRateHz,
      bitDepth: data.bitDepth.present ? data.bitDepth.value : this.bitDepth,
      bitrateKbps: data.bitrateKbps.present
          ? data.bitrateKbps.value
          : this.bitrateKbps,
      channels: data.channels.present ? data.channels.value : this.channels,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      mtimeMs: data.mtimeMs.present ? data.mtimeMs.value : this.mtimeMs,
      hasCover: data.hasCover.present ? data.hasCover.value : this.hasCover,
      coverKey: data.coverKey.present ? data.coverKey.value : this.coverKey,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      lyricsPlain: data.lyricsPlain.present
          ? data.lyricsPlain.value
          : this.lyricsPlain,
      lyricsSynced: data.lyricsSynced.present
          ? data.lyricsSynced.value
          : this.lyricsSynced,
      curiosities: data.curiosities.present
          ? data.curiosities.value
          : this.curiosities,
      enrichStatus: data.enrichStatus.present
          ? data.enrichStatus.value
          : this.enrichStatus,
      userEdited: data.userEdited.present
          ? data.userEdited.value
          : this.userEdited,
      missing: data.missing.present ? data.missing.value : this.missing,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      playCount: data.playCount.present ? data.playCount.value : this.playCount,
      replayGainDb: data.replayGainDb.present
          ? data.replayGainDb.value
          : this.replayGainDb,
      resumePositionMs: data.resumePositionMs.present
          ? data.resumePositionMs.value
          : this.resumePositionMs,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Track(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('folderId: $folderId, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('albumArtist: $albumArtist, ')
          ..write('album: $album, ')
          ..write('albumKey: $albumKey, ')
          ..write('trackNumber: $trackNumber, ')
          ..write('discNumber: $discNumber, ')
          ..write('year: $year, ')
          ..write('genre: $genre, ')
          ..write('durationMs: $durationMs, ')
          ..write('format: $format, ')
          ..write('sampleRateHz: $sampleRateHz, ')
          ..write('bitDepth: $bitDepth, ')
          ..write('bitrateKbps: $bitrateKbps, ')
          ..write('channels: $channels, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('mtimeMs: $mtimeMs, ')
          ..write('hasCover: $hasCover, ')
          ..write('coverKey: $coverKey, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('lyricsPlain: $lyricsPlain, ')
          ..write('lyricsSynced: $lyricsSynced, ')
          ..write('curiosities: $curiosities, ')
          ..write('enrichStatus: $enrichStatus, ')
          ..write('userEdited: $userEdited, ')
          ..write('missing: $missing, ')
          ..write('sha256: $sha256, ')
          ..write('addedAt: $addedAt, ')
          ..write('playCount: $playCount, ')
          ..write('replayGainDb: $replayGainDb, ')
          ..write('resumePositionMs: $resumePositionMs, ')
          ..write('lastPlayedAt: $lastPlayedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    path,
    folderId,
    title,
    artist,
    albumArtist,
    album,
    albumKey,
    trackNumber,
    discNumber,
    year,
    genre,
    durationMs,
    format,
    sampleRateHz,
    bitDepth,
    bitrateKbps,
    channels,
    sizeBytes,
    mtimeMs,
    hasCover,
    coverKey,
    isFavorite,
    lyricsPlain,
    lyricsSynced,
    curiosities,
    enrichStatus,
    userEdited,
    missing,
    sha256,
    addedAt,
    playCount,
    replayGainDb,
    resumePositionMs,
    lastPlayedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Track &&
          other.id == this.id &&
          other.path == this.path &&
          other.folderId == this.folderId &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.albumArtist == this.albumArtist &&
          other.album == this.album &&
          other.albumKey == this.albumKey &&
          other.trackNumber == this.trackNumber &&
          other.discNumber == this.discNumber &&
          other.year == this.year &&
          other.genre == this.genre &&
          other.durationMs == this.durationMs &&
          other.format == this.format &&
          other.sampleRateHz == this.sampleRateHz &&
          other.bitDepth == this.bitDepth &&
          other.bitrateKbps == this.bitrateKbps &&
          other.channels == this.channels &&
          other.sizeBytes == this.sizeBytes &&
          other.mtimeMs == this.mtimeMs &&
          other.hasCover == this.hasCover &&
          other.coverKey == this.coverKey &&
          other.isFavorite == this.isFavorite &&
          other.lyricsPlain == this.lyricsPlain &&
          other.lyricsSynced == this.lyricsSynced &&
          other.curiosities == this.curiosities &&
          other.enrichStatus == this.enrichStatus &&
          other.userEdited == this.userEdited &&
          other.missing == this.missing &&
          other.sha256 == this.sha256 &&
          other.addedAt == this.addedAt &&
          other.playCount == this.playCount &&
          other.replayGainDb == this.replayGainDb &&
          other.resumePositionMs == this.resumePositionMs &&
          other.lastPlayedAt == this.lastPlayedAt);
}

class TracksCompanion extends UpdateCompanion<Track> {
  final Value<int> id;
  final Value<String> path;
  final Value<int?> folderId;
  final Value<String> title;
  final Value<String?> artist;
  final Value<String?> albumArtist;
  final Value<String?> album;
  final Value<String> albumKey;
  final Value<int?> trackNumber;
  final Value<int?> discNumber;
  final Value<int?> year;
  final Value<String?> genre;
  final Value<int> durationMs;
  final Value<String> format;
  final Value<int?> sampleRateHz;
  final Value<int?> bitDepth;
  final Value<int?> bitrateKbps;
  final Value<int?> channels;
  final Value<int> sizeBytes;
  final Value<int> mtimeMs;
  final Value<bool> hasCover;
  final Value<String?> coverKey;
  final Value<bool> isFavorite;
  final Value<String?> lyricsPlain;
  final Value<String?> lyricsSynced;
  final Value<String?> curiosities;
  final Value<int> enrichStatus;
  final Value<bool> userEdited;
  final Value<bool> missing;
  final Value<String?> sha256;
  final Value<int> addedAt;
  final Value<int> playCount;
  final Value<double?> replayGainDb;
  final Value<int?> resumePositionMs;
  final Value<int?> lastPlayedAt;
  const TracksCompanion({
    this.id = const Value.absent(),
    this.path = const Value.absent(),
    this.folderId = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.albumArtist = const Value.absent(),
    this.album = const Value.absent(),
    this.albumKey = const Value.absent(),
    this.trackNumber = const Value.absent(),
    this.discNumber = const Value.absent(),
    this.year = const Value.absent(),
    this.genre = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.format = const Value.absent(),
    this.sampleRateHz = const Value.absent(),
    this.bitDepth = const Value.absent(),
    this.bitrateKbps = const Value.absent(),
    this.channels = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.mtimeMs = const Value.absent(),
    this.hasCover = const Value.absent(),
    this.coverKey = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.lyricsPlain = const Value.absent(),
    this.lyricsSynced = const Value.absent(),
    this.curiosities = const Value.absent(),
    this.enrichStatus = const Value.absent(),
    this.userEdited = const Value.absent(),
    this.missing = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.playCount = const Value.absent(),
    this.replayGainDb = const Value.absent(),
    this.resumePositionMs = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
  });
  TracksCompanion.insert({
    this.id = const Value.absent(),
    required String path,
    this.folderId = const Value.absent(),
    required String title,
    this.artist = const Value.absent(),
    this.albumArtist = const Value.absent(),
    this.album = const Value.absent(),
    required String albumKey,
    this.trackNumber = const Value.absent(),
    this.discNumber = const Value.absent(),
    this.year = const Value.absent(),
    this.genre = const Value.absent(),
    this.durationMs = const Value.absent(),
    required String format,
    this.sampleRateHz = const Value.absent(),
    this.bitDepth = const Value.absent(),
    this.bitrateKbps = const Value.absent(),
    this.channels = const Value.absent(),
    required int sizeBytes,
    required int mtimeMs,
    this.hasCover = const Value.absent(),
    this.coverKey = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.lyricsPlain = const Value.absent(),
    this.lyricsSynced = const Value.absent(),
    this.curiosities = const Value.absent(),
    this.enrichStatus = const Value.absent(),
    this.userEdited = const Value.absent(),
    this.missing = const Value.absent(),
    this.sha256 = const Value.absent(),
    required int addedAt,
    this.playCount = const Value.absent(),
    this.replayGainDb = const Value.absent(),
    this.resumePositionMs = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
  }) : path = Value(path),
       title = Value(title),
       albumKey = Value(albumKey),
       format = Value(format),
       sizeBytes = Value(sizeBytes),
       mtimeMs = Value(mtimeMs),
       addedAt = Value(addedAt);
  static Insertable<Track> custom({
    Expression<int>? id,
    Expression<String>? path,
    Expression<int>? folderId,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<String>? albumArtist,
    Expression<String>? album,
    Expression<String>? albumKey,
    Expression<int>? trackNumber,
    Expression<int>? discNumber,
    Expression<int>? year,
    Expression<String>? genre,
    Expression<int>? durationMs,
    Expression<String>? format,
    Expression<int>? sampleRateHz,
    Expression<int>? bitDepth,
    Expression<int>? bitrateKbps,
    Expression<int>? channels,
    Expression<int>? sizeBytes,
    Expression<int>? mtimeMs,
    Expression<bool>? hasCover,
    Expression<String>? coverKey,
    Expression<bool>? isFavorite,
    Expression<String>? lyricsPlain,
    Expression<String>? lyricsSynced,
    Expression<String>? curiosities,
    Expression<int>? enrichStatus,
    Expression<bool>? userEdited,
    Expression<bool>? missing,
    Expression<String>? sha256,
    Expression<int>? addedAt,
    Expression<int>? playCount,
    Expression<double>? replayGainDb,
    Expression<int>? resumePositionMs,
    Expression<int>? lastPlayedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (path != null) 'path': path,
      if (folderId != null) 'folder_id': folderId,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (albumArtist != null) 'album_artist': albumArtist,
      if (album != null) 'album': album,
      if (albumKey != null) 'album_key': albumKey,
      if (trackNumber != null) 'track_number': trackNumber,
      if (discNumber != null) 'disc_number': discNumber,
      if (year != null) 'year': year,
      if (genre != null) 'genre': genre,
      if (durationMs != null) 'duration_ms': durationMs,
      if (format != null) 'format': format,
      if (sampleRateHz != null) 'sample_rate_hz': sampleRateHz,
      if (bitDepth != null) 'bit_depth': bitDepth,
      if (bitrateKbps != null) 'bitrate_kbps': bitrateKbps,
      if (channels != null) 'channels': channels,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (mtimeMs != null) 'mtime_ms': mtimeMs,
      if (hasCover != null) 'has_cover': hasCover,
      if (coverKey != null) 'cover_key': coverKey,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (lyricsPlain != null) 'lyrics_plain': lyricsPlain,
      if (lyricsSynced != null) 'lyrics_synced': lyricsSynced,
      if (curiosities != null) 'curiosities': curiosities,
      if (enrichStatus != null) 'enrich_status': enrichStatus,
      if (userEdited != null) 'user_edited': userEdited,
      if (missing != null) 'missing': missing,
      if (sha256 != null) 'sha256': sha256,
      if (addedAt != null) 'added_at': addedAt,
      if (playCount != null) 'play_count': playCount,
      if (replayGainDb != null) 'replay_gain_db': replayGainDb,
      if (resumePositionMs != null) 'resume_position_ms': resumePositionMs,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
    });
  }

  TracksCompanion copyWith({
    Value<int>? id,
    Value<String>? path,
    Value<int?>? folderId,
    Value<String>? title,
    Value<String?>? artist,
    Value<String?>? albumArtist,
    Value<String?>? album,
    Value<String>? albumKey,
    Value<int?>? trackNumber,
    Value<int?>? discNumber,
    Value<int?>? year,
    Value<String?>? genre,
    Value<int>? durationMs,
    Value<String>? format,
    Value<int?>? sampleRateHz,
    Value<int?>? bitDepth,
    Value<int?>? bitrateKbps,
    Value<int?>? channels,
    Value<int>? sizeBytes,
    Value<int>? mtimeMs,
    Value<bool>? hasCover,
    Value<String?>? coverKey,
    Value<bool>? isFavorite,
    Value<String?>? lyricsPlain,
    Value<String?>? lyricsSynced,
    Value<String?>? curiosities,
    Value<int>? enrichStatus,
    Value<bool>? userEdited,
    Value<bool>? missing,
    Value<String?>? sha256,
    Value<int>? addedAt,
    Value<int>? playCount,
    Value<double?>? replayGainDb,
    Value<int?>? resumePositionMs,
    Value<int?>? lastPlayedAt,
  }) {
    return TracksCompanion(
      id: id ?? this.id,
      path: path ?? this.path,
      folderId: folderId ?? this.folderId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      albumArtist: albumArtist ?? this.albumArtist,
      album: album ?? this.album,
      albumKey: albumKey ?? this.albumKey,
      trackNumber: trackNumber ?? this.trackNumber,
      discNumber: discNumber ?? this.discNumber,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      durationMs: durationMs ?? this.durationMs,
      format: format ?? this.format,
      sampleRateHz: sampleRateHz ?? this.sampleRateHz,
      bitDepth: bitDepth ?? this.bitDepth,
      bitrateKbps: bitrateKbps ?? this.bitrateKbps,
      channels: channels ?? this.channels,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      mtimeMs: mtimeMs ?? this.mtimeMs,
      hasCover: hasCover ?? this.hasCover,
      coverKey: coverKey ?? this.coverKey,
      isFavorite: isFavorite ?? this.isFavorite,
      lyricsPlain: lyricsPlain ?? this.lyricsPlain,
      lyricsSynced: lyricsSynced ?? this.lyricsSynced,
      curiosities: curiosities ?? this.curiosities,
      enrichStatus: enrichStatus ?? this.enrichStatus,
      userEdited: userEdited ?? this.userEdited,
      missing: missing ?? this.missing,
      sha256: sha256 ?? this.sha256,
      addedAt: addedAt ?? this.addedAt,
      playCount: playCount ?? this.playCount,
      replayGainDb: replayGainDb ?? this.replayGainDb,
      resumePositionMs: resumePositionMs ?? this.resumePositionMs,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<int>(folderId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (albumArtist.present) {
      map['album_artist'] = Variable<String>(albumArtist.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (albumKey.present) {
      map['album_key'] = Variable<String>(albumKey.value);
    }
    if (trackNumber.present) {
      map['track_number'] = Variable<int>(trackNumber.value);
    }
    if (discNumber.present) {
      map['disc_number'] = Variable<int>(discNumber.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (sampleRateHz.present) {
      map['sample_rate_hz'] = Variable<int>(sampleRateHz.value);
    }
    if (bitDepth.present) {
      map['bit_depth'] = Variable<int>(bitDepth.value);
    }
    if (bitrateKbps.present) {
      map['bitrate_kbps'] = Variable<int>(bitrateKbps.value);
    }
    if (channels.present) {
      map['channels'] = Variable<int>(channels.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (mtimeMs.present) {
      map['mtime_ms'] = Variable<int>(mtimeMs.value);
    }
    if (hasCover.present) {
      map['has_cover'] = Variable<bool>(hasCover.value);
    }
    if (coverKey.present) {
      map['cover_key'] = Variable<String>(coverKey.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (lyricsPlain.present) {
      map['lyrics_plain'] = Variable<String>(lyricsPlain.value);
    }
    if (lyricsSynced.present) {
      map['lyrics_synced'] = Variable<String>(lyricsSynced.value);
    }
    if (curiosities.present) {
      map['curiosities'] = Variable<String>(curiosities.value);
    }
    if (enrichStatus.present) {
      map['enrich_status'] = Variable<int>(enrichStatus.value);
    }
    if (userEdited.present) {
      map['user_edited'] = Variable<bool>(userEdited.value);
    }
    if (missing.present) {
      map['missing'] = Variable<bool>(missing.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(addedAt.value);
    }
    if (playCount.present) {
      map['play_count'] = Variable<int>(playCount.value);
    }
    if (replayGainDb.present) {
      map['replay_gain_db'] = Variable<double>(replayGainDb.value);
    }
    if (resumePositionMs.present) {
      map['resume_position_ms'] = Variable<int>(resumePositionMs.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<int>(lastPlayedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TracksCompanion(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('folderId: $folderId, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('albumArtist: $albumArtist, ')
          ..write('album: $album, ')
          ..write('albumKey: $albumKey, ')
          ..write('trackNumber: $trackNumber, ')
          ..write('discNumber: $discNumber, ')
          ..write('year: $year, ')
          ..write('genre: $genre, ')
          ..write('durationMs: $durationMs, ')
          ..write('format: $format, ')
          ..write('sampleRateHz: $sampleRateHz, ')
          ..write('bitDepth: $bitDepth, ')
          ..write('bitrateKbps: $bitrateKbps, ')
          ..write('channels: $channels, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('mtimeMs: $mtimeMs, ')
          ..write('hasCover: $hasCover, ')
          ..write('coverKey: $coverKey, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('lyricsPlain: $lyricsPlain, ')
          ..write('lyricsSynced: $lyricsSynced, ')
          ..write('curiosities: $curiosities, ')
          ..write('enrichStatus: $enrichStatus, ')
          ..write('userEdited: $userEdited, ')
          ..write('missing: $missing, ')
          ..write('sha256: $sha256, ')
          ..write('addedAt: $addedAt, ')
          ..write('playCount: $playCount, ')
          ..write('replayGainDb: $replayGainDb, ')
          ..write('resumePositionMs: $resumePositionMs, ')
          ..write('lastPlayedAt: $lastPlayedAt')
          ..write(')'))
        .toString();
  }
}

class $FoldersTable extends Folders with TableInfo<$FoldersTable, Folder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, path, addedAt, label];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Folder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Folder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Folder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_at'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
    );
  }

  @override
  $FoldersTable createAlias(String alias) {
    return $FoldersTable(attachedDatabase, alias);
  }
}

class Folder extends DataClass implements Insertable<Folder> {
  final int id;
  final String path;
  final int addedAt;
  final String? label;
  const Folder({
    required this.id,
    required this.path,
    required this.addedAt,
    this.label,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['path'] = Variable<String>(path);
    map['added_at'] = Variable<int>(addedAt);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    return map;
  }

  FoldersCompanion toCompanion(bool nullToAbsent) {
    return FoldersCompanion(
      id: Value(id),
      path: Value(path),
      addedAt: Value(addedAt),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
    );
  }

  factory Folder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Folder(
      id: serializer.fromJson<int>(json['id']),
      path: serializer.fromJson<String>(json['path']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
      label: serializer.fromJson<String?>(json['label']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'path': serializer.toJson<String>(path),
      'addedAt': serializer.toJson<int>(addedAt),
      'label': serializer.toJson<String?>(label),
    };
  }

  Folder copyWith({
    int? id,
    String? path,
    int? addedAt,
    Value<String?> label = const Value.absent(),
  }) => Folder(
    id: id ?? this.id,
    path: path ?? this.path,
    addedAt: addedAt ?? this.addedAt,
    label: label.present ? label.value : this.label,
  );
  Folder copyWithCompanion(FoldersCompanion data) {
    return Folder(
      id: data.id.present ? data.id.value : this.id,
      path: data.path.present ? data.path.value : this.path,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      label: data.label.present ? data.label.value : this.label,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Folder(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('addedAt: $addedAt, ')
          ..write('label: $label')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, path, addedAt, label);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Folder &&
          other.id == this.id &&
          other.path == this.path &&
          other.addedAt == this.addedAt &&
          other.label == this.label);
}

class FoldersCompanion extends UpdateCompanion<Folder> {
  final Value<int> id;
  final Value<String> path;
  final Value<int> addedAt;
  final Value<String?> label;
  const FoldersCompanion({
    this.id = const Value.absent(),
    this.path = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.label = const Value.absent(),
  });
  FoldersCompanion.insert({
    this.id = const Value.absent(),
    required String path,
    required int addedAt,
    this.label = const Value.absent(),
  }) : path = Value(path),
       addedAt = Value(addedAt);
  static Insertable<Folder> custom({
    Expression<int>? id,
    Expression<String>? path,
    Expression<int>? addedAt,
    Expression<String>? label,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (path != null) 'path': path,
      if (addedAt != null) 'added_at': addedAt,
      if (label != null) 'label': label,
    });
  }

  FoldersCompanion copyWith({
    Value<int>? id,
    Value<String>? path,
    Value<int>? addedAt,
    Value<String?>? label,
  }) {
    return FoldersCompanion(
      id: id ?? this.id,
      path: path ?? this.path,
      addedAt: addedAt ?? this.addedAt,
      label: label ?? this.label,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(addedAt.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoldersCompanion(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('addedAt: $addedAt, ')
          ..write('label: $label')
          ..write(')'))
        .toString();
  }
}

class $PlaylistsTable extends Playlists
    with TableInfo<$PlaylistsTable, Playlist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverKeyMeta = const VerificationMeta(
    'coverKey',
  );
  @override
  late final GeneratedColumn<String> coverKey = GeneratedColumn<String>(
    'cover_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt, coverKey];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<Playlist> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('cover_key')) {
      context.handle(
        _coverKeyMeta,
        coverKey.isAcceptableOrUnknown(data['cover_key']!, _coverKeyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Playlist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Playlist(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      coverKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_key'],
      ),
    );
  }

  @override
  $PlaylistsTable createAlias(String alias) {
    return $PlaylistsTable(attachedDatabase, alias);
  }
}

class Playlist extends DataClass implements Insertable<Playlist> {
  final int id;
  final String name;
  final int createdAt;

  /// File name inside the covers folder; null = use the first track's cover.
  final String? coverKey;
  const Playlist({
    required this.id,
    required this.name,
    required this.createdAt,
    this.coverKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || coverKey != null) {
      map['cover_key'] = Variable<String>(coverKey);
    }
    return map;
  }

  PlaylistsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      coverKey: coverKey == null && nullToAbsent
          ? const Value.absent()
          : Value(coverKey),
    );
  }

  factory Playlist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Playlist(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      coverKey: serializer.fromJson<String?>(json['coverKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<int>(createdAt),
      'coverKey': serializer.toJson<String?>(coverKey),
    };
  }

  Playlist copyWith({
    int? id,
    String? name,
    int? createdAt,
    Value<String?> coverKey = const Value.absent(),
  }) => Playlist(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    coverKey: coverKey.present ? coverKey.value : this.coverKey,
  );
  Playlist copyWithCompanion(PlaylistsCompanion data) {
    return Playlist(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      coverKey: data.coverKey.present ? data.coverKey.value : this.coverKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Playlist(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('coverKey: $coverKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt, coverKey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Playlist &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.coverKey == this.coverKey);
}

class PlaylistsCompanion extends UpdateCompanion<Playlist> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> createdAt;
  final Value<String?> coverKey;
  const PlaylistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.coverKey = const Value.absent(),
  });
  PlaylistsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int createdAt,
    this.coverKey = const Value.absent(),
  }) : name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<Playlist> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? createdAt,
    Expression<String>? coverKey,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (coverKey != null) 'cover_key': coverKey,
    });
  }

  PlaylistsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? createdAt,
    Value<String?>? coverKey,
  }) {
    return PlaylistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      coverKey: coverKey ?? this.coverKey,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (coverKey.present) {
      map['cover_key'] = Variable<String>(coverKey.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('coverKey: $coverKey')
          ..write(')'))
        .toString();
  }
}

class $PlaylistTracksTable extends PlaylistTracks
    with TableInfo<$PlaylistTracksTable, PlaylistTrack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistTracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<int> playlistId = GeneratedColumn<int>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES playlists (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<int> trackId = GeneratedColumn<int>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [playlistId, trackId, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlist_tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaylistTrack> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playlistId, trackId};
  @override
  PlaylistTrack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistTrack(
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}playlist_id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $PlaylistTracksTable createAlias(String alias) {
    return $PlaylistTracksTable(attachedDatabase, alias);
  }
}

class PlaylistTrack extends DataClass implements Insertable<PlaylistTrack> {
  final int playlistId;
  final int trackId;
  final int position;
  const PlaylistTrack({
    required this.playlistId,
    required this.trackId,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['playlist_id'] = Variable<int>(playlistId);
    map['track_id'] = Variable<int>(trackId);
    map['position'] = Variable<int>(position);
    return map;
  }

  PlaylistTracksCompanion toCompanion(bool nullToAbsent) {
    return PlaylistTracksCompanion(
      playlistId: Value(playlistId),
      trackId: Value(trackId),
      position: Value(position),
    );
  }

  factory PlaylistTrack.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistTrack(
      playlistId: serializer.fromJson<int>(json['playlistId']),
      trackId: serializer.fromJson<int>(json['trackId']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playlistId': serializer.toJson<int>(playlistId),
      'trackId': serializer.toJson<int>(trackId),
      'position': serializer.toJson<int>(position),
    };
  }

  PlaylistTrack copyWith({int? playlistId, int? trackId, int? position}) =>
      PlaylistTrack(
        playlistId: playlistId ?? this.playlistId,
        trackId: trackId ?? this.trackId,
        position: position ?? this.position,
      );
  PlaylistTrack copyWithCompanion(PlaylistTracksCompanion data) {
    return PlaylistTrack(
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistTrack(')
          ..write('playlistId: $playlistId, ')
          ..write('trackId: $trackId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(playlistId, trackId, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistTrack &&
          other.playlistId == this.playlistId &&
          other.trackId == this.trackId &&
          other.position == this.position);
}

class PlaylistTracksCompanion extends UpdateCompanion<PlaylistTrack> {
  final Value<int> playlistId;
  final Value<int> trackId;
  final Value<int> position;
  final Value<int> rowid;
  const PlaylistTracksCompanion({
    this.playlistId = const Value.absent(),
    this.trackId = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistTracksCompanion.insert({
    required int playlistId,
    required int trackId,
    required int position,
    this.rowid = const Value.absent(),
  }) : playlistId = Value(playlistId),
       trackId = Value(trackId),
       position = Value(position);
  static Insertable<PlaylistTrack> custom({
    Expression<int>? playlistId,
    Expression<int>? trackId,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playlistId != null) 'playlist_id': playlistId,
      if (trackId != null) 'track_id': trackId,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistTracksCompanion copyWith({
    Value<int>? playlistId,
    Value<int>? trackId,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return PlaylistTracksCompanion(
      playlistId: playlistId ?? this.playlistId,
      trackId: trackId ?? this.trackId,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playlistId.present) {
      map['playlist_id'] = Variable<int>(playlistId.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<int>(trackId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistTracksCompanion(')
          ..write('playlistId: $playlistId, ')
          ..write('trackId: $trackId, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaylistImportsTable extends PlaylistImports
    with TableInfo<$PlaylistImportsTable, PlaylistImport> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistImportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<int> playlistId = GeneratedColumn<int>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES playlists (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sourceNameMeta = const VerificationMeta(
    'sourceName',
  );
  @override
  late final GeneratedColumn<String> sourceName = GeneratedColumn<String>(
    'source_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sourceKindMeta = const VerificationMeta(
    'sourceKind',
  );
  @override
  late final GeneratedColumn<String> sourceKind = GeneratedColumn<String>(
    'source_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('exportify'),
  );
  static const VerificationMeta _folderPathMeta = const VerificationMeta(
    'folderPath',
  );
  @override
  late final GeneratedColumn<String> folderPath = GeneratedColumn<String>(
    'folder_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _numberFilesMeta = const VerificationMeta(
    'numberFiles',
  );
  @override
  late final GeneratedColumn<bool> numberFiles = GeneratedColumn<bool>(
    'number_files',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("number_files" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _linkOnlyMeta = const VerificationMeta(
    'linkOnly',
  );
  @override
  late final GeneratedColumn<bool> linkOnly = GeneratedColumn<bool>(
    'link_only',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("link_only" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _planFirstMeta = const VerificationMeta(
    'planFirst',
  );
  @override
  late final GeneratedColumn<bool> planFirst = GeneratedColumn<bool>(
    'plan_first',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("plan_first" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _fetchCoversMeta = const VerificationMeta(
    'fetchCovers',
  );
  @override
  late final GeneratedColumn<bool> fetchCovers = GeneratedColumn<bool>(
    'fetch_covers',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("fetch_covers" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    playlistId,
    sourceName,
    createdAt,
    status,
    sourceKind,
    folderPath,
    numberFiles,
    linkOnly,
    planFirst,
    fetchCovers,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlist_imports';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaylistImport> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('source_name')) {
      context.handle(
        _sourceNameMeta,
        sourceName.isAcceptableOrUnknown(data['source_name']!, _sourceNameMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceNameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('source_kind')) {
      context.handle(
        _sourceKindMeta,
        sourceKind.isAcceptableOrUnknown(data['source_kind']!, _sourceKindMeta),
      );
    }
    if (data.containsKey('folder_path')) {
      context.handle(
        _folderPathMeta,
        folderPath.isAcceptableOrUnknown(data['folder_path']!, _folderPathMeta),
      );
    }
    if (data.containsKey('number_files')) {
      context.handle(
        _numberFilesMeta,
        numberFiles.isAcceptableOrUnknown(
          data['number_files']!,
          _numberFilesMeta,
        ),
      );
    }
    if (data.containsKey('link_only')) {
      context.handle(
        _linkOnlyMeta,
        linkOnly.isAcceptableOrUnknown(data['link_only']!, _linkOnlyMeta),
      );
    }
    if (data.containsKey('plan_first')) {
      context.handle(
        _planFirstMeta,
        planFirst.isAcceptableOrUnknown(data['plan_first']!, _planFirstMeta),
      );
    }
    if (data.containsKey('fetch_covers')) {
      context.handle(
        _fetchCoversMeta,
        fetchCovers.isAcceptableOrUnknown(
          data['fetch_covers']!,
          _fetchCoversMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaylistImport map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistImport(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}playlist_id'],
      )!,
      sourceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      sourceKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_kind'],
      )!,
      folderPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_path'],
      ),
      numberFiles: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}number_files'],
      )!,
      linkOnly: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}link_only'],
      )!,
      planFirst: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}plan_first'],
      )!,
      fetchCovers: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}fetch_covers'],
      )!,
    );
  }

  @override
  $PlaylistImportsTable createAlias(String alias) {
    return $PlaylistImportsTable(attachedDatabase, alias);
  }
}

class PlaylistImport extends DataClass implements Insertable<PlaylistImport> {
  final int id;
  final int playlistId;
  final String sourceName;
  final int createdAt;

  /// 0 running · 1 paused · 2 finished · 3 cancelled.
  final int status;

  /// Where the rows came from: `exportify` · `tunemymusic` · `soundiiz` ·
  /// `lastfm` · `csv` · `m3u` · `xspf`.
  final String sourceKind;

  /// Sub-folder of the download folder for this import (null = none).
  final String? folderPath;

  /// Prefix downloaded files with their position (`007 - Artist - Title`).
  final bool numberFiles;

  /// Link what the library has and download nothing.
  final bool linkOnly;

  /// Search everything first and wait for the user before downloading.
  final bool planFirst;

  /// Look the album cover up after each download.
  final bool fetchCovers;
  const PlaylistImport({
    required this.id,
    required this.playlistId,
    required this.sourceName,
    required this.createdAt,
    required this.status,
    required this.sourceKind,
    this.folderPath,
    required this.numberFiles,
    required this.linkOnly,
    required this.planFirst,
    required this.fetchCovers,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['playlist_id'] = Variable<int>(playlistId);
    map['source_name'] = Variable<String>(sourceName);
    map['created_at'] = Variable<int>(createdAt);
    map['status'] = Variable<int>(status);
    map['source_kind'] = Variable<String>(sourceKind);
    if (!nullToAbsent || folderPath != null) {
      map['folder_path'] = Variable<String>(folderPath);
    }
    map['number_files'] = Variable<bool>(numberFiles);
    map['link_only'] = Variable<bool>(linkOnly);
    map['plan_first'] = Variable<bool>(planFirst);
    map['fetch_covers'] = Variable<bool>(fetchCovers);
    return map;
  }

  PlaylistImportsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistImportsCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      sourceName: Value(sourceName),
      createdAt: Value(createdAt),
      status: Value(status),
      sourceKind: Value(sourceKind),
      folderPath: folderPath == null && nullToAbsent
          ? const Value.absent()
          : Value(folderPath),
      numberFiles: Value(numberFiles),
      linkOnly: Value(linkOnly),
      planFirst: Value(planFirst),
      fetchCovers: Value(fetchCovers),
    );
  }

  factory PlaylistImport.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistImport(
      id: serializer.fromJson<int>(json['id']),
      playlistId: serializer.fromJson<int>(json['playlistId']),
      sourceName: serializer.fromJson<String>(json['sourceName']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      status: serializer.fromJson<int>(json['status']),
      sourceKind: serializer.fromJson<String>(json['sourceKind']),
      folderPath: serializer.fromJson<String?>(json['folderPath']),
      numberFiles: serializer.fromJson<bool>(json['numberFiles']),
      linkOnly: serializer.fromJson<bool>(json['linkOnly']),
      planFirst: serializer.fromJson<bool>(json['planFirst']),
      fetchCovers: serializer.fromJson<bool>(json['fetchCovers']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playlistId': serializer.toJson<int>(playlistId),
      'sourceName': serializer.toJson<String>(sourceName),
      'createdAt': serializer.toJson<int>(createdAt),
      'status': serializer.toJson<int>(status),
      'sourceKind': serializer.toJson<String>(sourceKind),
      'folderPath': serializer.toJson<String?>(folderPath),
      'numberFiles': serializer.toJson<bool>(numberFiles),
      'linkOnly': serializer.toJson<bool>(linkOnly),
      'planFirst': serializer.toJson<bool>(planFirst),
      'fetchCovers': serializer.toJson<bool>(fetchCovers),
    };
  }

  PlaylistImport copyWith({
    int? id,
    int? playlistId,
    String? sourceName,
    int? createdAt,
    int? status,
    String? sourceKind,
    Value<String?> folderPath = const Value.absent(),
    bool? numberFiles,
    bool? linkOnly,
    bool? planFirst,
    bool? fetchCovers,
  }) => PlaylistImport(
    id: id ?? this.id,
    playlistId: playlistId ?? this.playlistId,
    sourceName: sourceName ?? this.sourceName,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
    sourceKind: sourceKind ?? this.sourceKind,
    folderPath: folderPath.present ? folderPath.value : this.folderPath,
    numberFiles: numberFiles ?? this.numberFiles,
    linkOnly: linkOnly ?? this.linkOnly,
    planFirst: planFirst ?? this.planFirst,
    fetchCovers: fetchCovers ?? this.fetchCovers,
  );
  PlaylistImport copyWithCompanion(PlaylistImportsCompanion data) {
    return PlaylistImport(
      id: data.id.present ? data.id.value : this.id,
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      sourceName: data.sourceName.present
          ? data.sourceName.value
          : this.sourceName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      status: data.status.present ? data.status.value : this.status,
      sourceKind: data.sourceKind.present
          ? data.sourceKind.value
          : this.sourceKind,
      folderPath: data.folderPath.present
          ? data.folderPath.value
          : this.folderPath,
      numberFiles: data.numberFiles.present
          ? data.numberFiles.value
          : this.numberFiles,
      linkOnly: data.linkOnly.present ? data.linkOnly.value : this.linkOnly,
      planFirst: data.planFirst.present ? data.planFirst.value : this.planFirst,
      fetchCovers: data.fetchCovers.present
          ? data.fetchCovers.value
          : this.fetchCovers,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistImport(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('sourceName: $sourceName, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('sourceKind: $sourceKind, ')
          ..write('folderPath: $folderPath, ')
          ..write('numberFiles: $numberFiles, ')
          ..write('linkOnly: $linkOnly, ')
          ..write('planFirst: $planFirst, ')
          ..write('fetchCovers: $fetchCovers')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    playlistId,
    sourceName,
    createdAt,
    status,
    sourceKind,
    folderPath,
    numberFiles,
    linkOnly,
    planFirst,
    fetchCovers,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistImport &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.sourceName == this.sourceName &&
          other.createdAt == this.createdAt &&
          other.status == this.status &&
          other.sourceKind == this.sourceKind &&
          other.folderPath == this.folderPath &&
          other.numberFiles == this.numberFiles &&
          other.linkOnly == this.linkOnly &&
          other.planFirst == this.planFirst &&
          other.fetchCovers == this.fetchCovers);
}

class PlaylistImportsCompanion extends UpdateCompanion<PlaylistImport> {
  final Value<int> id;
  final Value<int> playlistId;
  final Value<String> sourceName;
  final Value<int> createdAt;
  final Value<int> status;
  final Value<String> sourceKind;
  final Value<String?> folderPath;
  final Value<bool> numberFiles;
  final Value<bool> linkOnly;
  final Value<bool> planFirst;
  final Value<bool> fetchCovers;
  const PlaylistImportsCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.sourceName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
    this.sourceKind = const Value.absent(),
    this.folderPath = const Value.absent(),
    this.numberFiles = const Value.absent(),
    this.linkOnly = const Value.absent(),
    this.planFirst = const Value.absent(),
    this.fetchCovers = const Value.absent(),
  });
  PlaylistImportsCompanion.insert({
    this.id = const Value.absent(),
    required int playlistId,
    required String sourceName,
    required int createdAt,
    this.status = const Value.absent(),
    this.sourceKind = const Value.absent(),
    this.folderPath = const Value.absent(),
    this.numberFiles = const Value.absent(),
    this.linkOnly = const Value.absent(),
    this.planFirst = const Value.absent(),
    this.fetchCovers = const Value.absent(),
  }) : playlistId = Value(playlistId),
       sourceName = Value(sourceName),
       createdAt = Value(createdAt);
  static Insertable<PlaylistImport> custom({
    Expression<int>? id,
    Expression<int>? playlistId,
    Expression<String>? sourceName,
    Expression<int>? createdAt,
    Expression<int>? status,
    Expression<String>? sourceKind,
    Expression<String>? folderPath,
    Expression<bool>? numberFiles,
    Expression<bool>? linkOnly,
    Expression<bool>? planFirst,
    Expression<bool>? fetchCovers,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (sourceName != null) 'source_name': sourceName,
      if (createdAt != null) 'created_at': createdAt,
      if (status != null) 'status': status,
      if (sourceKind != null) 'source_kind': sourceKind,
      if (folderPath != null) 'folder_path': folderPath,
      if (numberFiles != null) 'number_files': numberFiles,
      if (linkOnly != null) 'link_only': linkOnly,
      if (planFirst != null) 'plan_first': planFirst,
      if (fetchCovers != null) 'fetch_covers': fetchCovers,
    });
  }

  PlaylistImportsCompanion copyWith({
    Value<int>? id,
    Value<int>? playlistId,
    Value<String>? sourceName,
    Value<int>? createdAt,
    Value<int>? status,
    Value<String>? sourceKind,
    Value<String?>? folderPath,
    Value<bool>? numberFiles,
    Value<bool>? linkOnly,
    Value<bool>? planFirst,
    Value<bool>? fetchCovers,
  }) {
    return PlaylistImportsCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      sourceName: sourceName ?? this.sourceName,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      sourceKind: sourceKind ?? this.sourceKind,
      folderPath: folderPath ?? this.folderPath,
      numberFiles: numberFiles ?? this.numberFiles,
      linkOnly: linkOnly ?? this.linkOnly,
      planFirst: planFirst ?? this.planFirst,
      fetchCovers: fetchCovers ?? this.fetchCovers,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<int>(playlistId.value);
    }
    if (sourceName.present) {
      map['source_name'] = Variable<String>(sourceName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (sourceKind.present) {
      map['source_kind'] = Variable<String>(sourceKind.value);
    }
    if (folderPath.present) {
      map['folder_path'] = Variable<String>(folderPath.value);
    }
    if (numberFiles.present) {
      map['number_files'] = Variable<bool>(numberFiles.value);
    }
    if (linkOnly.present) {
      map['link_only'] = Variable<bool>(linkOnly.value);
    }
    if (planFirst.present) {
      map['plan_first'] = Variable<bool>(planFirst.value);
    }
    if (fetchCovers.present) {
      map['fetch_covers'] = Variable<bool>(fetchCovers.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistImportsCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('sourceName: $sourceName, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('sourceKind: $sourceKind, ')
          ..write('folderPath: $folderPath, ')
          ..write('numberFiles: $numberFiles, ')
          ..write('linkOnly: $linkOnly, ')
          ..write('planFirst: $planFirst, ')
          ..write('fetchCovers: $fetchCovers')
          ..write(')'))
        .toString();
  }
}

class $PlaylistImportItemsTable extends PlaylistImportItems
    with TableInfo<$PlaylistImportItemsTable, PlaylistImportItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistImportItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _importIdMeta = const VerificationMeta(
    'importId',
  );
  @override
  late final GeneratedColumn<int> importId = GeneratedColumn<int>(
    'import_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES playlist_imports (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _rowIndexMeta = const VerificationMeta(
    'rowIndex',
  );
  @override
  late final GeneratedColumn<int> rowIndex = GeneratedColumn<int>(
    'row_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistsMeta = const VerificationMeta(
    'artists',
  );
  @override
  late final GeneratedColumn<String> artists = GeneratedColumn<String>(
    'artists',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<String> album = GeneratedColumn<String>(
    'album',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isrcMeta = const VerificationMeta('isrc');
  @override
  late final GeneratedColumn<String> isrc = GeneratedColumn<String>(
    'isrc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _candidatesMeta = const VerificationMeta(
    'candidates',
  );
  @override
  late final GeneratedColumn<String> candidates = GeneratedColumn<String>(
    'candidates',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<int> trackId = GeneratedColumn<int>(
    'track_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
    'score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    importId,
    rowIndex,
    title,
    artists,
    album,
    durationMs,
    isrc,
    status,
    videoId,
    candidates,
    trackId,
    score,
    note,
    location,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlist_import_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaylistImportItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('import_id')) {
      context.handle(
        _importIdMeta,
        importId.isAcceptableOrUnknown(data['import_id']!, _importIdMeta),
      );
    } else if (isInserting) {
      context.missing(_importIdMeta);
    }
    if (data.containsKey('row_index')) {
      context.handle(
        _rowIndexMeta,
        rowIndex.isAcceptableOrUnknown(data['row_index']!, _rowIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_rowIndexMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artists')) {
      context.handle(
        _artistsMeta,
        artists.isAcceptableOrUnknown(data['artists']!, _artistsMeta),
      );
    } else if (isInserting) {
      context.missing(_artistsMeta);
    }
    if (data.containsKey('album')) {
      context.handle(
        _albumMeta,
        album.isAcceptableOrUnknown(data['album']!, _albumMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('isrc')) {
      context.handle(
        _isrcMeta,
        isrc.isAcceptableOrUnknown(data['isrc']!, _isrcMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    }
    if (data.containsKey('candidates')) {
      context.handle(
        _candidatesMeta,
        candidates.isAcceptableOrUnknown(data['candidates']!, _candidatesMeta),
      );
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {importId, rowIndex};
  @override
  PlaylistImportItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistImportItem(
      importId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}import_id'],
      )!,
      rowIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_index'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      artists: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artists'],
      )!,
      album: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      isrc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}isrc'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_id'],
      ),
      candidates: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}candidates'],
      ),
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      ),
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
    );
  }

  @override
  $PlaylistImportItemsTable createAlias(String alias) {
    return $PlaylistImportItemsTable(attachedDatabase, alias);
  }
}

class PlaylistImportItem extends DataClass
    implements Insertable<PlaylistImportItem> {
  final int importId;
  final int rowIndex;
  final String title;

  /// Artists joined with `;` (the CSV separator, so never inside a name).
  final String artists;
  final String? album;
  final int? durationMs;
  final String? isrc;

  /// 0 to search · 1 queued · 2 downloaded · 3 linked (already in library)
  /// · 4 to review · 5 not found · 6 failed · 7 skipped by the user
  /// · 8 planned (chosen, waiting for «Download») · 9 removed from the source.
  final int status;
  final String? videoId;

  /// JSON list of the best candidates, kept while status is 4 (to review).
  final String? candidates;
  final int? trackId;
  final double? score;

  /// Why a row is «not found» or «to review» (shown and exported).
  final String? note;

  /// Path or URL of a local M3U/XSPF entry.
  final String? location;
  const PlaylistImportItem({
    required this.importId,
    required this.rowIndex,
    required this.title,
    required this.artists,
    this.album,
    this.durationMs,
    this.isrc,
    required this.status,
    this.videoId,
    this.candidates,
    this.trackId,
    this.score,
    this.note,
    this.location,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['import_id'] = Variable<int>(importId);
    map['row_index'] = Variable<int>(rowIndex);
    map['title'] = Variable<String>(title);
    map['artists'] = Variable<String>(artists);
    if (!nullToAbsent || album != null) {
      map['album'] = Variable<String>(album);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    if (!nullToAbsent || isrc != null) {
      map['isrc'] = Variable<String>(isrc);
    }
    map['status'] = Variable<int>(status);
    if (!nullToAbsent || videoId != null) {
      map['video_id'] = Variable<String>(videoId);
    }
    if (!nullToAbsent || candidates != null) {
      map['candidates'] = Variable<String>(candidates);
    }
    if (!nullToAbsent || trackId != null) {
      map['track_id'] = Variable<int>(trackId);
    }
    if (!nullToAbsent || score != null) {
      map['score'] = Variable<double>(score);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    return map;
  }

  PlaylistImportItemsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistImportItemsCompanion(
      importId: Value(importId),
      rowIndex: Value(rowIndex),
      title: Value(title),
      artists: Value(artists),
      album: album == null && nullToAbsent
          ? const Value.absent()
          : Value(album),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      isrc: isrc == null && nullToAbsent ? const Value.absent() : Value(isrc),
      status: Value(status),
      videoId: videoId == null && nullToAbsent
          ? const Value.absent()
          : Value(videoId),
      candidates: candidates == null && nullToAbsent
          ? const Value.absent()
          : Value(candidates),
      trackId: trackId == null && nullToAbsent
          ? const Value.absent()
          : Value(trackId),
      score: score == null && nullToAbsent
          ? const Value.absent()
          : Value(score),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
    );
  }

  factory PlaylistImportItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistImportItem(
      importId: serializer.fromJson<int>(json['importId']),
      rowIndex: serializer.fromJson<int>(json['rowIndex']),
      title: serializer.fromJson<String>(json['title']),
      artists: serializer.fromJson<String>(json['artists']),
      album: serializer.fromJson<String?>(json['album']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      isrc: serializer.fromJson<String?>(json['isrc']),
      status: serializer.fromJson<int>(json['status']),
      videoId: serializer.fromJson<String?>(json['videoId']),
      candidates: serializer.fromJson<String?>(json['candidates']),
      trackId: serializer.fromJson<int?>(json['trackId']),
      score: serializer.fromJson<double?>(json['score']),
      note: serializer.fromJson<String?>(json['note']),
      location: serializer.fromJson<String?>(json['location']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'importId': serializer.toJson<int>(importId),
      'rowIndex': serializer.toJson<int>(rowIndex),
      'title': serializer.toJson<String>(title),
      'artists': serializer.toJson<String>(artists),
      'album': serializer.toJson<String?>(album),
      'durationMs': serializer.toJson<int?>(durationMs),
      'isrc': serializer.toJson<String?>(isrc),
      'status': serializer.toJson<int>(status),
      'videoId': serializer.toJson<String?>(videoId),
      'candidates': serializer.toJson<String?>(candidates),
      'trackId': serializer.toJson<int?>(trackId),
      'score': serializer.toJson<double?>(score),
      'note': serializer.toJson<String?>(note),
      'location': serializer.toJson<String?>(location),
    };
  }

  PlaylistImportItem copyWith({
    int? importId,
    int? rowIndex,
    String? title,
    String? artists,
    Value<String?> album = const Value.absent(),
    Value<int?> durationMs = const Value.absent(),
    Value<String?> isrc = const Value.absent(),
    int? status,
    Value<String?> videoId = const Value.absent(),
    Value<String?> candidates = const Value.absent(),
    Value<int?> trackId = const Value.absent(),
    Value<double?> score = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<String?> location = const Value.absent(),
  }) => PlaylistImportItem(
    importId: importId ?? this.importId,
    rowIndex: rowIndex ?? this.rowIndex,
    title: title ?? this.title,
    artists: artists ?? this.artists,
    album: album.present ? album.value : this.album,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    isrc: isrc.present ? isrc.value : this.isrc,
    status: status ?? this.status,
    videoId: videoId.present ? videoId.value : this.videoId,
    candidates: candidates.present ? candidates.value : this.candidates,
    trackId: trackId.present ? trackId.value : this.trackId,
    score: score.present ? score.value : this.score,
    note: note.present ? note.value : this.note,
    location: location.present ? location.value : this.location,
  );
  PlaylistImportItem copyWithCompanion(PlaylistImportItemsCompanion data) {
    return PlaylistImportItem(
      importId: data.importId.present ? data.importId.value : this.importId,
      rowIndex: data.rowIndex.present ? data.rowIndex.value : this.rowIndex,
      title: data.title.present ? data.title.value : this.title,
      artists: data.artists.present ? data.artists.value : this.artists,
      album: data.album.present ? data.album.value : this.album,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      isrc: data.isrc.present ? data.isrc.value : this.isrc,
      status: data.status.present ? data.status.value : this.status,
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      candidates: data.candidates.present
          ? data.candidates.value
          : this.candidates,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      score: data.score.present ? data.score.value : this.score,
      note: data.note.present ? data.note.value : this.note,
      location: data.location.present ? data.location.value : this.location,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistImportItem(')
          ..write('importId: $importId, ')
          ..write('rowIndex: $rowIndex, ')
          ..write('title: $title, ')
          ..write('artists: $artists, ')
          ..write('album: $album, ')
          ..write('durationMs: $durationMs, ')
          ..write('isrc: $isrc, ')
          ..write('status: $status, ')
          ..write('videoId: $videoId, ')
          ..write('candidates: $candidates, ')
          ..write('trackId: $trackId, ')
          ..write('score: $score, ')
          ..write('note: $note, ')
          ..write('location: $location')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    importId,
    rowIndex,
    title,
    artists,
    album,
    durationMs,
    isrc,
    status,
    videoId,
    candidates,
    trackId,
    score,
    note,
    location,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistImportItem &&
          other.importId == this.importId &&
          other.rowIndex == this.rowIndex &&
          other.title == this.title &&
          other.artists == this.artists &&
          other.album == this.album &&
          other.durationMs == this.durationMs &&
          other.isrc == this.isrc &&
          other.status == this.status &&
          other.videoId == this.videoId &&
          other.candidates == this.candidates &&
          other.trackId == this.trackId &&
          other.score == this.score &&
          other.note == this.note &&
          other.location == this.location);
}

class PlaylistImportItemsCompanion extends UpdateCompanion<PlaylistImportItem> {
  final Value<int> importId;
  final Value<int> rowIndex;
  final Value<String> title;
  final Value<String> artists;
  final Value<String?> album;
  final Value<int?> durationMs;
  final Value<String?> isrc;
  final Value<int> status;
  final Value<String?> videoId;
  final Value<String?> candidates;
  final Value<int?> trackId;
  final Value<double?> score;
  final Value<String?> note;
  final Value<String?> location;
  final Value<int> rowid;
  const PlaylistImportItemsCompanion({
    this.importId = const Value.absent(),
    this.rowIndex = const Value.absent(),
    this.title = const Value.absent(),
    this.artists = const Value.absent(),
    this.album = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.isrc = const Value.absent(),
    this.status = const Value.absent(),
    this.videoId = const Value.absent(),
    this.candidates = const Value.absent(),
    this.trackId = const Value.absent(),
    this.score = const Value.absent(),
    this.note = const Value.absent(),
    this.location = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistImportItemsCompanion.insert({
    required int importId,
    required int rowIndex,
    required String title,
    required String artists,
    this.album = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.isrc = const Value.absent(),
    this.status = const Value.absent(),
    this.videoId = const Value.absent(),
    this.candidates = const Value.absent(),
    this.trackId = const Value.absent(),
    this.score = const Value.absent(),
    this.note = const Value.absent(),
    this.location = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : importId = Value(importId),
       rowIndex = Value(rowIndex),
       title = Value(title),
       artists = Value(artists);
  static Insertable<PlaylistImportItem> custom({
    Expression<int>? importId,
    Expression<int>? rowIndex,
    Expression<String>? title,
    Expression<String>? artists,
    Expression<String>? album,
    Expression<int>? durationMs,
    Expression<String>? isrc,
    Expression<int>? status,
    Expression<String>? videoId,
    Expression<String>? candidates,
    Expression<int>? trackId,
    Expression<double>? score,
    Expression<String>? note,
    Expression<String>? location,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (importId != null) 'import_id': importId,
      if (rowIndex != null) 'row_index': rowIndex,
      if (title != null) 'title': title,
      if (artists != null) 'artists': artists,
      if (album != null) 'album': album,
      if (durationMs != null) 'duration_ms': durationMs,
      if (isrc != null) 'isrc': isrc,
      if (status != null) 'status': status,
      if (videoId != null) 'video_id': videoId,
      if (candidates != null) 'candidates': candidates,
      if (trackId != null) 'track_id': trackId,
      if (score != null) 'score': score,
      if (note != null) 'note': note,
      if (location != null) 'location': location,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistImportItemsCompanion copyWith({
    Value<int>? importId,
    Value<int>? rowIndex,
    Value<String>? title,
    Value<String>? artists,
    Value<String?>? album,
    Value<int?>? durationMs,
    Value<String?>? isrc,
    Value<int>? status,
    Value<String?>? videoId,
    Value<String?>? candidates,
    Value<int?>? trackId,
    Value<double?>? score,
    Value<String?>? note,
    Value<String?>? location,
    Value<int>? rowid,
  }) {
    return PlaylistImportItemsCompanion(
      importId: importId ?? this.importId,
      rowIndex: rowIndex ?? this.rowIndex,
      title: title ?? this.title,
      artists: artists ?? this.artists,
      album: album ?? this.album,
      durationMs: durationMs ?? this.durationMs,
      isrc: isrc ?? this.isrc,
      status: status ?? this.status,
      videoId: videoId ?? this.videoId,
      candidates: candidates ?? this.candidates,
      trackId: trackId ?? this.trackId,
      score: score ?? this.score,
      note: note ?? this.note,
      location: location ?? this.location,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (importId.present) {
      map['import_id'] = Variable<int>(importId.value);
    }
    if (rowIndex.present) {
      map['row_index'] = Variable<int>(rowIndex.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artists.present) {
      map['artists'] = Variable<String>(artists.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (isrc.present) {
      map['isrc'] = Variable<String>(isrc.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (candidates.present) {
      map['candidates'] = Variable<String>(candidates.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<int>(trackId.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistImportItemsCompanion(')
          ..write('importId: $importId, ')
          ..write('rowIndex: $rowIndex, ')
          ..write('title: $title, ')
          ..write('artists: $artists, ')
          ..write('album: $album, ')
          ..write('durationMs: $durationMs, ')
          ..write('isrc: $isrc, ')
          ..write('status: $status, ')
          ..write('videoId: $videoId, ')
          ..write('candidates: $candidates, ')
          ..write('trackId: $trackId, ')
          ..write('score: $score, ')
          ..write('note: $note, ')
          ..write('location: $location, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaysTable extends Plays with TableInfo<$PlaysTable, Play> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<int> trackId = GeneratedColumn<int>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _playedAtMeta = const VerificationMeta(
    'playedAt',
  );
  @override
  late final GeneratedColumn<int> playedAt = GeneratedColumn<int>(
    'played_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _msPlayedMeta = const VerificationMeta(
    'msPlayed',
  );
  @override
  late final GeneratedColumn<int> msPlayed = GeneratedColumn<int>(
    'ms_played',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _contextMeta = const VerificationMeta(
    'context',
  );
  @override
  late final GeneratedColumn<int> context = GeneratedColumn<int>(
    'context',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contextNameMeta = const VerificationMeta(
    'contextName',
  );
  @override
  late final GeneratedColumn<String> contextName = GeneratedColumn<String>(
    'context_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trackId,
    playedAt,
    msPlayed,
    context,
    contextName,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plays';
  @override
  VerificationContext validateIntegrity(
    Insertable<Play> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('played_at')) {
      context.handle(
        _playedAtMeta,
        playedAt.isAcceptableOrUnknown(data['played_at']!, _playedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_playedAtMeta);
    }
    if (data.containsKey('ms_played')) {
      context.handle(
        _msPlayedMeta,
        msPlayed.isAcceptableOrUnknown(data['ms_played']!, _msPlayedMeta),
      );
    }
    if (data.containsKey('context')) {
      context.handle(
        _contextMeta,
        this.context.isAcceptableOrUnknown(data['context']!, _contextMeta),
      );
    }
    if (data.containsKey('context_name')) {
      context.handle(
        _contextNameMeta,
        contextName.isAcceptableOrUnknown(
          data['context_name']!,
          _contextNameMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Play map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Play(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
      playedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}played_at'],
      )!,
      msPlayed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ms_played'],
      )!,
      context: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}context'],
      ),
      contextName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_name'],
      ),
    );
  }

  @override
  $PlaysTable createAlias(String alias) {
    return $PlaysTable(attachedDatabase, alias);
  }
}

class Play extends DataClass implements Insertable<Play> {
  final int id;
  final int trackId;

  /// Epoch ms of the moment it counted as played.
  final int playedAt;

  /// Time really spent playing it (seeks do not count); grows until the
  /// track changes.
  final int msPlayed;

  /// `PlayContextKind.index` of where it was started from, if known.
  final int? context;
  final String? contextName;
  const Play({
    required this.id,
    required this.trackId,
    required this.playedAt,
    required this.msPlayed,
    this.context,
    this.contextName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['track_id'] = Variable<int>(trackId);
    map['played_at'] = Variable<int>(playedAt);
    map['ms_played'] = Variable<int>(msPlayed);
    if (!nullToAbsent || context != null) {
      map['context'] = Variable<int>(context);
    }
    if (!nullToAbsent || contextName != null) {
      map['context_name'] = Variable<String>(contextName);
    }
    return map;
  }

  PlaysCompanion toCompanion(bool nullToAbsent) {
    return PlaysCompanion(
      id: Value(id),
      trackId: Value(trackId),
      playedAt: Value(playedAt),
      msPlayed: Value(msPlayed),
      context: context == null && nullToAbsent
          ? const Value.absent()
          : Value(context),
      contextName: contextName == null && nullToAbsent
          ? const Value.absent()
          : Value(contextName),
    );
  }

  factory Play.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Play(
      id: serializer.fromJson<int>(json['id']),
      trackId: serializer.fromJson<int>(json['trackId']),
      playedAt: serializer.fromJson<int>(json['playedAt']),
      msPlayed: serializer.fromJson<int>(json['msPlayed']),
      context: serializer.fromJson<int?>(json['context']),
      contextName: serializer.fromJson<String?>(json['contextName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trackId': serializer.toJson<int>(trackId),
      'playedAt': serializer.toJson<int>(playedAt),
      'msPlayed': serializer.toJson<int>(msPlayed),
      'context': serializer.toJson<int?>(context),
      'contextName': serializer.toJson<String?>(contextName),
    };
  }

  Play copyWith({
    int? id,
    int? trackId,
    int? playedAt,
    int? msPlayed,
    Value<int?> context = const Value.absent(),
    Value<String?> contextName = const Value.absent(),
  }) => Play(
    id: id ?? this.id,
    trackId: trackId ?? this.trackId,
    playedAt: playedAt ?? this.playedAt,
    msPlayed: msPlayed ?? this.msPlayed,
    context: context.present ? context.value : this.context,
    contextName: contextName.present ? contextName.value : this.contextName,
  );
  Play copyWithCompanion(PlaysCompanion data) {
    return Play(
      id: data.id.present ? data.id.value : this.id,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      playedAt: data.playedAt.present ? data.playedAt.value : this.playedAt,
      msPlayed: data.msPlayed.present ? data.msPlayed.value : this.msPlayed,
      context: data.context.present ? data.context.value : this.context,
      contextName: data.contextName.present
          ? data.contextName.value
          : this.contextName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Play(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('playedAt: $playedAt, ')
          ..write('msPlayed: $msPlayed, ')
          ..write('context: $context, ')
          ..write('contextName: $contextName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, trackId, playedAt, msPlayed, context, contextName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Play &&
          other.id == this.id &&
          other.trackId == this.trackId &&
          other.playedAt == this.playedAt &&
          other.msPlayed == this.msPlayed &&
          other.context == this.context &&
          other.contextName == this.contextName);
}

class PlaysCompanion extends UpdateCompanion<Play> {
  final Value<int> id;
  final Value<int> trackId;
  final Value<int> playedAt;
  final Value<int> msPlayed;
  final Value<int?> context;
  final Value<String?> contextName;
  const PlaysCompanion({
    this.id = const Value.absent(),
    this.trackId = const Value.absent(),
    this.playedAt = const Value.absent(),
    this.msPlayed = const Value.absent(),
    this.context = const Value.absent(),
    this.contextName = const Value.absent(),
  });
  PlaysCompanion.insert({
    this.id = const Value.absent(),
    required int trackId,
    required int playedAt,
    this.msPlayed = const Value.absent(),
    this.context = const Value.absent(),
    this.contextName = const Value.absent(),
  }) : trackId = Value(trackId),
       playedAt = Value(playedAt);
  static Insertable<Play> custom({
    Expression<int>? id,
    Expression<int>? trackId,
    Expression<int>? playedAt,
    Expression<int>? msPlayed,
    Expression<int>? context,
    Expression<String>? contextName,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trackId != null) 'track_id': trackId,
      if (playedAt != null) 'played_at': playedAt,
      if (msPlayed != null) 'ms_played': msPlayed,
      if (context != null) 'context': context,
      if (contextName != null) 'context_name': contextName,
    });
  }

  PlaysCompanion copyWith({
    Value<int>? id,
    Value<int>? trackId,
    Value<int>? playedAt,
    Value<int>? msPlayed,
    Value<int?>? context,
    Value<String?>? contextName,
  }) {
    return PlaysCompanion(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      playedAt: playedAt ?? this.playedAt,
      msPlayed: msPlayed ?? this.msPlayed,
      context: context ?? this.context,
      contextName: contextName ?? this.contextName,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<int>(trackId.value);
    }
    if (playedAt.present) {
      map['played_at'] = Variable<int>(playedAt.value);
    }
    if (msPlayed.present) {
      map['ms_played'] = Variable<int>(msPlayed.value);
    }
    if (context.present) {
      map['context'] = Variable<int>(context.value);
    }
    if (contextName.present) {
      map['context_name'] = Variable<String>(contextName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaysCompanion(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('playedAt: $playedAt, ')
          ..write('msPlayed: $msPlayed, ')
          ..write('context: $context, ')
          ..write('contextName: $contextName')
          ..write(')'))
        .toString();
  }
}

class $SmartPlaylistsTable extends SmartPlaylists
    with TableInfo<$SmartPlaylistsTable, SmartPlaylist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SmartPlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rulesMeta = const VerificationMeta('rules');
  @override
  late final GeneratedColumn<String> rules = GeneratedColumn<String>(
    'rules',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortMeta = const VerificationMeta('sort');
  @override
  late final GeneratedColumn<String> sort = GeneratedColumn<String>(
    'sort',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _limitCountMeta = const VerificationMeta(
    'limitCount',
  );
  @override
  late final GeneratedColumn<int> limitCount = GeneratedColumn<int>(
    'limit_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    rules,
    sort,
    limitCount,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'smart_playlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<SmartPlaylist> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('rules')) {
      context.handle(
        _rulesMeta,
        rules.isAcceptableOrUnknown(data['rules']!, _rulesMeta),
      );
    } else if (isInserting) {
      context.missing(_rulesMeta);
    }
    if (data.containsKey('sort')) {
      context.handle(
        _sortMeta,
        sort.isAcceptableOrUnknown(data['sort']!, _sortMeta),
      );
    }
    if (data.containsKey('limit_count')) {
      context.handle(
        _limitCountMeta,
        limitCount.isAcceptableOrUnknown(data['limit_count']!, _limitCountMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SmartPlaylist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SmartPlaylist(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      rules: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rules'],
      )!,
      sort: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sort'],
      ),
      limitCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}limit_count'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SmartPlaylistsTable createAlias(String alias) {
    return $SmartPlaylistsTable(attachedDatabase, alias);
  }
}

class SmartPlaylist extends DataClass implements Insertable<SmartPlaylist> {
  final int id;
  final String name;
  final String rules;

  /// `SortOption` name, or `random`; null = the default order.
  final String? sort;
  final int? limitCount;
  final int createdAt;
  const SmartPlaylist({
    required this.id,
    required this.name,
    required this.rules,
    this.sort,
    this.limitCount,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['rules'] = Variable<String>(rules);
    if (!nullToAbsent || sort != null) {
      map['sort'] = Variable<String>(sort);
    }
    if (!nullToAbsent || limitCount != null) {
      map['limit_count'] = Variable<int>(limitCount);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  SmartPlaylistsCompanion toCompanion(bool nullToAbsent) {
    return SmartPlaylistsCompanion(
      id: Value(id),
      name: Value(name),
      rules: Value(rules),
      sort: sort == null && nullToAbsent ? const Value.absent() : Value(sort),
      limitCount: limitCount == null && nullToAbsent
          ? const Value.absent()
          : Value(limitCount),
      createdAt: Value(createdAt),
    );
  }

  factory SmartPlaylist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SmartPlaylist(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      rules: serializer.fromJson<String>(json['rules']),
      sort: serializer.fromJson<String?>(json['sort']),
      limitCount: serializer.fromJson<int?>(json['limitCount']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'rules': serializer.toJson<String>(rules),
      'sort': serializer.toJson<String?>(sort),
      'limitCount': serializer.toJson<int?>(limitCount),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  SmartPlaylist copyWith({
    int? id,
    String? name,
    String? rules,
    Value<String?> sort = const Value.absent(),
    Value<int?> limitCount = const Value.absent(),
    int? createdAt,
  }) => SmartPlaylist(
    id: id ?? this.id,
    name: name ?? this.name,
    rules: rules ?? this.rules,
    sort: sort.present ? sort.value : this.sort,
    limitCount: limitCount.present ? limitCount.value : this.limitCount,
    createdAt: createdAt ?? this.createdAt,
  );
  SmartPlaylist copyWithCompanion(SmartPlaylistsCompanion data) {
    return SmartPlaylist(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      rules: data.rules.present ? data.rules.value : this.rules,
      sort: data.sort.present ? data.sort.value : this.sort,
      limitCount: data.limitCount.present
          ? data.limitCount.value
          : this.limitCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SmartPlaylist(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rules: $rules, ')
          ..write('sort: $sort, ')
          ..write('limitCount: $limitCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, rules, sort, limitCount, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SmartPlaylist &&
          other.id == this.id &&
          other.name == this.name &&
          other.rules == this.rules &&
          other.sort == this.sort &&
          other.limitCount == this.limitCount &&
          other.createdAt == this.createdAt);
}

class SmartPlaylistsCompanion extends UpdateCompanion<SmartPlaylist> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> rules;
  final Value<String?> sort;
  final Value<int?> limitCount;
  final Value<int> createdAt;
  const SmartPlaylistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.rules = const Value.absent(),
    this.sort = const Value.absent(),
    this.limitCount = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SmartPlaylistsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String rules,
    this.sort = const Value.absent(),
    this.limitCount = const Value.absent(),
    required int createdAt,
  }) : name = Value(name),
       rules = Value(rules),
       createdAt = Value(createdAt);
  static Insertable<SmartPlaylist> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? rules,
    Expression<String>? sort,
    Expression<int>? limitCount,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (rules != null) 'rules': rules,
      if (sort != null) 'sort': sort,
      if (limitCount != null) 'limit_count': limitCount,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SmartPlaylistsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? rules,
    Value<String?>? sort,
    Value<int?>? limitCount,
    Value<int>? createdAt,
  }) {
    return SmartPlaylistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      rules: rules ?? this.rules,
      sort: sort ?? this.sort,
      limitCount: limitCount ?? this.limitCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rules.present) {
      map['rules'] = Variable<String>(rules.value);
    }
    if (sort.present) {
      map['sort'] = Variable<String>(sort.value);
    }
    if (limitCount.present) {
      map['limit_count'] = Variable<int>(limitCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SmartPlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rules: $rules, ')
          ..write('sort: $sort, ')
          ..write('limitCount: $limitCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $UserTagsTable extends UserTags with TableInfo<$UserTagsTable, UserTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE COLLATE NOCASE',
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, color];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserTag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      ),
    );
  }

  @override
  $UserTagsTable createAlias(String alias) {
    return $UserTagsTable(attachedDatabase, alias);
  }
}

class UserTag extends DataClass implements Insertable<UserTag> {
  final int id;
  final String name;

  /// Index of one of the eight accent tokens; null = none.
  final int? color;
  const UserTag({required this.id, required this.name, this.color});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    return map;
  }

  UserTagsCompanion toCompanion(bool nullToAbsent) {
    return UserTagsCompanion(
      id: Value(id),
      name: Value(name),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
    );
  }

  factory UserTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserTag(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<int?>(json['color']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<int?>(color),
    };
  }

  UserTag copyWith({
    int? id,
    String? name,
    Value<int?> color = const Value.absent(),
  }) => UserTag(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color.present ? color.value : this.color,
  );
  UserTag copyWithCompanion(UserTagsCompanion data) {
    return UserTag(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserTag(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, color);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserTag &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color);
}

class UserTagsCompanion extends UpdateCompanion<UserTag> {
  final Value<int> id;
  final Value<String> name;
  final Value<int?> color;
  const UserTagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
  });
  UserTagsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.color = const Value.absent(),
  }) : name = Value(name);
  static Insertable<UserTag> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? color,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
    });
  }

  UserTagsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int?>? color,
  }) {
    return UserTagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserTagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }
}

class $TrackTagsTable extends TrackTags
    with TableInfo<$TrackTagsTable, TrackTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<int> trackId = GeneratedColumn<int>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<int> tagId = GeneratedColumn<int>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES user_tags (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [trackId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'track_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrackTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {trackId, tagId};
  @override
  TrackTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackTag(
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $TrackTagsTable createAlias(String alias) {
    return $TrackTagsTable(attachedDatabase, alias);
  }
}

class TrackTag extends DataClass implements Insertable<TrackTag> {
  final int trackId;
  final int tagId;
  const TrackTag({required this.trackId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['track_id'] = Variable<int>(trackId);
    map['tag_id'] = Variable<int>(tagId);
    return map;
  }

  TrackTagsCompanion toCompanion(bool nullToAbsent) {
    return TrackTagsCompanion(trackId: Value(trackId), tagId: Value(tagId));
  }

  factory TrackTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackTag(
      trackId: serializer.fromJson<int>(json['trackId']),
      tagId: serializer.fromJson<int>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackId': serializer.toJson<int>(trackId),
      'tagId': serializer.toJson<int>(tagId),
    };
  }

  TrackTag copyWith({int? trackId, int? tagId}) =>
      TrackTag(trackId: trackId ?? this.trackId, tagId: tagId ?? this.tagId);
  TrackTag copyWithCompanion(TrackTagsCompanion data) {
    return TrackTag(
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackTag(')
          ..write('trackId: $trackId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(trackId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackTag &&
          other.trackId == this.trackId &&
          other.tagId == this.tagId);
}

class TrackTagsCompanion extends UpdateCompanion<TrackTag> {
  final Value<int> trackId;
  final Value<int> tagId;
  final Value<int> rowid;
  const TrackTagsCompanion({
    this.trackId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrackTagsCompanion.insert({
    required int trackId,
    required int tagId,
    this.rowid = const Value.absent(),
  }) : trackId = Value(trackId),
       tagId = Value(tagId);
  static Insertable<TrackTag> custom({
    Expression<int>? trackId,
    Expression<int>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (trackId != null) 'track_id': trackId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrackTagsCompanion copyWith({
    Value<int>? trackId,
    Value<int>? tagId,
    Value<int>? rowid,
  }) {
    return TrackTagsCompanion(
      trackId: trackId ?? this.trackId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (trackId.present) {
      map['track_id'] = Variable<int>(trackId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<int>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackTagsCompanion(')
          ..write('trackId: $trackId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TracksTable tracks = $TracksTable(this);
  late final $FoldersTable folders = $FoldersTable(this);
  late final $PlaylistsTable playlists = $PlaylistsTable(this);
  late final $PlaylistTracksTable playlistTracks = $PlaylistTracksTable(this);
  late final $PlaylistImportsTable playlistImports = $PlaylistImportsTable(
    this,
  );
  late final $PlaylistImportItemsTable playlistImportItems =
      $PlaylistImportItemsTable(this);
  late final $PlaysTable plays = $PlaysTable(this);
  late final $SmartPlaylistsTable smartPlaylists = $SmartPlaylistsTable(this);
  late final $UserTagsTable userTags = $UserTagsTable(this);
  late final $TrackTagsTable trackTags = $TrackTagsTable(this);
  late final Index tracksAlbumKey = Index(
    'tracks_album_key',
    'CREATE INDEX tracks_album_key ON tracks (album_key)',
  );
  late final Index tracksArtist = Index(
    'tracks_artist',
    'CREATE INDEX tracks_artist ON tracks (artist)',
  );
  late final Index tracksFavorite = Index(
    'tracks_favorite',
    'CREATE INDEX tracks_favorite ON tracks (is_favorite)',
  );
  late final Index tracksMissing = Index(
    'tracks_missing',
    'CREATE INDEX tracks_missing ON tracks (missing)',
  );
  late final Index tracksTitle = Index(
    'tracks_title',
    'CREATE INDEX tracks_title ON tracks (title)',
  );
  late final Index playlistTracksTrack = Index(
    'playlist_tracks_track',
    'CREATE INDEX playlist_tracks_track ON playlist_tracks (track_id)',
  );
  late final Index playsTrack = Index(
    'plays_track',
    'CREATE INDEX plays_track ON plays (track_id)',
  );
  late final Index playsAt = Index(
    'plays_at',
    'CREATE INDEX plays_at ON plays (played_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tracks,
    folders,
    playlists,
    playlistTracks,
    playlistImports,
    playlistImportItems,
    plays,
    smartPlaylists,
    userTags,
    trackTags,
    tracksAlbumKey,
    tracksArtist,
    tracksFavorite,
    tracksMissing,
    tracksTitle,
    playlistTracksTrack,
    playsTrack,
    playsAt,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playlist_tracks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tracks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playlist_tracks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playlist_imports', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlist_imports',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playlist_import_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tracks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playlist_import_items', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tracks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('plays', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tracks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('track_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'user_tags',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('track_tags', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$TracksTableCreateCompanionBuilder = TracksCompanion Function({
  Value<int> id,
  required String path,
  Value<int?> folderId,
  required String title,
  Value<String?> artist,
  Value<String?> albumArtist,
  Value<String?> album,
  required String albumKey,
  Value<int?> trackNumber,
  Value<int?> discNumber,
  Value<int?> year,
  Value<String?> genre,
  Value<int> durationMs,
  required String format,
  Value<int?> sampleRateHz,
  Value<int?> bitDepth,
  Value<int?> bitrateKbps,
  Value<int?> channels,
  required int sizeBytes,
  required int mtimeMs,
  Value<bool> hasCover,
  Value<String?> coverKey,
  Value<bool> isFavorite,
  Value<String?> lyricsPlain,
  Value<String?> lyricsSynced,
  Value<String?> curiosities,
  Value<int> enrichStatus,
  Value<bool> userEdited,
  Value<bool> missing,
  Value<String?> sha256,
  required int addedAt,
  Value<int> playCount,
  Value<double?> replayGainDb,
  Value<int?> resumePositionMs,
  Value<int?> lastPlayedAt,
});
typedef $$TracksTableUpdateCompanionBuilder = TracksCompanion Function({
  Value<int> id,
  Value<String> path,
  Value<int?> folderId,
  Value<String> title,
  Value<String?> artist,
  Value<String?> albumArtist,
  Value<String?> album,
  Value<String> albumKey,
  Value<int?> trackNumber,
  Value<int?> discNumber,
  Value<int?> year,
  Value<String?> genre,
  Value<int> durationMs,
  Value<String> format,
  Value<int?> sampleRateHz,
  Value<int?> bitDepth,
  Value<int?> bitrateKbps,
  Value<int?> channels,
  Value<int> sizeBytes,
  Value<int> mtimeMs,
  Value<bool> hasCover,
  Value<String?> coverKey,
  Value<bool> isFavorite,
  Value<String?> lyricsPlain,
  Value<String?> lyricsSynced,
  Value<String?> curiosities,
  Value<int> enrichStatus,
  Value<bool> userEdited,
  Value<bool> missing,
  Value<String?> sha256,
  Value<int> addedAt,
  Value<int> playCount,
  Value<double?> replayGainDb,
  Value<int?> resumePositionMs,
  Value<int?> lastPlayedAt,
});

final class $$TracksTableReferences
    extends BaseReferences<_$AppDatabase, $TracksTable, Track> {
  $$TracksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlaylistTracksTable, List<PlaylistTrack>>
  _playlistTracksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.playlistTracks,
    aliasName: 'tracks__id__playlist_tracks__track_id',
  );

  $$PlaylistTracksTableProcessedTableManager get playlistTracksRefs {
    final manager = $$PlaylistTracksTableTableManager(
      $_db,
      $_db.playlistTracks,
    ).filter((f) => f.trackId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_playlistTracksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $PlaylistImportItemsTable,
    List<PlaylistImportItem>
  >
  _playlistImportItemsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.playlistImportItems,
        aliasName: 'tracks__id__playlist_import_items__track_id',
      );

  $$PlaylistImportItemsTableProcessedTableManager get playlistImportItemsRefs {
    final manager = $$PlaylistImportItemsTableTableManager(
      $_db,
      $_db.playlistImportItems,
    ).filter((f) => f.trackId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _playlistImportItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlaysTable, List<Play>> _playsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.plays,
    aliasName: 'tracks__id__plays__track_id',
  );

  $$PlaysTableProcessedTableManager get playsRefs {
    final manager = $$PlaysTableTableManager(
      $_db,
      $_db.plays,
    ).filter((f) => f.trackId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_playsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TrackTagsTable, List<TrackTag>>
  _trackTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.trackTags,
    aliasName: 'tracks__id__track_tags__track_id',
  );

  $$TrackTagsTableProcessedTableManager get trackTagsRefs {
    final manager = $$TrackTagsTableTableManager(
      $_db,
      $_db.trackTags,
    ).filter((f) => f.trackId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_trackTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TracksTableFilterComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumKey => $composableBuilder(
    column: $table.albumKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discNumber => $composableBuilder(
    column: $table.discNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sampleRateHz => $composableBuilder(
    column: $table.sampleRateHz,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bitDepth => $composableBuilder(
    column: $table.bitDepth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bitrateKbps => $composableBuilder(
    column: $table.bitrateKbps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get channels => $composableBuilder(
    column: $table.channels,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mtimeMs => $composableBuilder(
    column: $table.mtimeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasCover => $composableBuilder(
    column: $table.hasCover,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverKey => $composableBuilder(
    column: $table.coverKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lyricsPlain => $composableBuilder(
    column: $table.lyricsPlain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lyricsSynced => $composableBuilder(
    column: $table.lyricsSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get curiosities => $composableBuilder(
    column: $table.curiosities,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get enrichStatus => $composableBuilder(
    column: $table.enrichStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get userEdited => $composableBuilder(
    column: $table.userEdited,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get missing => $composableBuilder(
    column: $table.missing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playCount => $composableBuilder(
    column: $table.playCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get replayGainDb => $composableBuilder(
    column: $table.replayGainDb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get resumePositionMs => $composableBuilder(
    column: $table.resumePositionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> playlistTracksRefs(
    Expression<bool> Function($$PlaylistTracksTableFilterComposer f) f,
  ) {
    final $$PlaylistTracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistTracks,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistTracksTableFilterComposer(
            $db: $db,
            $table: $db.playlistTracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> playlistImportItemsRefs(
    Expression<bool> Function($$PlaylistImportItemsTableFilterComposer f) f,
  ) {
    final $$PlaylistImportItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistImportItems,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistImportItemsTableFilterComposer(
            $db: $db,
            $table: $db.playlistImportItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> playsRefs(
    Expression<bool> Function($$PlaysTableFilterComposer f) f,
  ) {
    final $$PlaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plays,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaysTableFilterComposer(
            $db: $db,
            $table: $db.plays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> trackTagsRefs(
    Expression<bool> Function($$TrackTagsTableFilterComposer f) f,
  ) {
    final $$TrackTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackTags,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackTagsTableFilterComposer(
            $db: $db,
            $table: $db.trackTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TracksTableOrderingComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumKey => $composableBuilder(
    column: $table.albumKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discNumber => $composableBuilder(
    column: $table.discNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sampleRateHz => $composableBuilder(
    column: $table.sampleRateHz,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bitDepth => $composableBuilder(
    column: $table.bitDepth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bitrateKbps => $composableBuilder(
    column: $table.bitrateKbps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get channels => $composableBuilder(
    column: $table.channels,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mtimeMs => $composableBuilder(
    column: $table.mtimeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasCover => $composableBuilder(
    column: $table.hasCover,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverKey => $composableBuilder(
    column: $table.coverKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lyricsPlain => $composableBuilder(
    column: $table.lyricsPlain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lyricsSynced => $composableBuilder(
    column: $table.lyricsSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get curiosities => $composableBuilder(
    column: $table.curiosities,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get enrichStatus => $composableBuilder(
    column: $table.enrichStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get userEdited => $composableBuilder(
    column: $table.userEdited,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get missing => $composableBuilder(
    column: $table.missing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playCount => $composableBuilder(
    column: $table.playCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get replayGainDb => $composableBuilder(
    column: $table.replayGainDb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get resumePositionMs => $composableBuilder(
    column: $table.resumePositionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TracksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<int> get folderId =>
      $composableBuilder(column: $table.folderId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => column,
  );

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<String> get albumKey =>
      $composableBuilder(column: $table.albumKey, builder: (column) => column);

  GeneratedColumn<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discNumber => $composableBuilder(
    column: $table.discNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<int> get sampleRateHz => $composableBuilder(
    column: $table.sampleRateHz,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bitDepth =>
      $composableBuilder(column: $table.bitDepth, builder: (column) => column);

  GeneratedColumn<int> get bitrateKbps => $composableBuilder(
    column: $table.bitrateKbps,
    builder: (column) => column,
  );

  GeneratedColumn<int> get channels =>
      $composableBuilder(column: $table.channels, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<int> get mtimeMs =>
      $composableBuilder(column: $table.mtimeMs, builder: (column) => column);

  GeneratedColumn<bool> get hasCover =>
      $composableBuilder(column: $table.hasCover, builder: (column) => column);

  GeneratedColumn<String> get coverKey =>
      $composableBuilder(column: $table.coverKey, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lyricsPlain => $composableBuilder(
    column: $table.lyricsPlain,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lyricsSynced => $composableBuilder(
    column: $table.lyricsSynced,
    builder: (column) => column,
  );

  GeneratedColumn<String> get curiosities => $composableBuilder(
    column: $table.curiosities,
    builder: (column) => column,
  );

  GeneratedColumn<int> get enrichStatus => $composableBuilder(
    column: $table.enrichStatus,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get userEdited => $composableBuilder(
    column: $table.userEdited,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get missing =>
      $composableBuilder(column: $table.missing, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<int> get playCount =>
      $composableBuilder(column: $table.playCount, builder: (column) => column);

  GeneratedColumn<double> get replayGainDb => $composableBuilder(
    column: $table.replayGainDb,
    builder: (column) => column,
  );

  GeneratedColumn<int> get resumePositionMs => $composableBuilder(
    column: $table.resumePositionMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => column,
  );

  Expression<T> playlistTracksRefs<T extends Object>(
    Expression<T> Function($$PlaylistTracksTableAnnotationComposer a) f,
  ) {
    final $$PlaylistTracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistTracks,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistTracksTableAnnotationComposer(
            $db: $db,
            $table: $db.playlistTracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> playlistImportItemsRefs<T extends Object>(
    Expression<T> Function($$PlaylistImportItemsTableAnnotationComposer a) f,
  ) {
    final $$PlaylistImportItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.playlistImportItems,
          getReferencedColumn: (t) => t.trackId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PlaylistImportItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.playlistImportItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> playsRefs<T extends Object>(
    Expression<T> Function($$PlaysTableAnnotationComposer a) f,
  ) {
    final $$PlaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plays,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaysTableAnnotationComposer(
            $db: $db,
            $table: $db.plays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> trackTagsRefs<T extends Object>(
    Expression<T> Function($$TrackTagsTableAnnotationComposer a) f,
  ) {
    final $$TrackTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackTags,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.trackTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TracksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TracksTable,
          Track,
          $$TracksTableFilterComposer,
          $$TracksTableOrderingComposer,
          $$TracksTableAnnotationComposer,
          $$TracksTableCreateCompanionBuilder,
          $$TracksTableUpdateCompanionBuilder,
          (Track, $$TracksTableReferences),
          Track,
          PrefetchHooks Function({
            bool playlistTracksRefs,
            bool playlistImportItemsRefs,
            bool playsRefs,
            bool trackTagsRefs,
          })
        > {
  $$TracksTableTableManager(_$AppDatabase db, $TracksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<int?> folderId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> artist = const Value.absent(),
                Value<String?> albumArtist = const Value.absent(),
                Value<String?> album = const Value.absent(),
                Value<String> albumKey = const Value.absent(),
                Value<int?> trackNumber = const Value.absent(),
                Value<int?> discNumber = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<int?> sampleRateHz = const Value.absent(),
                Value<int?> bitDepth = const Value.absent(),
                Value<int?> bitrateKbps = const Value.absent(),
                Value<int?> channels = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<int> mtimeMs = const Value.absent(),
                Value<bool> hasCover = const Value.absent(),
                Value<String?> coverKey = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<String?> lyricsPlain = const Value.absent(),
                Value<String?> lyricsSynced = const Value.absent(),
                Value<String?> curiosities = const Value.absent(),
                Value<int> enrichStatus = const Value.absent(),
                Value<bool> userEdited = const Value.absent(),
                Value<bool> missing = const Value.absent(),
                Value<String?> sha256 = const Value.absent(),
                Value<int> addedAt = const Value.absent(),
                Value<int> playCount = const Value.absent(),
                Value<double?> replayGainDb = const Value.absent(),
                Value<int?> resumePositionMs = const Value.absent(),
                Value<int?> lastPlayedAt = const Value.absent(),
              }) => TracksCompanion(
                id: id,
                path: path,
                folderId: folderId,
                title: title,
                artist: artist,
                albumArtist: albumArtist,
                album: album,
                albumKey: albumKey,
                trackNumber: trackNumber,
                discNumber: discNumber,
                year: year,
                genre: genre,
                durationMs: durationMs,
                format: format,
                sampleRateHz: sampleRateHz,
                bitDepth: bitDepth,
                bitrateKbps: bitrateKbps,
                channels: channels,
                sizeBytes: sizeBytes,
                mtimeMs: mtimeMs,
                hasCover: hasCover,
                coverKey: coverKey,
                isFavorite: isFavorite,
                lyricsPlain: lyricsPlain,
                lyricsSynced: lyricsSynced,
                curiosities: curiosities,
                enrichStatus: enrichStatus,
                userEdited: userEdited,
                missing: missing,
                sha256: sha256,
                addedAt: addedAt,
                playCount: playCount,
                replayGainDb: replayGainDb,
                resumePositionMs: resumePositionMs,
                lastPlayedAt: lastPlayedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String path,
                Value<int?> folderId = const Value.absent(),
                required String title,
                Value<String?> artist = const Value.absent(),
                Value<String?> albumArtist = const Value.absent(),
                Value<String?> album = const Value.absent(),
                required String albumKey,
                Value<int?> trackNumber = const Value.absent(),
                Value<int?> discNumber = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                required String format,
                Value<int?> sampleRateHz = const Value.absent(),
                Value<int?> bitDepth = const Value.absent(),
                Value<int?> bitrateKbps = const Value.absent(),
                Value<int?> channels = const Value.absent(),
                required int sizeBytes,
                required int mtimeMs,
                Value<bool> hasCover = const Value.absent(),
                Value<String?> coverKey = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<String?> lyricsPlain = const Value.absent(),
                Value<String?> lyricsSynced = const Value.absent(),
                Value<String?> curiosities = const Value.absent(),
                Value<int> enrichStatus = const Value.absent(),
                Value<bool> userEdited = const Value.absent(),
                Value<bool> missing = const Value.absent(),
                Value<String?> sha256 = const Value.absent(),
                required int addedAt,
                Value<int> playCount = const Value.absent(),
                Value<double?> replayGainDb = const Value.absent(),
                Value<int?> resumePositionMs = const Value.absent(),
                Value<int?> lastPlayedAt = const Value.absent(),
              }) => TracksCompanion.insert(
                id: id,
                path: path,
                folderId: folderId,
                title: title,
                artist: artist,
                albumArtist: albumArtist,
                album: album,
                albumKey: albumKey,
                trackNumber: trackNumber,
                discNumber: discNumber,
                year: year,
                genre: genre,
                durationMs: durationMs,
                format: format,
                sampleRateHz: sampleRateHz,
                bitDepth: bitDepth,
                bitrateKbps: bitrateKbps,
                channels: channels,
                sizeBytes: sizeBytes,
                mtimeMs: mtimeMs,
                hasCover: hasCover,
                coverKey: coverKey,
                isFavorite: isFavorite,
                lyricsPlain: lyricsPlain,
                lyricsSynced: lyricsSynced,
                curiosities: curiosities,
                enrichStatus: enrichStatus,
                userEdited: userEdited,
                missing: missing,
                sha256: sha256,
                addedAt: addedAt,
                playCount: playCount,
                replayGainDb: replayGainDb,
                resumePositionMs: resumePositionMs,
                lastPlayedAt: lastPlayedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TracksTable, Track>(table),
                  $$TracksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                playlistTracksRefs = false,
                playlistImportItemsRefs = false,
                playsRefs = false,
                trackTagsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (playlistTracksRefs) db.playlistTracks,
                    if (playlistImportItemsRefs) db.playlistImportItems,
                    if (playsRefs) db.plays,
                    if (trackTagsRefs) db.trackTags,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (playlistTracksRefs)
                        await $_getPrefetchedData<
                          Track,
                          $TracksTable,
                          PlaylistTrack
                        >(
                          currentTable: table,
                          referencedTable: $$TracksTableReferences
                              ._playlistTracksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TracksTableReferences(
                                db,
                                table,
                                p0,
                              ).playlistTracksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.trackId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (playlistImportItemsRefs)
                        await $_getPrefetchedData<
                          Track,
                          $TracksTable,
                          PlaylistImportItem
                        >(
                          currentTable: table,
                          referencedTable: $$TracksTableReferences
                              ._playlistImportItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TracksTableReferences(
                                db,
                                table,
                                p0,
                              ).playlistImportItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.trackId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (playsRefs)
                        await $_getPrefetchedData<Track, $TracksTable, Play>(
                          currentTable: table,
                          referencedTable: $$TracksTableReferences
                              ._playsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TracksTableReferences(db, table, p0).playsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.trackId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (trackTagsRefs)
                        await $_getPrefetchedData<
                          Track,
                          $TracksTable,
                          TrackTag
                        >(
                          currentTable: table,
                          referencedTable: $$TracksTableReferences
                              ._trackTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TracksTableReferences(
                                db,
                                table,
                                p0,
                              ).trackTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.trackId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TracksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TracksTable,
      Track,
      $$TracksTableFilterComposer,
      $$TracksTableOrderingComposer,
      $$TracksTableAnnotationComposer,
      $$TracksTableCreateCompanionBuilder,
      $$TracksTableUpdateCompanionBuilder,
      (Track, $$TracksTableReferences),
      Track,
      PrefetchHooks Function({
        bool playlistTracksRefs,
        bool playlistImportItemsRefs,
        bool playsRefs,
        bool trackTagsRefs,
      })
    >;
typedef $$FoldersTableCreateCompanionBuilder = FoldersCompanion Function({
  Value<int> id,
  required String path,
  required int addedAt,
  Value<String?> label,
});
typedef $$FoldersTableUpdateCompanionBuilder = FoldersCompanion Function({
  Value<int> id,
  Value<String> path,
  Value<int> addedAt,
  Value<String?> label,
});

class $$FoldersTableFilterComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoldersTableOrderingComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoldersTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);
}

class $$FoldersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoldersTable,
          Folder,
          $$FoldersTableFilterComposer,
          $$FoldersTableOrderingComposer,
          $$FoldersTableAnnotationComposer,
          $$FoldersTableCreateCompanionBuilder,
          $$FoldersTableUpdateCompanionBuilder,
          (Folder, BaseReferences<_$AppDatabase, $FoldersTable, Folder>),
          Folder,
          PrefetchHooks Function()
        > {
  $$FoldersTableTableManager(_$AppDatabase db, $FoldersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<int> addedAt = const Value.absent(),
                Value<String?> label = const Value.absent(),
              }) => FoldersCompanion(
                id: id,
                path: path,
                addedAt: addedAt,
                label: label,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String path,
                required int addedAt,
                Value<String?> label = const Value.absent(),
              }) => FoldersCompanion.insert(
                id: id,
                path: path,
                addedAt: addedAt,
                label: label,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FoldersTable, Folder>(table),
                  BaseReferences<_$AppDatabase, $FoldersTable, Folder>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoldersTable,
      Folder,
      $$FoldersTableFilterComposer,
      $$FoldersTableOrderingComposer,
      $$FoldersTableAnnotationComposer,
      $$FoldersTableCreateCompanionBuilder,
      $$FoldersTableUpdateCompanionBuilder,
      (Folder, BaseReferences<_$AppDatabase, $FoldersTable, Folder>),
      Folder,
      PrefetchHooks Function()
    >;
typedef $$PlaylistsTableCreateCompanionBuilder = PlaylistsCompanion Function({
  Value<int> id,
  required String name,
  required int createdAt,
  Value<String?> coverKey,
});
typedef $$PlaylistsTableUpdateCompanionBuilder = PlaylistsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> createdAt,
  Value<String?> coverKey,
});

final class $$PlaylistsTableReferences
    extends BaseReferences<_$AppDatabase, $PlaylistsTable, Playlist> {
  $$PlaylistsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlaylistTracksTable, List<PlaylistTrack>>
  _playlistTracksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.playlistTracks,
    aliasName: 'playlists__id__playlist_tracks__playlist_id',
  );

  $$PlaylistTracksTableProcessedTableManager get playlistTracksRefs {
    final manager = $$PlaylistTracksTableTableManager(
      $_db,
      $_db.playlistTracks,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_playlistTracksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlaylistImportsTable, List<PlaylistImport>>
  _playlistImportsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.playlistImports,
    aliasName: 'playlists__id__playlist_imports__playlist_id',
  );

  $$PlaylistImportsTableProcessedTableManager get playlistImportsRefs {
    final manager = $$PlaylistImportsTableTableManager(
      $_db,
      $_db.playlistImports,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _playlistImportsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlaylistsTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverKey => $composableBuilder(
    column: $table.coverKey,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> playlistTracksRefs(
    Expression<bool> Function($$PlaylistTracksTableFilterComposer f) f,
  ) {
    final $$PlaylistTracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistTracks,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistTracksTableFilterComposer(
            $db: $db,
            $table: $db.playlistTracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> playlistImportsRefs(
    Expression<bool> Function($$PlaylistImportsTableFilterComposer f) f,
  ) {
    final $$PlaylistImportsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistImports,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistImportsTableFilterComposer(
            $db: $db,
            $table: $db.playlistImports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverKey => $composableBuilder(
    column: $table.coverKey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaylistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get coverKey =>
      $composableBuilder(column: $table.coverKey, builder: (column) => column);

  Expression<T> playlistTracksRefs<T extends Object>(
    Expression<T> Function($$PlaylistTracksTableAnnotationComposer a) f,
  ) {
    final $$PlaylistTracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistTracks,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistTracksTableAnnotationComposer(
            $db: $db,
            $table: $db.playlistTracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> playlistImportsRefs<T extends Object>(
    Expression<T> Function($$PlaylistImportsTableAnnotationComposer a) f,
  ) {
    final $$PlaylistImportsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistImports,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistImportsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlistImports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaylistsTable,
          Playlist,
          $$PlaylistsTableFilterComposer,
          $$PlaylistsTableOrderingComposer,
          $$PlaylistsTableAnnotationComposer,
          $$PlaylistsTableCreateCompanionBuilder,
          $$PlaylistsTableUpdateCompanionBuilder,
          (Playlist, $$PlaylistsTableReferences),
          Playlist,
          PrefetchHooks Function({
            bool playlistTracksRefs,
            bool playlistImportsRefs,
          })
        > {
  $$PlaylistsTableTableManager(_$AppDatabase db, $PlaylistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String?> coverKey = const Value.absent(),
              }) => PlaylistsCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                coverKey: coverKey,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int createdAt,
                Value<String?> coverKey = const Value.absent(),
              }) => PlaylistsCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                coverKey: coverKey,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaylistsTable, Playlist>(table),
                  $$PlaylistsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({playlistTracksRefs = false, playlistImportsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (playlistTracksRefs) db.playlistTracks,
                    if (playlistImportsRefs) db.playlistImports,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (playlistTracksRefs)
                        await $_getPrefetchedData<
                          Playlist,
                          $PlaylistsTable,
                          PlaylistTrack
                        >(
                          currentTable: table,
                          referencedTable: $$PlaylistsTableReferences
                              ._playlistTracksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlaylistsTableReferences(
                                db,
                                table,
                                p0,
                              ).playlistTracksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playlistId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (playlistImportsRefs)
                        await $_getPrefetchedData<
                          Playlist,
                          $PlaylistsTable,
                          PlaylistImport
                        >(
                          currentTable: table,
                          referencedTable: $$PlaylistsTableReferences
                              ._playlistImportsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlaylistsTableReferences(
                                db,
                                table,
                                p0,
                              ).playlistImportsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playlistId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PlaylistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaylistsTable,
      Playlist,
      $$PlaylistsTableFilterComposer,
      $$PlaylistsTableOrderingComposer,
      $$PlaylistsTableAnnotationComposer,
      $$PlaylistsTableCreateCompanionBuilder,
      $$PlaylistsTableUpdateCompanionBuilder,
      (Playlist, $$PlaylistsTableReferences),
      Playlist,
      PrefetchHooks Function({
        bool playlistTracksRefs,
        bool playlistImportsRefs,
      })
    >;
typedef $$PlaylistTracksTableCreateCompanionBuilder =
    PlaylistTracksCompanion Function({
      required int playlistId,
      required int trackId,
      required int position,
      Value<int> rowid,
    });
typedef $$PlaylistTracksTableUpdateCompanionBuilder =
    PlaylistTracksCompanion Function({
      Value<int> playlistId,
      Value<int> trackId,
      Value<int> position,
      Value<int> rowid,
    });

final class $$PlaylistTracksTableReferences
    extends BaseReferences<_$AppDatabase, $PlaylistTracksTable, PlaylistTrack> {
  $$PlaylistTracksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlaylistsTable _playlistIdTable(_$AppDatabase db) =>
      db.playlists.createAlias('playlist_tracks__playlist_id__playlists__id');

  $$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<int>('playlist_id')!;

    final manager = $$PlaylistsTableTableManager(
      $_db,
      $_db.playlists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TracksTable _trackIdTable(_$AppDatabase db) =>
      db.tracks.createAlias('playlist_tracks__track_id__tracks__id');

  $$TracksTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<int>('track_id')!;

    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlaylistTracksTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistTracksTable> {
  $$PlaylistTracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TracksTableFilterComposer get trackId {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistTracksTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistTracksTable> {
  $$PlaylistTracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TracksTableOrderingComposer get trackId {
    final $$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableOrderingComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistTracksTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistTracksTable> {
  $$PlaylistTracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TracksTableAnnotationComposer get trackId {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistTracksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaylistTracksTable,
          PlaylistTrack,
          $$PlaylistTracksTableFilterComposer,
          $$PlaylistTracksTableOrderingComposer,
          $$PlaylistTracksTableAnnotationComposer,
          $$PlaylistTracksTableCreateCompanionBuilder,
          $$PlaylistTracksTableUpdateCompanionBuilder,
          (PlaylistTrack, $$PlaylistTracksTableReferences),
          PlaylistTrack,
          PrefetchHooks Function({bool playlistId, bool trackId})
        > {
  $$PlaylistTracksTableTableManager(
    _$AppDatabase db,
    $PlaylistTracksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistTracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistTracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistTracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> playlistId = const Value.absent(),
                Value<int> trackId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistTracksCompanion(
                playlistId: playlistId,
                trackId: trackId,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int playlistId,
                required int trackId,
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => PlaylistTracksCompanion.insert(
                playlistId: playlistId,
                trackId: trackId,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaylistTracksTable, PlaylistTrack>(table),
                  $$PlaylistTracksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistId = false, trackId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (playlistId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.playlistId,
                        referencedTable: $$PlaylistTracksTableReferences
                            ._playlistIdTable(db),
                        referencedColumn: $$PlaylistTracksTableReferences
                            ._playlistIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (trackId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.trackId,
                        referencedTable: $$PlaylistTracksTableReferences
                            ._trackIdTable(db),
                        referencedColumn: $$PlaylistTracksTableReferences
                            ._trackIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlaylistTracksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaylistTracksTable,
      PlaylistTrack,
      $$PlaylistTracksTableFilterComposer,
      $$PlaylistTracksTableOrderingComposer,
      $$PlaylistTracksTableAnnotationComposer,
      $$PlaylistTracksTableCreateCompanionBuilder,
      $$PlaylistTracksTableUpdateCompanionBuilder,
      (PlaylistTrack, $$PlaylistTracksTableReferences),
      PlaylistTrack,
      PrefetchHooks Function({bool playlistId, bool trackId})
    >;
typedef $$PlaylistImportsTableCreateCompanionBuilder =
    PlaylistImportsCompanion Function({
      Value<int> id,
      required int playlistId,
      required String sourceName,
      required int createdAt,
      Value<int> status,
      Value<String> sourceKind,
      Value<String?> folderPath,
      Value<bool> numberFiles,
      Value<bool> linkOnly,
      Value<bool> planFirst,
      Value<bool> fetchCovers,
    });
typedef $$PlaylistImportsTableUpdateCompanionBuilder =
    PlaylistImportsCompanion Function({
      Value<int> id,
      Value<int> playlistId,
      Value<String> sourceName,
      Value<int> createdAt,
      Value<int> status,
      Value<String> sourceKind,
      Value<String?> folderPath,
      Value<bool> numberFiles,
      Value<bool> linkOnly,
      Value<bool> planFirst,
      Value<bool> fetchCovers,
    });

final class $$PlaylistImportsTableReferences
    extends
        BaseReferences<_$AppDatabase, $PlaylistImportsTable, PlaylistImport> {
  $$PlaylistImportsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlaylistsTable _playlistIdTable(_$AppDatabase db) =>
      db.playlists.createAlias('playlist_imports__playlist_id__playlists__id');

  $$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<int>('playlist_id')!;

    final manager = $$PlaylistsTableTableManager(
      $_db,
      $_db.playlists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $PlaylistImportItemsTable,
    List<PlaylistImportItem>
  >
  _playlistImportItemsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.playlistImportItems,
        aliasName: 'playlist_imports__id__playlist_import_items__import_id',
      );

  $$PlaylistImportItemsTableProcessedTableManager get playlistImportItemsRefs {
    final manager = $$PlaylistImportItemsTableTableManager(
      $_db,
      $_db.playlistImportItems,
    ).filter((f) => f.importId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _playlistImportItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlaylistImportsTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistImportsTable> {
  $$PlaylistImportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceKind => $composableBuilder(
    column: $table.sourceKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderPath => $composableBuilder(
    column: $table.folderPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get numberFiles => $composableBuilder(
    column: $table.numberFiles,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get linkOnly => $composableBuilder(
    column: $table.linkOnly,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get planFirst => $composableBuilder(
    column: $table.planFirst,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get fetchCovers => $composableBuilder(
    column: $table.fetchCovers,
    builder: (column) => ColumnFilters(column),
  );

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> playlistImportItemsRefs(
    Expression<bool> Function($$PlaylistImportItemsTableFilterComposer f) f,
  ) {
    final $$PlaylistImportItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistImportItems,
      getReferencedColumn: (t) => t.importId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistImportItemsTableFilterComposer(
            $db: $db,
            $table: $db.playlistImportItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistImportsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistImportsTable> {
  $$PlaylistImportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceKind => $composableBuilder(
    column: $table.sourceKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderPath => $composableBuilder(
    column: $table.folderPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get numberFiles => $composableBuilder(
    column: $table.numberFiles,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get linkOnly => $composableBuilder(
    column: $table.linkOnly,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get planFirst => $composableBuilder(
    column: $table.planFirst,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get fetchCovers => $composableBuilder(
    column: $table.fetchCovers,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistImportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistImportsTable> {
  $$PlaylistImportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get sourceKind => $composableBuilder(
    column: $table.sourceKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get folderPath => $composableBuilder(
    column: $table.folderPath,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get numberFiles => $composableBuilder(
    column: $table.numberFiles,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get linkOnly =>
      $composableBuilder(column: $table.linkOnly, builder: (column) => column);

  GeneratedColumn<bool> get planFirst =>
      $composableBuilder(column: $table.planFirst, builder: (column) => column);

  GeneratedColumn<bool> get fetchCovers => $composableBuilder(
    column: $table.fetchCovers,
    builder: (column) => column,
  );

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> playlistImportItemsRefs<T extends Object>(
    Expression<T> Function($$PlaylistImportItemsTableAnnotationComposer a) f,
  ) {
    final $$PlaylistImportItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.playlistImportItems,
          getReferencedColumn: (t) => t.importId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PlaylistImportItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.playlistImportItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PlaylistImportsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaylistImportsTable,
          PlaylistImport,
          $$PlaylistImportsTableFilterComposer,
          $$PlaylistImportsTableOrderingComposer,
          $$PlaylistImportsTableAnnotationComposer,
          $$PlaylistImportsTableCreateCompanionBuilder,
          $$PlaylistImportsTableUpdateCompanionBuilder,
          (PlaylistImport, $$PlaylistImportsTableReferences),
          PlaylistImport,
          PrefetchHooks Function({
            bool playlistId,
            bool playlistImportItemsRefs,
          })
        > {
  $$PlaylistImportsTableTableManager(
    _$AppDatabase db,
    $PlaylistImportsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistImportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistImportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistImportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> playlistId = const Value.absent(),
                Value<String> sourceName = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<String> sourceKind = const Value.absent(),
                Value<String?> folderPath = const Value.absent(),
                Value<bool> numberFiles = const Value.absent(),
                Value<bool> linkOnly = const Value.absent(),
                Value<bool> planFirst = const Value.absent(),
                Value<bool> fetchCovers = const Value.absent(),
              }) => PlaylistImportsCompanion(
                id: id,
                playlistId: playlistId,
                sourceName: sourceName,
                createdAt: createdAt,
                status: status,
                sourceKind: sourceKind,
                folderPath: folderPath,
                numberFiles: numberFiles,
                linkOnly: linkOnly,
                planFirst: planFirst,
                fetchCovers: fetchCovers,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int playlistId,
                required String sourceName,
                required int createdAt,
                Value<int> status = const Value.absent(),
                Value<String> sourceKind = const Value.absent(),
                Value<String?> folderPath = const Value.absent(),
                Value<bool> numberFiles = const Value.absent(),
                Value<bool> linkOnly = const Value.absent(),
                Value<bool> planFirst = const Value.absent(),
                Value<bool> fetchCovers = const Value.absent(),
              }) => PlaylistImportsCompanion.insert(
                id: id,
                playlistId: playlistId,
                sourceName: sourceName,
                createdAt: createdAt,
                status: status,
                sourceKind: sourceKind,
                folderPath: folderPath,
                numberFiles: numberFiles,
                linkOnly: linkOnly,
                planFirst: planFirst,
                fetchCovers: fetchCovers,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaylistImportsTable, PlaylistImport>(table),
                  $$PlaylistImportsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({playlistId = false, playlistImportItemsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (playlistImportItemsRefs) db.playlistImportItems,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (playlistId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.playlistId,
                            referencedTable: $$PlaylistImportsTableReferences
                                ._playlistIdTable(db),
                            referencedColumn: $$PlaylistImportsTableReferences
                                ._playlistIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (playlistImportItemsRefs)
                        await $_getPrefetchedData<
                          PlaylistImport,
                          $PlaylistImportsTable,
                          PlaylistImportItem
                        >(
                          currentTable: table,
                          referencedTable: $$PlaylistImportsTableReferences
                              ._playlistImportItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlaylistImportsTableReferences(
                                db,
                                table,
                                p0,
                              ).playlistImportItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.importId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PlaylistImportsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaylistImportsTable,
      PlaylistImport,
      $$PlaylistImportsTableFilterComposer,
      $$PlaylistImportsTableOrderingComposer,
      $$PlaylistImportsTableAnnotationComposer,
      $$PlaylistImportsTableCreateCompanionBuilder,
      $$PlaylistImportsTableUpdateCompanionBuilder,
      (PlaylistImport, $$PlaylistImportsTableReferences),
      PlaylistImport,
      PrefetchHooks Function({bool playlistId, bool playlistImportItemsRefs})
    >;
typedef $$PlaylistImportItemsTableCreateCompanionBuilder =
    PlaylistImportItemsCompanion Function({
      required int importId,
      required int rowIndex,
      required String title,
      required String artists,
      Value<String?> album,
      Value<int?> durationMs,
      Value<String?> isrc,
      Value<int> status,
      Value<String?> videoId,
      Value<String?> candidates,
      Value<int?> trackId,
      Value<double?> score,
      Value<String?> note,
      Value<String?> location,
      Value<int> rowid,
    });
typedef $$PlaylistImportItemsTableUpdateCompanionBuilder =
    PlaylistImportItemsCompanion Function({
      Value<int> importId,
      Value<int> rowIndex,
      Value<String> title,
      Value<String> artists,
      Value<String?> album,
      Value<int?> durationMs,
      Value<String?> isrc,
      Value<int> status,
      Value<String?> videoId,
      Value<String?> candidates,
      Value<int?> trackId,
      Value<double?> score,
      Value<String?> note,
      Value<String?> location,
      Value<int> rowid,
    });

final class $$PlaylistImportItemsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PlaylistImportItemsTable,
          PlaylistImportItem
        > {
  $$PlaylistImportItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlaylistImportsTable _importIdTable(_$AppDatabase db) => db
      .playlistImports
      .createAlias('playlist_import_items__import_id__playlist_imports__id');

  $$PlaylistImportsTableProcessedTableManager get importId {
    final $_column = $_itemColumn<int>('import_id')!;

    final manager = $$PlaylistImportsTableTableManager(
      $_db,
      $_db.playlistImports,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_importIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TracksTable _trackIdTable(_$AppDatabase db) =>
      db.tracks.createAlias('playlist_import_items__track_id__tracks__id');

  $$TracksTableProcessedTableManager? get trackId {
    final $_column = $_itemColumn<int>('track_id');
    if ($_column == null) return null;
    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlaylistImportItemsTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistImportItemsTable> {
  $$PlaylistImportItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowIndex => $composableBuilder(
    column: $table.rowIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artists => $composableBuilder(
    column: $table.artists,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get isrc => $composableBuilder(
    column: $table.isrc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get candidates => $composableBuilder(
    column: $table.candidates,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  $$PlaylistImportsTableFilterComposer get importId {
    final $$PlaylistImportsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.importId,
      referencedTable: $db.playlistImports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistImportsTableFilterComposer(
            $db: $db,
            $table: $db.playlistImports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TracksTableFilterComposer get trackId {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistImportItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistImportItemsTable> {
  $$PlaylistImportItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowIndex => $composableBuilder(
    column: $table.rowIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artists => $composableBuilder(
    column: $table.artists,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get isrc => $composableBuilder(
    column: $table.isrc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get candidates => $composableBuilder(
    column: $table.candidates,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlaylistImportsTableOrderingComposer get importId {
    final $$PlaylistImportsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.importId,
      referencedTable: $db.playlistImports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistImportsTableOrderingComposer(
            $db: $db,
            $table: $db.playlistImports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TracksTableOrderingComposer get trackId {
    final $$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableOrderingComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistImportItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistImportItemsTable> {
  $$PlaylistImportItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowIndex =>
      $composableBuilder(column: $table.rowIndex, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artists =>
      $composableBuilder(column: $table.artists, builder: (column) => column);

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get isrc =>
      $composableBuilder(column: $table.isrc, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<String> get candidates => $composableBuilder(
    column: $table.candidates,
    builder: (column) => column,
  );

  GeneratedColumn<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  $$PlaylistImportsTableAnnotationComposer get importId {
    final $$PlaylistImportsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.importId,
      referencedTable: $db.playlistImports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistImportsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlistImports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TracksTableAnnotationComposer get trackId {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistImportItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaylistImportItemsTable,
          PlaylistImportItem,
          $$PlaylistImportItemsTableFilterComposer,
          $$PlaylistImportItemsTableOrderingComposer,
          $$PlaylistImportItemsTableAnnotationComposer,
          $$PlaylistImportItemsTableCreateCompanionBuilder,
          $$PlaylistImportItemsTableUpdateCompanionBuilder,
          (PlaylistImportItem, $$PlaylistImportItemsTableReferences),
          PlaylistImportItem,
          PrefetchHooks Function({bool importId, bool trackId})
        > {
  $$PlaylistImportItemsTableTableManager(
    _$AppDatabase db,
    $PlaylistImportItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistImportItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistImportItemsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PlaylistImportItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> importId = const Value.absent(),
                Value<int> rowIndex = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> artists = const Value.absent(),
                Value<String?> album = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<String?> isrc = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<String?> videoId = const Value.absent(),
                Value<String?> candidates = const Value.absent(),
                Value<int?> trackId = const Value.absent(),
                Value<double?> score = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistImportItemsCompanion(
                importId: importId,
                rowIndex: rowIndex,
                title: title,
                artists: artists,
                album: album,
                durationMs: durationMs,
                isrc: isrc,
                status: status,
                videoId: videoId,
                candidates: candidates,
                trackId: trackId,
                score: score,
                note: note,
                location: location,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int importId,
                required int rowIndex,
                required String title,
                required String artists,
                Value<String?> album = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<String?> isrc = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<String?> videoId = const Value.absent(),
                Value<String?> candidates = const Value.absent(),
                Value<int?> trackId = const Value.absent(),
                Value<double?> score = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistImportItemsCompanion.insert(
                importId: importId,
                rowIndex: rowIndex,
                title: title,
                artists: artists,
                album: album,
                durationMs: durationMs,
                isrc: isrc,
                status: status,
                videoId: videoId,
                candidates: candidates,
                trackId: trackId,
                score: score,
                note: note,
                location: location,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaylistImportItemsTable, PlaylistImportItem>(
                    table,
                  ),
                  $$PlaylistImportItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({importId = false, trackId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (importId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.importId,
                        referencedTable: $$PlaylistImportItemsTableReferences
                            ._importIdTable(db),
                        referencedColumn: $$PlaylistImportItemsTableReferences
                            ._importIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (trackId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.trackId,
                        referencedTable: $$PlaylistImportItemsTableReferences
                            ._trackIdTable(db),
                        referencedColumn: $$PlaylistImportItemsTableReferences
                            ._trackIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlaylistImportItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaylistImportItemsTable,
      PlaylistImportItem,
      $$PlaylistImportItemsTableFilterComposer,
      $$PlaylistImportItemsTableOrderingComposer,
      $$PlaylistImportItemsTableAnnotationComposer,
      $$PlaylistImportItemsTableCreateCompanionBuilder,
      $$PlaylistImportItemsTableUpdateCompanionBuilder,
      (PlaylistImportItem, $$PlaylistImportItemsTableReferences),
      PlaylistImportItem,
      PrefetchHooks Function({bool importId, bool trackId})
    >;
typedef $$PlaysTableCreateCompanionBuilder = PlaysCompanion Function({
  Value<int> id,
  required int trackId,
  required int playedAt,
  Value<int> msPlayed,
  Value<int?> context,
  Value<String?> contextName,
});
typedef $$PlaysTableUpdateCompanionBuilder = PlaysCompanion Function({
  Value<int> id,
  Value<int> trackId,
  Value<int> playedAt,
  Value<int> msPlayed,
  Value<int?> context,
  Value<String?> contextName,
});

final class $$PlaysTableReferences
    extends BaseReferences<_$AppDatabase, $PlaysTable, Play> {
  $$PlaysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TracksTable _trackIdTable(_$AppDatabase db) =>
      db.tracks.createAlias('plays__track_id__tracks__id');

  $$TracksTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<int>('track_id')!;

    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlaysTableFilterComposer extends Composer<_$AppDatabase, $PlaysTable> {
  $$PlaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get msPlayed => $composableBuilder(
    column: $table.msPlayed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get context => $composableBuilder(
    column: $table.context,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contextName => $composableBuilder(
    column: $table.contextName,
    builder: (column) => ColumnFilters(column),
  );

  $$TracksTableFilterComposer get trackId {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaysTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaysTable> {
  $$PlaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get msPlayed => $composableBuilder(
    column: $table.msPlayed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get context => $composableBuilder(
    column: $table.context,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contextName => $composableBuilder(
    column: $table.contextName,
    builder: (column) => ColumnOrderings(column),
  );

  $$TracksTableOrderingComposer get trackId {
    final $$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableOrderingComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaysTable> {
  $$PlaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get playedAt =>
      $composableBuilder(column: $table.playedAt, builder: (column) => column);

  GeneratedColumn<int> get msPlayed =>
      $composableBuilder(column: $table.msPlayed, builder: (column) => column);

  GeneratedColumn<int> get context =>
      $composableBuilder(column: $table.context, builder: (column) => column);

  GeneratedColumn<String> get contextName => $composableBuilder(
    column: $table.contextName,
    builder: (column) => column,
  );

  $$TracksTableAnnotationComposer get trackId {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaysTable,
          Play,
          $$PlaysTableFilterComposer,
          $$PlaysTableOrderingComposer,
          $$PlaysTableAnnotationComposer,
          $$PlaysTableCreateCompanionBuilder,
          $$PlaysTableUpdateCompanionBuilder,
          (Play, $$PlaysTableReferences),
          Play,
          PrefetchHooks Function({bool trackId})
        > {
  $$PlaysTableTableManager(_$AppDatabase db, $PlaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> trackId = const Value.absent(),
                Value<int> playedAt = const Value.absent(),
                Value<int> msPlayed = const Value.absent(),
                Value<int?> context = const Value.absent(),
                Value<String?> contextName = const Value.absent(),
              }) => PlaysCompanion(
                id: id,
                trackId: trackId,
                playedAt: playedAt,
                msPlayed: msPlayed,
                context: context,
                contextName: contextName,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int trackId,
                required int playedAt,
                Value<int> msPlayed = const Value.absent(),
                Value<int?> context = const Value.absent(),
                Value<String?> contextName = const Value.absent(),
              }) => PlaysCompanion.insert(
                id: id,
                trackId: trackId,
                playedAt: playedAt,
                msPlayed: msPlayed,
                context: context,
                contextName: contextName,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaysTable, Play>(table),
                  $$PlaysTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({trackId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (trackId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.trackId,
                        referencedTable: $$PlaysTableReferences._trackIdTable(
                          db,
                        ),
                        referencedColumn: $$PlaysTableReferences
                            ._trackIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaysTable,
      Play,
      $$PlaysTableFilterComposer,
      $$PlaysTableOrderingComposer,
      $$PlaysTableAnnotationComposer,
      $$PlaysTableCreateCompanionBuilder,
      $$PlaysTableUpdateCompanionBuilder,
      (Play, $$PlaysTableReferences),
      Play,
      PrefetchHooks Function({bool trackId})
    >;
typedef $$SmartPlaylistsTableCreateCompanionBuilder =
    SmartPlaylistsCompanion Function({
      Value<int> id,
      required String name,
      required String rules,
      Value<String?> sort,
      Value<int?> limitCount,
      required int createdAt,
    });
typedef $$SmartPlaylistsTableUpdateCompanionBuilder =
    SmartPlaylistsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> rules,
      Value<String?> sort,
      Value<int?> limitCount,
      Value<int> createdAt,
    });

class $$SmartPlaylistsTableFilterComposer
    extends Composer<_$AppDatabase, $SmartPlaylistsTable> {
  $$SmartPlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rules => $composableBuilder(
    column: $table.rules,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get limitCount => $composableBuilder(
    column: $table.limitCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SmartPlaylistsTableOrderingComposer
    extends Composer<_$AppDatabase, $SmartPlaylistsTable> {
  $$SmartPlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rules => $composableBuilder(
    column: $table.rules,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get limitCount => $composableBuilder(
    column: $table.limitCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SmartPlaylistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SmartPlaylistsTable> {
  $$SmartPlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get rules =>
      $composableBuilder(column: $table.rules, builder: (column) => column);

  GeneratedColumn<String> get sort =>
      $composableBuilder(column: $table.sort, builder: (column) => column);

  GeneratedColumn<int> get limitCount => $composableBuilder(
    column: $table.limitCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SmartPlaylistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SmartPlaylistsTable,
          SmartPlaylist,
          $$SmartPlaylistsTableFilterComposer,
          $$SmartPlaylistsTableOrderingComposer,
          $$SmartPlaylistsTableAnnotationComposer,
          $$SmartPlaylistsTableCreateCompanionBuilder,
          $$SmartPlaylistsTableUpdateCompanionBuilder,
          (
            SmartPlaylist,
            BaseReferences<_$AppDatabase, $SmartPlaylistsTable, SmartPlaylist>,
          ),
          SmartPlaylist,
          PrefetchHooks Function()
        > {
  $$SmartPlaylistsTableTableManager(
    _$AppDatabase db,
    $SmartPlaylistsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SmartPlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SmartPlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SmartPlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> rules = const Value.absent(),
                Value<String?> sort = const Value.absent(),
                Value<int?> limitCount = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => SmartPlaylistsCompanion(
                id: id,
                name: name,
                rules: rules,
                sort: sort,
                limitCount: limitCount,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String rules,
                Value<String?> sort = const Value.absent(),
                Value<int?> limitCount = const Value.absent(),
                required int createdAt,
              }) => SmartPlaylistsCompanion.insert(
                id: id,
                name: name,
                rules: rules,
                sort: sort,
                limitCount: limitCount,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SmartPlaylistsTable, SmartPlaylist>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SmartPlaylistsTable,
                    SmartPlaylist
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SmartPlaylistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SmartPlaylistsTable,
      SmartPlaylist,
      $$SmartPlaylistsTableFilterComposer,
      $$SmartPlaylistsTableOrderingComposer,
      $$SmartPlaylistsTableAnnotationComposer,
      $$SmartPlaylistsTableCreateCompanionBuilder,
      $$SmartPlaylistsTableUpdateCompanionBuilder,
      (
        SmartPlaylist,
        BaseReferences<_$AppDatabase, $SmartPlaylistsTable, SmartPlaylist>,
      ),
      SmartPlaylist,
      PrefetchHooks Function()
    >;
typedef $$UserTagsTableCreateCompanionBuilder = UserTagsCompanion Function({
  Value<int> id,
  required String name,
  Value<int?> color,
});
typedef $$UserTagsTableUpdateCompanionBuilder = UserTagsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int?> color,
});

final class $$UserTagsTableReferences
    extends BaseReferences<_$AppDatabase, $UserTagsTable, UserTag> {
  $$UserTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TrackTagsTable, List<TrackTag>>
  _trackTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.trackTags,
    aliasName: 'user_tags__id__track_tags__tag_id',
  );

  $$TrackTagsTableProcessedTableManager get trackTagsRefs {
    final manager = $$TrackTagsTableTableManager(
      $_db,
      $_db.trackTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_trackTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UserTagsTableFilterComposer
    extends Composer<_$AppDatabase, $UserTagsTable> {
  $$UserTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> trackTagsRefs(
    Expression<bool> Function($$TrackTagsTableFilterComposer f) f,
  ) {
    final $$TrackTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackTagsTableFilterComposer(
            $db: $db,
            $table: $db.trackTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UserTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserTagsTable> {
  $$UserTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserTagsTable> {
  $$UserTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  Expression<T> trackTagsRefs<T extends Object>(
    Expression<T> Function($$TrackTagsTableAnnotationComposer a) f,
  ) {
    final $$TrackTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.trackTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UserTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserTagsTable,
          UserTag,
          $$UserTagsTableFilterComposer,
          $$UserTagsTableOrderingComposer,
          $$UserTagsTableAnnotationComposer,
          $$UserTagsTableCreateCompanionBuilder,
          $$UserTagsTableUpdateCompanionBuilder,
          (UserTag, $$UserTagsTableReferences),
          UserTag,
          PrefetchHooks Function({bool trackTagsRefs})
        > {
  $$UserTagsTableTableManager(_$AppDatabase db, $UserTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int?> color = const Value.absent(),
          }) => UserTagsCompanion(id: id, name: name, color: color),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<int?> color = const Value.absent(),
          }) => UserTagsCompanion.insert(id: id, name: name, color: color),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserTagsTable, UserTag>(table),
                  $$UserTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({trackTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (trackTagsRefs) db.trackTags],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (trackTagsRefs)
                    await $_getPrefetchedData<
                      UserTag,
                      $UserTagsTable,
                      TrackTag
                    >(
                      currentTable: table,
                      referencedTable: $$UserTagsTableReferences
                          ._trackTagsRefsTable(db),
                      managerFromTypedResult: (p0) => $$UserTagsTableReferences(
                        db,
                        table,
                        p0,
                      ).trackTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tagId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$UserTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserTagsTable,
      UserTag,
      $$UserTagsTableFilterComposer,
      $$UserTagsTableOrderingComposer,
      $$UserTagsTableAnnotationComposer,
      $$UserTagsTableCreateCompanionBuilder,
      $$UserTagsTableUpdateCompanionBuilder,
      (UserTag, $$UserTagsTableReferences),
      UserTag,
      PrefetchHooks Function({bool trackTagsRefs})
    >;
typedef $$TrackTagsTableCreateCompanionBuilder = TrackTagsCompanion Function({
  required int trackId,
  required int tagId,
  Value<int> rowid,
});
typedef $$TrackTagsTableUpdateCompanionBuilder = TrackTagsCompanion Function({
  Value<int> trackId,
  Value<int> tagId,
  Value<int> rowid,
});

final class $$TrackTagsTableReferences
    extends BaseReferences<_$AppDatabase, $TrackTagsTable, TrackTag> {
  $$TrackTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TracksTable _trackIdTable(_$AppDatabase db) =>
      db.tracks.createAlias('track_tags__track_id__tracks__id');

  $$TracksTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<int>('track_id')!;

    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $UserTagsTable _tagIdTable(_$AppDatabase db) =>
      db.userTags.createAlias('track_tags__tag_id__user_tags__id');

  $$UserTagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<int>('tag_id')!;

    final manager = $$UserTagsTableTableManager(
      $_db,
      $_db.userTags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TrackTagsTableFilterComposer
    extends Composer<_$AppDatabase, $TrackTagsTable> {
  $$TrackTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$TracksTableFilterComposer get trackId {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UserTagsTableFilterComposer get tagId {
    final $$UserTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.userTags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserTagsTableFilterComposer(
            $db: $db,
            $table: $db.userTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $TrackTagsTable> {
  $$TrackTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$TracksTableOrderingComposer get trackId {
    final $$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableOrderingComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UserTagsTableOrderingComposer get tagId {
    final $$UserTagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.userTags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserTagsTableOrderingComposer(
            $db: $db,
            $table: $db.userTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrackTagsTable> {
  $$TrackTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$TracksTableAnnotationComposer get trackId {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UserTagsTableAnnotationComposer get tagId {
    final $$UserTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.userTags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.userTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrackTagsTable,
          TrackTag,
          $$TrackTagsTableFilterComposer,
          $$TrackTagsTableOrderingComposer,
          $$TrackTagsTableAnnotationComposer,
          $$TrackTagsTableCreateCompanionBuilder,
          $$TrackTagsTableUpdateCompanionBuilder,
          (TrackTag, $$TrackTagsTableReferences),
          TrackTag,
          PrefetchHooks Function({bool trackId, bool tagId})
        > {
  $$TrackTagsTableTableManager(_$AppDatabase db, $TrackTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> trackId = const Value.absent(),
                Value<int> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrackTagsCompanion(
                trackId: trackId,
                tagId: tagId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int trackId,
                required int tagId,
                Value<int> rowid = const Value.absent(),
              }) => TrackTagsCompanion.insert(
                trackId: trackId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TrackTagsTable, TrackTag>(table),
                  $$TrackTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({trackId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (trackId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.trackId,
                        referencedTable: $$TrackTagsTableReferences
                            ._trackIdTable(db),
                        referencedColumn: $$TrackTagsTableReferences
                            ._trackIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (tagId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.tagId,
                        referencedTable: $$TrackTagsTableReferences._tagIdTable(
                          db,
                        ),
                        referencedColumn: $$TrackTagsTableReferences
                            ._tagIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TrackTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrackTagsTable,
      TrackTag,
      $$TrackTagsTableFilterComposer,
      $$TrackTagsTableOrderingComposer,
      $$TrackTagsTableAnnotationComposer,
      $$TrackTagsTableCreateCompanionBuilder,
      $$TrackTagsTableUpdateCompanionBuilder,
      (TrackTag, $$TrackTagsTableReferences),
      TrackTag,
      PrefetchHooks Function({bool trackId, bool tagId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db, _db.tracks);
  $$FoldersTableTableManager get folders =>
      $$FoldersTableTableManager(_db, _db.folders);
  $$PlaylistsTableTableManager get playlists =>
      $$PlaylistsTableTableManager(_db, _db.playlists);
  $$PlaylistTracksTableTableManager get playlistTracks =>
      $$PlaylistTracksTableTableManager(_db, _db.playlistTracks);
  $$PlaylistImportsTableTableManager get playlistImports =>
      $$PlaylistImportsTableTableManager(_db, _db.playlistImports);
  $$PlaylistImportItemsTableTableManager get playlistImportItems =>
      $$PlaylistImportItemsTableTableManager(_db, _db.playlistImportItems);
  $$PlaysTableTableManager get plays =>
      $$PlaysTableTableManager(_db, _db.plays);
  $$SmartPlaylistsTableTableManager get smartPlaylists =>
      $$SmartPlaylistsTableTableManager(_db, _db.smartPlaylists);
  $$UserTagsTableTableManager get userTags =>
      $$UserTagsTableTableManager(_db, _db.userTags);
  $$TrackTagsTableTableManager get trackTags =>
      $$TrackTagsTableTableManager(_db, _db.trackTags);
}
