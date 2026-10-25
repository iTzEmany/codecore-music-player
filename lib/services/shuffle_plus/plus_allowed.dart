import '../audio/online_entries.dart';
import 'shuffle_plus_controller.dart';

/// Why Shuffle+ is not suggesting right now (null: it is, or it is off).
enum ShufflePlusBlock { jam, shortList, noTool, metered, stopped, online, radio }

/// Null when the shuffle button may reach Shuffle+, else why not (R-25).
/// An empty queue allows it: nothing plays yet and the Home picks the mode before Play.
/// noTool / metered / stopped do not count: Shuffle+ stays chosen and waits.
ShufflePlusBlock? plusAllowed({
  required List<int> queueIds,
  required bool jam,
  required bool radio,
  required int localCount,
}) {
  if (jam) {
    return ShufflePlusBlock.jam;
  }
  if (radio) {
    return ShufflePlusBlock.radio;
  }
  if (queueIds.isEmpty) {
    return null;
  }
  if (queueIds.every(isOnlineId)) {
    return ShufflePlusBlock.online;
  }
  if (localCount < ShufflePlusController.minSourceSize) {
    return ShufflePlusBlock.shortList;
  }
  return null;
}
