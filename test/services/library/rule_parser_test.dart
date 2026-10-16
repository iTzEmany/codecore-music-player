import 'package:codecore/services/library/rules/rule_ast.dart';
import 'package:codecore/services/library/rules/rule_parser.dart';
import 'package:flutter_test/flutter_test.dart';

RuleExpr p(String text) => parseRules(text).expr;
List<RuleWarning> w(String text) => parseRules(text).warnings;

void main() {
  group('plain words', () {
    test('one word is free text', () {
      expect(p('floyd'), const RuleText('floyd'));
      expect(w('floyd'), isEmpty);
    });

    test('several words are all required', () {
      expect(p('pink floyd'), const RuleAnd([RuleText('pink'), RuleText('floyd')]));
    });

    test('a quoted phrase is one term', () {
      expect(p('"pink floyd"'), const RuleText('pink floyd'));
    });

    test('empty text matches everything', () {
      expect(p(''), const RuleAnd([]));
      expect(p('   '), const RuleAnd([]));
      expect(w(''), isEmpty);
    });
  });

  group('fields', () {
    test('text fields, Italian and English names, any case', () {
      expect(p('artista:floyd'), const RuleContains(RuleField.artist, 'floyd'));
      expect(p('artist:floyd'), const RuleContains(RuleField.artist, 'floyd'));
      expect(p('ARTISTA:Floyd'), const RuleContains(RuleField.artist, 'Floyd'));
      expect(p('album:wall'), const RuleContains(RuleField.album, 'wall'));
      expect(p('genere:rock'), const RuleContains(RuleField.genre, 'rock'));
      expect(p('genre:rock'), const RuleContains(RuleField.genre, 'rock'));
      expect(p('cartella:jazz'), const RuleContains(RuleField.folder, 'jazz'));
      expect(p('folder:jazz'), const RuleContains(RuleField.folder, 'jazz'));
    });

    test('tag and format are matched whole', () {
      expect(const RuleContains(RuleField.tag, 'live').exact, isTrue);
      expect(const RuleContains(RuleField.format, 'flac').exact, isTrue);
      expect(const RuleContains(RuleField.artist, 'x').exact, isFalse);
      expect(p('tag:live'), const RuleContains(RuleField.tag, 'live'));
      expect(p('formato:flac'), const RuleContains(RuleField.format, 'flac'));
    });

    test('quoted values keep their spaces', () {
      expect(p('artista:"pink floyd"'), const RuleContains(RuleField.artist, 'pink floyd'));
      expect(p('album:"The Wall" rock'),
          const RuleAnd([RuleContains(RuleField.album, 'The Wall'), RuleText('rock')]));
    });

    test('the keywords', () {
      expect(p('preferiti'), const RuleFlag(RuleFlagKind.favorites));
      expect(p('favorites'), const RuleFlag(RuleFlagKind.favorites));
      expect(p('mai-ascoltati'), const RuleFlag(RuleFlagKind.neverPlayed));
      expect(p('never-played'), const RuleFlag(RuleFlagKind.neverPlayed));
    });
  });

  group('numbers', () {
    test('a year, a range, open ranges', () {
      expect(p('anno:1990'), const RuleNumber(RuleField.year, NumOp.eq, 1990));
      expect(p('anno:1990..1999'), const RuleNumber(RuleField.year, NumOp.range, 1990, 1999));
      expect(p('anno:..1980'), const RuleNumber(RuleField.year, NumOp.range, null, 1980));
      expect(p('anno:2000..'), const RuleNumber(RuleField.year, NumOp.range, 2000, null));
      expect(p('year:1990..1999'), const RuleNumber(RuleField.year, NumOp.range, 1990, 1999));
    });

    test('comparisons', () {
      expect(p('anno>1990'), const RuleNumber(RuleField.year, NumOp.gt, 1990));
      expect(p('anno>=1990'), const RuleNumber(RuleField.year, NumOp.ge, 1990));
      expect(p('anno<1990'), const RuleNumber(RuleField.year, NumOp.lt, 1990));
      expect(p('anno<=1990'), const RuleNumber(RuleField.year, NumOp.le, 1990));
      expect(p('ascolti>10'), const RuleNumber(RuleField.plays, NumOp.gt, 10));
      expect(p('plays:0'), const RuleNumber(RuleField.plays, NumOp.eq, 0));
    });

    test('the length in minutes (the default) or seconds', () {
      expect(p('durata>5m'), const RuleNumber(RuleField.duration, NumOp.gt, 300));
      expect(p('durata<90s'), const RuleNumber(RuleField.duration, NumOp.lt, 90));
      expect(p('durata>5'), const RuleNumber(RuleField.duration, NumOp.gt, 300), reason: 'bare = minutes');
      expect(p('durata:2m..4m'), const RuleNumber(RuleField.duration, NumOp.range, 120, 240));
      expect(p('duration<1.5m'), const RuleNumber(RuleField.duration, NumOp.lt, 90));
    });

    test('how long ago it was added: days, weeks, months', () {
      expect(p('aggiunto<30g'), const RuleNumber(RuleField.added, NumOp.lt, 30));
      expect(p('aggiunto<30'), const RuleNumber(RuleField.added, NumOp.lt, 30));
      expect(p('aggiunto<2sett'), const RuleNumber(RuleField.added, NumOp.lt, 14));
      expect(p('aggiunto>6mesi'), const RuleNumber(RuleField.added, NumOp.gt, 180));
      expect(p('added:7g..30g'), const RuleNumber(RuleField.added, NumOp.range, 7, 30));
    });
  });

  group('negation and OR', () {
    test('a minus negates one term', () {
      expect(p('-live'), const RuleNot(RuleText('live')));
      expect(p('-artista:floyd'), const RuleNot(RuleContains(RuleField.artist, 'floyd')));
      expect(p('-"live at"'), const RuleNot(RuleText('live at')));
      expect(p('rock -live'), const RuleAnd([RuleText('rock'), RuleNot(RuleText('live'))]));
    });

    test('OR joins two terms, tighter than the implicit AND', () {
      expect(p('rock OR jazz'), const RuleOr(RuleText('rock'), RuleText('jazz')));
      expect(
        p('anno:1990..1999 genere:rock OR genere:jazz'),
        const RuleAnd([
          RuleNumber(RuleField.year, NumOp.range, 1990, 1999),
          RuleOr(RuleContains(RuleField.genre, 'rock'), RuleContains(RuleField.genre, 'jazz')),
        ]),
      );
    });

    test('a lowercase «or» is just a word', () {
      expect(p('rock or jazz'),
          const RuleAnd([RuleText('rock'), RuleText('or'), RuleText('jazz')]));
    });

    test('a dangling OR is reported and ignored', () {
      expect(p('OR rock'), const RuleText('rock'));
      expect(w('OR rock').single.kind, RuleWarningKind.danglingOr);
      expect(p('rock OR'), const RuleText('rock'));
      expect(w('rock OR').single.kind, RuleWarningKind.danglingOr);
    });
  });

  group('never throws: bad terms become words and warnings', () {
    test('an unknown field is plain text', () {
      expect(p('colore:rosso'), const RuleText('colore:rosso'));
      expect(w('colore:rosso').single.kind, RuleWarningKind.unknownField);
    });

    test('a number that is not one', () {
      expect(p('anno:abc'), const RuleText('anno:abc'));
      expect(w('anno:abc').single.kind, RuleWarningKind.badNumber);
    });

    test('a wrong unit', () {
      expect(w('anno:1990g').single.kind, RuleWarningKind.badUnit);
      expect(w('durata>5x').single.kind, RuleWarningKind.badUnit);
      expect(w('aggiunto<3anni').single.kind, RuleWarningKind.badUnit);
    });

    test('a broken range', () {
      expect(w('anno:..').single.kind, RuleWarningKind.badRange);
      expect(w('anno:1999..1990').single.kind, RuleWarningKind.badRange);
      expect(w('anno:1..2..3').single.kind, RuleWarningKind.badRange);
    });

    test('a comparison on a text field', () {
      expect(p('artista>floyd'), const RuleText('artista>floyd'));
      expect(w('artista>floyd'), isNotEmpty);
    });

    test('a field with nothing after it (still typing) is skipped, with a warning', () {
      expect(p('artista:'), const RuleAnd([]));
      expect(w('artista:').single.kind, RuleWarningKind.emptyValue);
      expect(p('rock anno:'), const RuleText('rock'));
    });

    test('an unterminated quote runs to the end', () {
      expect(p('artista:"pink flo'), const RuleContains(RuleField.artist, 'pink flo'));
      expect(p('"pink'), const RuleText('pink'));
    });

    test('odd input never throws', () {
      for (final s in ['-', '--', '""', ':', '::', '..', 'a:b:c', '"', '-"', 'OR OR', 'anno:..2000..', '\t\n', '😀:😀']) {
        expect(() => parseRules(s), returnsNormally, reason: s);
      }
    });
  });

  group('operators or plain words', () {
    test('plain words have none, anything else does', () {
      expect(hasOperators('pink floyd'), isFalse);
      expect(hasOperators('"pink floyd"'), isFalse);
      expect(hasOperators('colore:rosso'), isFalse, reason: 'unknown field is text');
      expect(hasOperators('artista:floyd'), isTrue);
      expect(hasOperators('-live'), isTrue);
      expect(hasOperators('rock OR jazz'), isTrue);
      expect(hasOperators('preferiti'), isTrue);
      expect(hasOperators('anno>1990'), isTrue);
      expect(hasOperators(''), isFalse);
    });
  });

  group('formatting', () {
    test('canonical text uses the Italian names', () {
      expect(formatRules(p('artist:floyd year:1970..1979')), 'artista:floyd anno:1970..1979');
      expect(formatRules(p('durata>300s')), 'durata>5m');
      expect(formatRules(p('durata<90s')), 'durata<90s');
      expect(formatRules(p('aggiunto<2sett')), 'aggiunto<14g');
      expect(formatRules(p('favorites')), 'preferiti');
    });

    test('values with spaces are quoted again', () {
      expect(formatRules(p('artista:"pink floyd"')), 'artista:"pink floyd"');
      expect(formatRules(p('"pink floyd"')), '"pink floyd"');
      expect(formatRules(p('-"live at"')), '-"live at"');
    });

    test('parse → format → parse gives the same tree, for many rules', () {
      for (final s in [
        'floyd',
        'pink floyd -live',
        'artista:"pink floyd" -live anno:1970..1979',
        'anno:..1980',
        'anno:2000..',
        'durata:2m..4m aggiunto<30g',
        'rock OR jazz',
        'genere:rock OR genere:jazz anno>=1990',
        'tag:live formato:flac preferiti',
        'mai-ascoltati ascolti:0',
        '-tag:live -"quel brano"',
        'cartella:"Musica/Jazz" album:"The Wall"',
        'OR',
        'artista: anno:abc',
      ]) {
        final once = p(s);
        final text = formatRules(once);
        expect(p(text), once, reason: '$s → $text');
        expect(formatRules(p(text)), text, reason: 'stable: $s');
      }
    });
  });
}
