import 'package:codecore/services/online/yt_dlp_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses plain, build-numbered and padded versions', () {
    expect(parseYtDlpVersion('2024.04.09')!.toString(), '2024.04.09');
    expect(parseYtDlpVersion('2026.08.19\n')!.toString(), '2026.08.19');
    final b = parseYtDlpVersion('2026.08.19.1')!;
    expect(b.build, 1);
    expect(b.toString(), '2026.08.19.1');
  });

  test('rejects text that is not a version', () {
    expect(parseYtDlpVersion(''), isNull);
    expect(parseYtDlpVersion('yt-dlp: command not found'), isNull);
    expect(parseYtDlpVersion('2026.8.1'), isNull);
    expect(parseYtDlpVersion('v2026.08.19'), isNull);
  });

  test('ordering by date then build', () {
    int cmp(String a, String b) =>
        parseYtDlpVersion(a)!.compareTo(parseYtDlpVersion(b)!);
    expect(cmp('2024.04.09', '2026.08.19'), lessThan(0));
    expect(cmp('2026.08.19.1', '2026.08.19'), greaterThan(0));
    expect(cmp('2026.08.19', '2026.08.19'), 0);
    expect(cmp('2025.12.01', '2025.11.30'), greaterThan(0));
  });

  test('outdated only below the minimum and only for real versions', () {
    expect(isYtDlpOutdated('2024.04.09'), isTrue);
    expect(isYtDlpOutdated('2025.11.11'), isTrue);
    expect(isYtDlpOutdated(kMinYtDlpVersion), isFalse);
    expect(isYtDlpOutdated('2026.08.19'), isFalse);
    expect(isYtDlpOutdated(null), isFalse);
    expect(isYtDlpOutdated('garbage'), isFalse);
  });
}
