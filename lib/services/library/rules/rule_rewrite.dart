import 'rule_ast.dart';
import 'rule_parser.dart';

RuleExpr _mapTags(RuleExpr e, String Function(String) f) => switch (e) {
      RuleAnd(:final terms) => RuleAnd([for (final t in terms) _mapTags(t, f)]),
      RuleOr(:final left, :final right) =>
        RuleOr(_mapTags(left, f), _mapTags(right, f)),
      RuleNot(:final inner) => RuleNot(_mapTags(inner, f)),
      RuleContains(:final field, :final value) when field == RuleField.tag =>
        RuleContains(field, f(value)),
      _ => e,
    };

/// [rules] with every `tag:from` (any case) turned into `tag:to`, in canonical
/// form; null when the rules do not mention that tag (nothing to save).
/// Rules cite a tag by its name, so renaming a tag must not break them.
String? renameTagInRules(String rules, String from, String to) {
  final parsed = parseRules(rules).expr;
  var changed = false;
  final mapped = _mapTags(parsed, (v) {
    if (v.toLowerCase() != from.toLowerCase()) return v;
    changed = true;
    return to;
  });
  return changed ? formatRules(mapped) : null;
}
