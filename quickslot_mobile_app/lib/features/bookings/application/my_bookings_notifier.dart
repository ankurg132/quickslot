import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_notifier.dart';
import '../data/bookings_repository.dart';
import '../../../core/common/exceptions.dart';
import '../domain/booking.dart';

final isOfflineBookingsProvider = StateProvider<bool>((ref) => false);

class MyBookingsNotifier extends AsyncNotifier<List<Booking>> {
  Future<List<Booking>> _fetchBookings(String userId) async {
    try {
      final bookings = await ref.read(bookingsRepositoryProvider).getUserBookings(userId);
      ref.read(isOfflineBookingsProvider.notifier).state = false;
      return bookings;
    } catch (e) {
      if (e is OfflineCacheException) {
        ref.read(isOfflineBookingsProvider.notifier).state = true;
        return e.cachedBookings;
      }
      ref.read(isOfflineBookingsProvider.notifier).state = false;
      rethrow;
    }
  }

  @override
  FutureOr<List<Booking>> build() async {
    final authState = ref.watch(authNotifierProvider);
    final userId = authState.currentUserId;
    if (userId == null) return const [];
    return _fetchBookings(userId);
  }

  Future<void> bookSlot(String venueId, String date, String slotTime) async {
    state = const AsyncLoading();
    try {
      await ref.read(bookingsRepositoryProvider).bookSlot(venueId, date, slotTime);
      final authState = ref.read(authNotifierProvider);
      final bookings = await _fetchBookings(authState.currentUserId!);
      state = AsyncValue.data(bookings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> cancelBooking(int bookingId) async {
    state = const AsyncLoading();
    try {
      await ref.read(bookingsRepositoryProvider).cancelBooking(bookingId);
      final authState = ref.read(authNotifierProvider);
      final bookings = await _fetchBookings(authState.currentUserId!);
      state = AsyncValue.data(bookings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final myBookingsNotifierProvider = AsyncNotifierProvider<MyBookingsNotifier, List<Booking>>(() {
  return MyBookingsNotifier();
});

