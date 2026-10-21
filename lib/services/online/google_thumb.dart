const _googleHosts = {'lh3.googleusercontent.com', 'yt3.googleusercontent.com'};
const _steps = [120, 226, 320, 544];
final _size = RegExp(r'=w\d+-h\d+');

/// Rewrites the size in the address of a Google-hosted picture
/// (`…=w120-h120-p-l90-rj`) to the smallest step (120, 226, 320, 544) that is
/// at least [px] wide, so the image cache reuses a few sizes. Other addresses
/// come back unchanged.
String googleThumbAt(String url, int px) {
  final host = Uri.tryParse(url)?.host;
  if (host == null || !_googleHosts.contains(host)) return url;
  final step = _steps.firstWhere((s) => s >= px, orElse: () => _steps.last);
  return url.replaceFirst(_size, '=w$step-h$step');
}
