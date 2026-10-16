import 'package:codecore/services/library/rules/rule_rewrite.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a tag cited in the rules is renamed, in canonical form', () {
    expect(renameTagInRules('tag:live', 'live', 'concerti'), 'tag:concerti');
    expect(renameTagInRules('TAG:Live artista:floyd', 'live', 'Dal vivo'), 'tag:"Dal vivo" artista:floyd');
    expect(renameTagInRules('tag:"live set"', 'Live Set', 'x'), 'tag:x');
  });

  test('inside OR and negation too', () {
    expect(renameTagInRules('-tag:live', 'live', 'dal vivo'), '-tag:"dal vivo"');
    expect(renameTagInRules('tag:live OR tag:studio', 'live', 'concerti'), 'tag:concerti OR tag:studio');
    expect(renameTagInRules('rock tag:live anno>1990', 'live', 'l'), 'rock tag:l anno>1990');
  });

  test('other fields and other tags are left alone', () {
    expect(renameTagInRules('artista:live', 'live', 'x'), isNull);
    expect(renameTagInRules('live', 'live', 'x'), isNull);
    expect(renameTagInRules('tag:studio', 'live', 'x'), isNull);
    expect(renameTagInRules('', 'live', 'x'), isNull);
    expect(renameTagInRules('tag:live2', 'live', 'x'), isNull, reason: 'whole name');
  });
}
