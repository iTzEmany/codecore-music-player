const _prefix = 'stream:';

/// Library path of a streamed track's shadow row.
String streamPathOf(String key) => '$_prefix$key';

/// The cache key of a `stream:<key>` path, or null for any other path.
String? keyOfStreamPath(String path) =>
    path.startsWith(_prefix) ? path.substring(_prefix.length) : null;

/// File name of [key] inside the cache folder.
String streamFileName(String key) => key.replaceAll(':', '_');
