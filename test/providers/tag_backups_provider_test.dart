import 'dart:io';

import 'package:codecore/providers/library_providers.dart';
import 'package:codecore/providers/tag_backup_providers.dart';
import 'package:codecore/services/tags/tag_backups.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the backup list follows backups added after it was first read', () async {
    final dir = await Directory.systemTemp.createTemp('tagbak');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/song.mp3')..writeAsStringSync('x');
    final store = TagBackupStore(Directory('${dir.path}/bak'));
    final c = ProviderContainer(
        overrides: [tagBackupStoreProvider.overrideWith((ref) async => store)]);
    addTearDown(c.dispose);
    c.listen(tagBackupsProvider, (_, _) {});

    expect(await c.read(tagBackupsProvider.future), isEmpty);
    await store.add(file.path);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(c.read(tagBackupsProvider).value, hasLength(1));
  });
}
