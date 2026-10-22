import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/l10n/app_localizations_it.dart';
import 'package:codecore/services/android/release_notifier.dart';
import 'package:codecore/services/online/ytm_artist.dart';
import 'package:codecore/services/releases/release_checker.dart';
import 'package:codecore/services/releases/release_diff.dart';
import 'package:codecore/services/releases/release_notification_text.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

FreshRelease fresh(String artist, String title, {bool muted = false}) => FreshRelease(
      FollowedArtist(
        ytmId: 'UC$artist',
        name: artist,
        origin: 0,
        excluded: false,
        muted: muted,
        followedAt: 0,
        checksFailed: 0,
      ),
      NewRelease(
        release: YtmRelease(browseId: 'MPREb_$title', title: title, subtitle: '2026'),
        kind: ReleaseKind.album,
        year: 2026,
        groupKey: title,
      ),
    );

void main() {
  final l = AppLocalizationsIt();

  test('one release says its title and artist', () {
    final t = releaseNotificationText([fresh('Lucio Corsi', 'Volevo essere un duro')], l)!;
    expect(t.title, 'Nuove uscite');
    expect(t.body, 'Nuova uscita: Volevo essere un duro di Lucio Corsi');
  });

  test('several releases of one or two artists name them', () {
    expect(releaseNotificationText([fresh('A', 'x'), fresh('A', 'y')], l)!.body, '2 nuove uscite: A');
    expect(releaseNotificationText([fresh('A', 'x'), fresh('B', 'y')], l)!.body, '2 nuove uscite: A e B');
  });

  test('five releases name two artists and count the others', () {
    final five = [
      fresh('A', '1'),
      fresh('B', '2'),
      fresh('C', '3'),
      fresh('C', '4'),
      fresh('D', '5'),
    ];
    expect(releaseNotificationText(five, l)!.body, '5 nuove uscite: A, B e altri 2');
  });

  test('muted artists are left out; nothing is said when all are muted', () {
    final some = [fresh('A', 'x', muted: true), fresh('B', 'y')];
    expect(releaseNotificationText(some, l)!.body, 'Nuova uscita: y di B');
    expect(releaseNotificationText([fresh('A', 'x', muted: true)], l), isNull);
  });

  test('the hook posts the words in the app language through the channel', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('codecore/notify');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (c) async {
      calls.add(c);
      return true;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final hook = releaseNotifyHookFor(ReleaseNotifier(channel: channel), () => 'en');
    await hook([fresh('Lucio Corsi', 'Volevo essere un duro')]);
    expect(calls.single.method, 'showReleases');
    expect(calls.single.arguments, {
      'title': 'New releases',
      'body': 'New release: Volevo essere un duro by Lucio Corsi',
      'channelName': 'New releases',
      'actionLabel': 'Show',
    });
  });

  test('a tap that opened the app is read once from the channel', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('codecore/notify');
    String? target = 'releases';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (c) async {
      final t = target;
      target = null;
      return t;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final n = ReleaseNotifier(channel: channel);
    expect(await n.takeLaunchTarget(), 'releases');
    expect(await n.takeLaunchTarget(), isNull);
  });
}
