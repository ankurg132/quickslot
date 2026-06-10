import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_notifier.dart';
import '../data/bookings_repository.dart';
import '../data/bookings_repository_impl.dart'; // To access OfflineCacheException
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
    state = await AsyncValue.guard(() async {
      await ref.read(bookingsRepositoryProvider).bookSlot(venueId, date, slotTime);
      final authState = ref.read(authNotifierProvider);
      return _fetchBookings(authState.currentUserId!);
    });
  }

  Future<void> cancelBooking(int bookingId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(bookingsRepositoryProvider).cancelBooking(bookingId);
      final authState = ref.read(authNotifierProvider);
      return _fetchBookings(authState.currentUserId!);
    });
  }
}

final myBookingsNotifierProvider = AsyncNotifierProvider<MyBookingsNotifier, List<Booking>>(() {
  return MyBookingsNotifier();
});

