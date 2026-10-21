import 'dart:math';

enum PlayRepeat { off, all, one }

/// The queue as it was, to put it back (the undo of «Svuota»).
class QueueState {
  const QueueState._(this._items, this._order, this._pos, this._history);

  final List<int> _items, _order, _history;
  final int _pos;

  int? get currentId => _pos < 0 ? null : _items[_order[_pos]];
}

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
  PlayRepeat _repeat = PlayRepeat.off;
  int _revision = 0;

  /// The shuffled order the next wrap-around will use, fixed in advance by
  /// [peekNext] so that [next] lands on the very track that was announced.
  List<int>? _pendingOrder;

  PlayRepeat get repeat => _repeat;
  set repeat(PlayRepeat value) {
    if (value == _repeat) return;
    _repeat = value;
    _changed();
  }

  /// Grows with every change to the queue (items, order, position, modes), so
  /// whoever prepared «the next track» knows when to prepare it again.
  int get revision => _revision;

  void _changed() {
    _pendingOrder = null;
    _revision++;
  }

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
    _changed();
  }

  void setItems(List<int> trackIds, {int startIndex = 0}) {
    _items
      ..clear()
      ..addAll(trackIds);
    _history.clear();
    _changed();
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
        if (full || i != idx) i,
    ];
    _shuffleInPlace(rest);
    _order = full ? rest : [idx, ...rest];
    _pos = 0;
  }

  void _shuffleInPlace(List<int> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }

  /// A fresh shuffle of every item for the next lap, never starting with the
  /// track that just played when there is a choice.
  List<int> _newLapOrder() {
    final order = List<int>.generate(_items.length, (i) => i);
    _shuffleInPlace(order);
    if (order.length > 1 && order[0] == currentIndex) {
      final swap = order[1];
      order[1] = order[0];
      order[0] = swap;
    }
    return order;
  }

  void _pushHistory(int naturalIndex) {
    _history.add(naturalIndex);
    if (_history.length > _maxHistory) _history.removeAt(0);
  }

  /// Whether [next] would land on a track (not past the end).
  bool get hasNext =>
      _pos >= 0 && (_pos + 1 < _order.length || repeat != PlayRepeat.off);

  /// The id [next] would return with the same [auto], without changing the
  /// queue, the history or the revision. At the end of a shuffled lap with
  /// repeat-all it fixes the next lap's order, so [next] agrees with it.
  int? peekNext({bool auto = true}) {
    if (_pos < 0) return null;
    if (auto && repeat == PlayRepeat.one) return currentId;
    if (_pos + 1 < _order.length) return _items[_order[_pos + 1]];
    if (repeat == PlayRepeat.off) return null;
    if (!_shuffle) return _items[_order[0]];
    return _items[(_pendingOrder ??= _newLapOrder())[0]];
  }

  /// `auto` is true when a track ended by itself.
  int? next({bool auto = false}) {
    if (_pos < 0) return null;
    if (auto && repeat == PlayRepeat.one) return currentId;
    if (_pos + 1 < _order.length) {
      _pushHistory(currentIndex);
      _pos++;
      _changed();
      return currentId;
    }
    if (repeat == PlayRepeat.off) return null;
    _pushHistory(currentIndex);
    if (_shuffle) {
      _order = _pendingOrder ?? _newLapOrder();
    }
    _pos = 0;
    _changed();
    return currentId;
  }

  /// Returns the id to play, or null only for an empty queue.
  int? previous() {
    if (_pos < 0) return null;
    _changed();
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
    _changed();
  }

  /// Returns true when the removed item was the current one (the caller must
  /// load [currentId] again, which now points at the following item).
  bool removeAt(int index) {
    if (index < 0 || index >= _items.length) return false;
    _changed();
    final removedPos = _order.indexOf(index);
    final wasCurrent = removedPos == _pos;
    _items.removeAt(index);
    _order = [
      for (final i in _order)
        if (i != index) i > index ? i - 1 : i,
    ];
    _history
      ..removeWhere((i) => i == index)
      ..replaceRange(0, _history.length, [
        for (final i in _history) i > index ? i - 1 : i,
      ]);
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
    _changed();
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

  /// What follows the current track, built again from [source] (the list
  /// playback started from): in order from the current track on or, with
  /// shuffle, a fresh shuffle of the whole list, kept in the queue's own order
  /// so the queue shows what will play. Without [source] it is just dropped.
  /// The current track stays; the history goes (it pointed into old items).
  void rebuildUpcoming(List<int>? source) {
    final current = currentId;
    if (current == null) return;
    final from = source ?? const <int>[];
    final at = from.indexOf(current);
    final List<int> ids;
    var pos = 0;
    if (from.isEmpty) {
      ids = [current];
    } else if (_shuffle) {
      final rest = [...from];
      if (at >= 0) rest.removeAt(at);
      _shuffleInPlace(rest);
      ids = [current, ...rest];
    } else if (at >= 0) {
      ids = [...from];
      pos = at;
    } else {
      ids = [current, ...from];
    }
    _items
      ..clear()
      ..addAll(ids);
    _order = List.generate(_items.length, (i) => i);
    _pos = pos;
    _history.clear();
    _changed();
  }

  QueueState saveState() =>
      QueueState._(List.of(_items), List.of(_order), _pos, List.of(_history));

  /// Puts [state] back, only while the same track plays; false otherwise.
  bool restoreState(QueueState state) {
    if (state.currentId == null || state.currentId != currentId) return false;
    _items
      ..clear()
      ..addAll(state._items);
    _order = List.of(state._order);
    _pos = state._pos;
    _history
      ..clear()
      ..addAll(state._history);
    _changed();
    return true;
  }

  void insertNext(int trackId) {
    if (_items.isEmpty) {
      setItems([trackId]);
      return;
    }
    _changed();
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
    _changed();
    _items.add(trackId);
    _order.add(_items.length - 1);
  }
}
