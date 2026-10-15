import 'dart:math';

enum PlayRepeat { off, all, one }

/// Pure queue logic. Items are track ids in their natural order; `_order`
/// maps play position -> natural index (identity unless shuffled).
class PlayQueue {
  PlayQueue({Random? random}) : _random = random ?? Random();

  static const _maxHistory = 100;

  final Random _random;
  final List<int> _items = [];
  List<int> _order = [];
  final List<int> _history = []; // natural indices, most recent last
  int _pos = -1;
  bool _shuffle = false;

  PlayRepeat repeat = PlayRepeat.off;

  List<int> get items => List.unmodifiable(_items);
  int get currentIndex => _pos < 0 ? -1 : _order[_pos];
  int? get currentId => _pos < 0 ? null : _items[_order[_pos]];
  bool get isEmpty => _items.isEmpty;
  bool get shuffle => _shuffle;

  /// Ids in the order they will be played.
  List<int> get playOrder => [for (final i in _order) _items[i]];

  set shuffle(bool value) {
    if (value == _shuffle) return;
    _shuffle = value;
    final current = currentIndex;
    _rebuildOrder(current);
  }

  void setItems(List<int> trackIds, {int startIndex = 0}) {
    _items
      ..clear()
      ..addAll(trackIds);
    _history.clear();
    if (_items.isEmpty) {
      _order = [];
      _pos = -1;
      return;
    }
    final start = startIndex.clamp(0, _items.length - 1);
    _rebuildOrder(start);
  }

  void _rebuildOrder(int firstIndex) {
    if (_items.isEmpty) {
      _order = [];
      _pos = -1;
      return;
    }
    final idx = firstIndex < 0 ? 0 : firstIndex;
    if (!_shuffle) {
      _order = List.generate(_items.length, (i) => i);
      _pos = idx;
      return;
    }
    final full = firstIndex < 0;
    final rest = [
      for (var i = 0; i < _items.length; i++)
        if (full || i != idx) i
    ];
    for (var i = rest.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final tmp = rest[i];
      rest[i] = rest[j];
      rest[j] = tmp;
    }
    _order = full ? rest : [idx, ...rest];
    _pos = 0;
  }

  void _pushHistory(int naturalIndex) {
    _history.add(naturalIndex);
    if (_history.length > _maxHistory) _history.removeAt(0);
  }

  /// Whether [next] would land on a track (not past the end).
  bool get hasNext =>
      _pos >= 0 && (_pos + 1 < _order.length || repeat != PlayRepeat.off);

  /// `auto` is true when a track ended by itself.
  int? next({bool auto = false}) {
    if (_pos < 0) return null;
    if (auto && repeat == PlayRepeat.one) return currentId;
    if (_pos + 1 < _order.length) {
      _pushHistory(currentIndex);
      _pos++;
      return currentId;
    }
    if (repeat == PlayRepeat.off) return null;
    _pushHistory(currentIndex);
    if (_shuffle) {
      final last = currentIndex;
      _rebuildOrder(-1);
      // Avoid the same track twice in a row when possible.
      if (_order.length > 1 && _order[0] == last) {
        final swap = _order[1];
        _order[1] = _order[0];
        _order[0] = swap;
      }
      _pos = 0;
    } else {
      _pos = 0;
    }
    return currentId;
  }

  /// Returns the id to play, or null only for an empty queue.
  int? previous() {
    if (_pos < 0) return null;
    if (_history.isNotEmpty) {
      final idx = _history.removeLast();
      final p = _order.indexOf(idx);
      if (p >= 0) _pos = p;
      return currentId;
    }
    if (_pos > 0) {
      _pos--;
    } else if (repeat == PlayRepeat.all) {
      _pos = _order.length - 1;
    }
    return currentId;
  }

  void jumpTo(int index) {
    if (index < 0 || index >= _items.length) return;
    if (_pos >= 0 && currentIndex != index) _pushHistory(currentIndex);
    _pos = _order.indexOf(index);
  }

  /// Returns true when the removed item was the current one (the caller must
  /// load [currentId] again, which now points at the following item).
  bool removeAt(int index) {
    if (index < 0 || index >= _items.length) return false;
    final removedPos = _order.indexOf(index);
    final wasCurrent = removedPos == _pos;
    _items.removeAt(index);
    _order = [
      for (final i in _order)
        if (i != index) i > index ? i - 1 : i
    ];
    _history
      ..removeWhere((i) => i == index)
      ..replaceRange(
          0, _history.length, [for (final i in _history) i > index ? i - 1 : i]);
    if (_items.isEmpty) {
      _pos = -1;
    } else if (removedPos < _pos) {
      _pos--;
    } else if (_pos >= _order.length) {
      _pos = _order.length - 1;
    }
    return wasCurrent;
  }

  /// Moves an item in natural order, keeping the current track playing.
  void move(int from, int to) {
    if (from < 0 || from >= _items.length || to < 0 || to >= _items.length) return;
    if (from == to) return;
    final currentNatural = currentIndex;
    final ids = List<int>.from(_items);
    final moved = ids.removeAt(from);
    ids.insert(to, moved);
    int remap(int i) {
      if (i == from) return to;
      if (from < to && i > from && i <= to) return i - 1;
      if (from > to && i >= to && i < from) return i + 1;
      return i;
    }
    _items
      ..clear()
      ..addAll(ids);
    for (var h = 0; h < _history.length; h++) {
      _history[h] = remap(_history[h]);
    }
    if (_shuffle) {
      _order = [for (final i in _order) remap(i)];
    } else {
      _order = List.generate(_items.length, (i) => i);
    }
    if (currentNatural >= 0) _pos = _order.indexOf(remap(currentNatural));
  }

  void insertNext(int trackId) {
    if (_items.isEmpty) {
      setItems([trackId]);
      return;
    }
    final at = currentIndex + 1;
    _items.insert(at, trackId);
    _order = [for (final i in _order) i >= at ? i + 1 : i];
    for (var h = 0; h < _history.length; h++) {
      if (_history[h] >= at) _history[h]++;
    }
    _order.insert(_pos + 1, at);
  }

  void append(int trackId) {
    if (_items.isEmpty) {
      setItems([trackId]);
      return;
    }
    _items.add(trackId);
    _order.add(_items.length - 1);
  }
}
