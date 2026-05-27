import 'package:flutter/foundation.dart';

import 'search_history_store.dart';

class SearchHistoryController extends ChangeNotifier {
  SearchHistoryController(this._store);

  final SearchHistoryStore _store;

  static const int maxItems = 5;

  bool _isLoading = false;
  List<String> _items = const <String>[];

  bool get isLoading => _isLoading;
  List<String> get items => List<String>.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    _items = await _store.load();
    _items = _normalize(_items);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> record(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return;
    }

    final next = <String>[
      normalized,
      ..._items.where((item) => item != normalized),
    ];
    _items = next.take(maxItems).toList(growable: false);
    notifyListeners();
    await _store.save(_items);
  }

  List<String> _normalize(List<String> items) {
    final normalized = <String>[];
    for (final item in items) {
      final value = item.trim();
      if (value.isEmpty || normalized.contains(value)) {
        continue;
      }
      normalized.add(value);
      if (normalized.length == maxItems) {
        break;
      }
    }
    return normalized;
  }
}
