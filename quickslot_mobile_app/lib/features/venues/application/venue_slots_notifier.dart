import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/venues_repository.dart';
import '../domain/venue_slot.dart';
import '../../auth/application/auth_notifier.dart';

class VenueSlotsNotifier extends AutoDisposeFamilyAsyncNotifier<List<VenueSlot>, String> {
  @override
  FutureOr<List<VenueSlot>> build(String arg) async {
    final parts = arg.split(':');
    final venueId = parts[0];
    final date = parts[1];
    final slots = await ref.read(venuesRepositoryProvider).getVenueSlots(venueId, date);
    
    final currentUserId = ref.watch(authNotifierProvider).currentUserId;
    return _mapSlots(slots, currentUserId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final parts = arg.split(':');
      final venueId = parts[0];
      final date = parts[1];
      final slots = await ref.read(venuesRepositoryProvider).getVenueSlots(venueId, date);
      
      final currentUserId = ref.read(authNotifierProvider).currentUserId;
      return _mapSlots(slots, currentUserId);
    });
  }

  List<VenueSlot> _mapSlots(List<VenueSlot> slots, String? currentUserId) {
    if (currentUserId == null) return slots;
    return slots.map((slot) {
      if (slot.bookedBy == currentUserId) {
        return slot.copyWith(status: SlotStatus.bookedByMe);
      }
      return slot;
    }).toList();
  }
}

final venueSlotsNotifierProvider =
    AsyncNotifierProvider.autoDispose.family<VenueSlotsNotifier, List<VenueSlot>, String>(() {
  return VenueSlotsNotifier();
});
