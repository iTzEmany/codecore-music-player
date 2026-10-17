/// File extensions (the `format` column) that hold lossless audio.
const _lossless = {'flac', 'wav', 'aiff', 'aif', 'alac'};

bool isLosslessFormat(String format) => _lossless.contains(format.toLowerCase());
