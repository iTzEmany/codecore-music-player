import 'dart:math';

import 'package:codecore/services/jam/jam_suggestion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final pool = {
    'rock': ['r1', 'r2', 'r3'],
    'jazz': ['j1'],
    null: ['r1', 'r2', 'r3', 'j1', 'x1'],
  };
  Future<List<String>> cand(String? g) async => pool[g] ?? const [];
  Future<String?> pick(Map<String, int> w, Random r, {bool Function(String)? played}) =>
      pickSuggestion<String>(
          genreWeights: w, candidates: cand, random: r, isPlayed: played ?? (_) => false);

  test('genres are drawn by weight (fixed seed)', () async {
    final r = Random(7);
    var rock = 0, jazz = 0;
    for (var i = 0; i < 400; i++) {
      final t = (await pick({'rock': 3, 'jazz': 1}, r))!;
      t.startsWith('r') ? rock++ : jazz++;
    }
    expect(rock, inInclusiveRange(270, 330)); // 3:1
    expect(jazz, greaterThan(0));
  });

  test('played tracks are never suggested; a genre left empty is skipped', () async {
    final r = Random(1);
    for (var i = 0; i < 50; i++) {
      expect(await pick({'rock': 1, 'jazz': 1}, r, played: (t) => t.startsWith('r')), 'j1');
    }
  });

  test('no usable genre falls back to any library track; none at all gives null', () async {
    expect(await pick({'blues': 5}, Random(1), played: (t) => t != 'x1'), 'x1');
    expect(await pick({}, Random(1)), isNotNull);
    expect(await pick({'rock': 1}, Random(1), played: (_) => true), isNull);
    expect(
        await pickSuggestion<String>(
            genreWeights: const {},
            candidates: (_) async => const [],
            random: Random(1),
            isPlayed: (_) => false),
        isNull);
  });

  test('same song by title and artist, case blind', () {
    expect(suggestionKey(' Hello ', 'ADELE'), suggestionKey('hello', 'adele '));
    expect(suggestionKey('a', null), isNot(suggestionKey('a', 'b')));
  });

  test('weights that are all zero fall back without drawing from nothing', () async {
    expect(await pick({'rock': 0, 'jazz': 0}, Random(1)), isNotNull);
  });
}
