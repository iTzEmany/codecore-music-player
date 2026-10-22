/// `MemTotal` of a `/proc/meminfo` text, in kB; null when absent.
int? memTotalKb(String meminfo) {
  final m = RegExp(r'^MemTotal:\s+(\d+)\s+kB', multiLine: true).firstMatch(meminfo);
  return m == null ? null : int.parse(m.group(1)!);
}

/// Flutter keeps up to 100 MB of decoded images, as textures in the graphics
/// memory: on a phone too much next to the rest of the app. 48 MB with 4 GB
/// or less (the Mi A3), 64 MB above (the Motorola edge 40 reached 300 MB of
/// graphics memory): ~110 grid covers or ~900 list thumbnails at 2.75×.
int imageCacheBytes(int? memTotalKb) =>
    memTotalKb != null && memTotalKb <= 4608 * 1024 ? 48 << 20 : 64 << 20;
