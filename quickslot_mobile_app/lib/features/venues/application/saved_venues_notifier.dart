import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedVenuesNotifier extends Notifier<Set<String>> {
  static const _key = 'saved_venue_ids';

  @override
  Set<String> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_key);
      if (list != null) {
        state = list.toSet();
      }
    } catch (e) {
      // Silently catch loading error
    }
  }

  Future<void> toggleSaved(String venueId) async {
    final newState = Set<String>.from(state);
    if (newState.contains(venueId)) {
      newState.remove(venueId);
    } else {
      newState.add(venueId);
    }
    state = newState;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, newState.toList());
    } catch (e) {
      // Silently catch save error
    }
  }

  bool isSaved(String venueId) {
    return state.contains(venueId);
  }
}

final savedVenuesProvider = NotifierProvider<SavedVenuesNotifier, Set<String>>(() {
  return SavedVenuesNotifier();
});
