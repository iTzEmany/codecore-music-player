/// `MemTotal` of a `/proc/meminfo` text, in kB; null when absent.
int? memTotalKb(String meminfo) {
  final m = RegExp(r'^MemTotal:\s+(\d+)\s+kB', multiLine: true).firstMatch(meminfo);
  return m == null ? null : int.parse(m.group(1)!);
}

/// Flutter keeps up to 100 MB of decoded images; on a phone with 4 GB or less
/// (the Mi A3) that is too much next to the rest of the app: 48 MB there.
int imageCacheBytes(int? memTotalKb) =>
    memTotalKb != null && memTotalKb <= 4608 * 1024 ? 48 << 20 : 100 << 20;
