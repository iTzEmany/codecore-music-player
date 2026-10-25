import '../../l10n/app_localizations.dart';
import '../../providers/shuffle_plus_providers.dart' show ShufflePlusBlock;

String shufflePlusBlockText(AppLocalizations l, ShufflePlusBlock b) => switch (b) {
      ShufflePlusBlock.jam => l.shufflePlusBlockJam,
      ShufflePlusBlock.shortList => l.shufflePlusBlockShort,
      ShufflePlusBlock.noTool => l.shufflePlusBlockNoTool,
      ShufflePlusBlock.metered => l.shufflePlusBlockMetered,
      ShufflePlusBlock.stopped => l.shufflePlusBlockStopped,
      ShufflePlusBlock.online => l.shufflePlusBlockOnline,
      ShufflePlusBlock.radio => l.shufflePlusBlockRadio,
    };
