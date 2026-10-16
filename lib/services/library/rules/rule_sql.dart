import 'package:drift/drift.dart';

import 'rule_ast.dart';

const _dayMs = 86400000;

/// `%…%` for a LIKE with the special characters of [s] escaped (`\` is the
/// escape character, as in `TrackRepository`).
String likeContains(String s) => '%${s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_')}%';

/// A `WHERE` clause (without the keyword) and its variables, in the order the
/// `?` appear. The text of a rule is **never** pasted into the SQL: only
/// `Variable`s carry it.
typedef RuleSql = ({String where, List<Variable> vars});

/// Turns [e] into SQL on the `tracks` table. Missing tracks are always left
/// out. [nowMs] is the moment «added <30g» counts back from.
RuleSql toSql(RuleExpr e, {required int nowMs}) {
  final vars = <Variable>[];
  final sql = _expr(e, nowMs, vars);
  return (where: 'missing = 0 AND ($sql)', vars: vars);
}

// Every leaf is wrapped so that a NULL column reads as «no» instead of
// «unknown»: that way a negated term keeps the tracks without that tag.
String _leaf(String predicate) => 'COALESCE(($predicate), 0)';

String _expr(RuleExpr e, int now, List<Variable> vars) {
  switch (e) {
    case RuleAnd(:final terms):
      if (terms.isEmpty) return '1';
      return terms.map((t) => '(${_expr(t, now, vars)})').join(' AND ');
    case RuleOr(:final left, :final right):
      final l = _expr(left, now, vars);
      final r = _expr(right, now, vars);
      return '($l) OR ($r)';
    case RuleNot(:final inner):
      return 'NOT (${_expr(inner, now, vars)})';
    case RuleText(:final text):
      final p = likeContains(text);
      vars.addAll([Variable<String>(p), Variable<String>(p), Variable<String>(p)]);
      return _leaf(
        r"title LIKE ? ESCAPE '\' OR COALESCE(artist, '') LIKE ? ESCAPE '\' "
        r"OR COALESCE(album, '') LIKE ? ESCAPE '\'",
      );
    case RuleFlag(:final kind):
      return switch (kind) {
        RuleFlagKind.favorites => 'is_favorite = 1',
        RuleFlagKind.neverPlayed => 'play_count = 0',
      };
    case RuleContains():
      return _contains(e, vars);
    case RuleNumber():
      return _number(e, now, vars);
  }
}

String _contains(RuleContains e, List<Variable> vars) {
  switch (e.field) {
    case RuleField.tag:
      vars.add(Variable<String>(e.value));
      return _leaf(
        'EXISTS (SELECT 1 FROM track_tags tt JOIN user_tags u ON u.id = tt.tag_id '
        'WHERE tt.track_id = tracks.id AND u.name = ? COLLATE NOCASE)',
      );
    case RuleField.format:
      vars.add(Variable<String>(e.value));
      return _leaf('lower(format) = lower(?)');
    default:
      final column = switch (e.field) {
        RuleField.artist => 'artist',
        RuleField.album => 'album',
        RuleField.genre => 'genre',
        _ => 'path', // folder
      };
      vars.add(Variable<String>(likeContains(e.value)));
      return _leaf("COALESCE($column, '') LIKE ? ESCAPE '\\'");
  }
}

String _number(RuleNumber e, int now, List<Variable> vars) {
  if (e.field == RuleField.added) return _added(e, now, vars);
  final column = switch (e.field) {
    RuleField.year => 'year',
    RuleField.plays => 'play_count',
    _ => 'duration_ms', // duration: seconds in the rule, ms in the column
  };
  final scale = e.field == RuleField.duration ? 1000.0 : 1.0;
  Variable v(double x) => e.field == RuleField.duration
      ? Variable<double>(x * scale)
      : Variable<int>(x.round());
  switch (e.op) {
    case NumOp.range:
      final parts = <String>[];
      if (e.a != null) {
        parts.add('$column >= ?');
        vars.add(v(e.a!));
      }
      if (e.b != null) {
        parts.add('$column <= ?');
        vars.add(v(e.b!));
      }
      return _leaf(parts.isEmpty ? '1' : parts.join(' AND '));
    default:
      final op = switch (e.op) {
        NumOp.eq => '=',
        NumOp.gt => '>',
        NumOp.ge => '>=',
        NumOp.lt => '<',
        _ => '<=',
      };
      vars.add(v(e.a!));
      return _leaf('$column $op ?');
  }
}

/// «aggiunto» speaks of age: `<30g` is newer than 30 days, so `added_at` is
/// *after* the moment 30 days ago.
String _added(RuleNumber e, int now, List<Variable> vars) {
  int ago(double days) => now - (days * _dayMs).round();
  switch (e.op) {
    case NumOp.range:
      final parts = <String>[];
      if (e.a != null) {
        parts.add('added_at <= ?'); // at least a days old
        vars.add(Variable<int>(ago(e.a!)));
      }
      if (e.b != null) {
        parts.add('added_at >= ?'); // at most b days old
        vars.add(Variable<int>(ago(e.b!)));
      }
      return _leaf(parts.isEmpty ? '1' : parts.join(' AND '));
    case NumOp.eq:
      vars
        ..add(Variable<int>(ago(e.a!)))
        ..add(Variable<int>(ago(e.a! + 1)));
      return _leaf('added_at <= ? AND added_at > ?');
    case NumOp.lt:
      vars.add(Variable<int>(ago(e.a!)));
      return _leaf('added_at > ?');
    case NumOp.le:
      vars.add(Variable<int>(ago(e.a!)));
      return _leaf('added_at >= ?');
    case NumOp.gt:
      vars.add(Variable<int>(ago(e.a!)));
      return _leaf('added_at < ?');
    case NumOp.ge:
      vars.add(Variable<int>(ago(e.a!)));
      return _leaf('added_at <= ?');
  }
}
