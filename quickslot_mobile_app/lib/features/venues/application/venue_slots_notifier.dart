import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/venues_repository.dart';
import '../domain/venue_slot.dart';

class VenueSlotsNotifier extends AutoDisposeFamilyAsyncNotifier<List<VenueSlot>, String> {
  @override
  FutureOr<List<VenueSlot>> build(String arg) async {
    final parts = arg.split(':');
    final venueId = parts[0];
    final date = parts[1];
    return ref.read(venuesRepositoryProvider).getVenueSlots(venueId, date);
  }

  Future<void> refresh() async {
    // Keep loading state but preserve the old data for pull-to-refresh if needed,
    // or set state to AsyncLoading to show spinner.
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final parts = arg.split(':');
      final venueId = parts[0];
      final date = parts[1];
      return ref.read(venuesRepositoryProvider).getVenueSlots(venueId, date);
    });
  }
}

final venueSlotsNotifierProvider =
    AsyncNotifierProvider.autoDispose.family<VenueSlotsNotifier, List<VenueSlot>, String>(() {
  return VenueSlotsNotifier();
});
