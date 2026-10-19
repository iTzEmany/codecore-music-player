import '../../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import 'package:flutter/painting.dart' show Color;
import '../../widgets/color_picker.dart';

String tokenLabel(AppLocalizations l, CcToken t) => switch (t) {
  CcToken.bg => l.tokenBg,
  CcToken.surface1 => l.tokenSurface1,
  CcToken.surface2 => l.tokenSurface2,
  CcToken.surface3 => l.tokenSurface3,
  CcToken.accent => l.tokenAccent,
  CcToken.accentSoft => l.tokenAccentSoft,
  CcToken.onAccent => l.tokenOnAccent,
  CcToken.text => l.tokenText,
  CcToken.textMuted => l.tokenTextMuted,
  CcToken.textFaint => l.tokenTextFaint,
  CcToken.heroBase => l.tokenHero,
  CcToken.error => l.tokenError,
};

Color tokenColor(CcColors c, CcToken t) => switch (t) {
  CcToken.bg => c.bg,
  CcToken.surface1 => c.surface1,
  CcToken.surface2 => c.surface2,
  CcToken.surface3 => c.surface3,
  CcToken.accent => c.accent,
  CcToken.accentSoft => c.accentSoft,
  CcToken.onAccent => c.onAccent,
  CcToken.text => c.text,
  CcToken.textMuted => c.textMuted,
  CcToken.textFaint => c.textFaint,
  CcToken.heroBase => c.heroBase,
  CcToken.error => c.error,
};

CcColorPickerLabels pickerLabels(AppLocalizations l) => CcColorPickerLabels(
  hue: l.pickerHue,
  saturationValue: l.pickerSv,
  alpha: l.pickerAlpha,
  hex: l.pickerHex,
  invalidHex: l.pickerInvalid,
  recent: l.pickerRecent,
);

