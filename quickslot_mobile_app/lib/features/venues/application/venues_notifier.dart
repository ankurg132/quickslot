import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/venues_repository.dart';
import '../domain/venue.dart';

class VenuesNotifier extends AsyncNotifier<List<Venue>> {
  @override
  FutureOr<List<Venue>> build() async {
    return ref.read(venuesRepositoryProvider).getVenues();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(venuesRepositoryProvider).getVenues());
  }
}

final venuesNotifierProvider = AsyncNotifierProvider<VenuesNotifier, List<Venue>>(() {
  return VenuesNotifier();
});
