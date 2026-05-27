import 'package:shared_preferences/shared_preferences.dart';

abstract class SearchHistoryStore {
  Future<List<String>> load();

  Future<void> save(List<String> items);
}

class SharedPreferencesSearchHistoryStore implements SearchHistoryStore {
  SharedPreferencesSearchHistoryStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _key = 'twc_search_history';

  @override
  Future<List<String>> load() async {
    final values = _prefs.getStringList(_key);
    return List<String>.unmodifiable(values ?? const <String>[]);
  }

  @override
  Future<void> save(List<String> items) async {
    await _prefs.setStringList(_key, items);
  }
}

class InMemorySearchHistoryStore implements SearchHistoryStore {
  InMemorySearchHistoryStore([List<String> initialItems = const <String>[]])
    : _items = List<String>.from(initialItems);

  final List<String> _items;

  @override
  Future<List<String>> load() async {
    return List<String>.unmodifiable(_items);
  }

  @override
  Future<void> save(List<String> items) async {
    _items
      ..clear()
      ..addAll(items);
  }
}
