import '../../l10n/app_localizations.dart';

enum CreditGroup { performers, writers, production, other }

typedef _Label = String Function(AppLocalizations);

/// Normalized (lower-case) role as saved by `parseDeezerContributors` /
/// `parseMbCredits` -> group and translated label. Unknown roles fall back to
/// the raw text in [CreditGroup.other].
final Map<String, (CreditGroup, _Label)> _roles = {
  for (final r in ['vocal', 'vocals', 'lead vocals', 'singer'])
    r: (CreditGroup.performers, (l) => l.creditRoleVocals),
  for (final r in ['background vocals', 'backing vocals'])
    r: (CreditGroup.performers, (l) => l.creditRoleBackingVocals),
  'guitar': (CreditGroup.performers, (l) => l.creditRoleGuitar),
  for (final r in ['bass guitar', 'bass'])
    r: (CreditGroup.performers, (l) => l.creditRoleBassGuitar),
  'drums': (CreditGroup.performers, (l) => l.creditRoleDrums),
  for (final r in ['keyboard', 'keyboards'])
    r: (CreditGroup.performers, (l) => l.creditRoleKeyboard),
  'piano': (CreditGroup.performers, (l) => l.creditRolePiano),
  'synthesizer': (CreditGroup.performers, (l) => l.creditRoleSynthesizer),
  'composer': (CreditGroup.writers, (l) => l.creditRoleComposer),
  for (final r in ['author', 'writer'])
    r: (CreditGroup.writers, (l) => l.creditRoleAuthor),
  'lyricist': (CreditGroup.writers, (l) => l.creditRoleLyricist),
  'arranger': (CreditGroup.writers, (l) => l.creditRoleArranger),
  'producer': (CreditGroup.production, (l) => l.creditRoleProducer),
  'additionalproducer':
      (CreditGroup.production, (l) => l.creditRoleAdditionalProducer),
  for (final r in ['mix', 'mixer', 'mixingengineer'])
    r: (CreditGroup.production, (l) => l.creditRoleMix),
  for (final r in ['mastering', 'masteringengineer'])
    r: (CreditGroup.production, (l) => l.creditRoleMastering),
  for (final r in ['recording', 'recordingengineer'])
    r: (CreditGroup.production, (l) => l.creditRoleRecording),
  'engineer': (CreditGroup.production, (l) => l.creditRoleEngineer),
  for (final r in ['programming', 'programmer'])
    r: (CreditGroup.production, (l) => l.creditRoleProgramming),
  'drumprogrammer': (CreditGroup.production, (l) => l.creditRoleDrumProgrammer),
  'musicpublisher': (CreditGroup.other, (l) => l.creditRoleMusicPublisher),
};

CreditGroup creditGroup(String role) =>
    _roles[role]?.$1 ?? CreditGroup.other;

String creditRoleLabel(AppLocalizations l10n, String role) =>
    _roles[role]?.$2(l10n) ?? role.replaceAll('_', ' ');

String creditGroupTitle(AppLocalizations l10n, CreditGroup g) => switch (g) {
      CreditGroup.performers => l10n.creditsGroupPerformers,
      CreditGroup.writers => l10n.creditsGroupWriters,
      CreditGroup.production => l10n.creditsGroupProduction,
      CreditGroup.other => l10n.creditsGroupOther,
    };
