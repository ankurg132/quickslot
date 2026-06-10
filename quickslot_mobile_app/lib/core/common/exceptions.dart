import '../../features/bookings/domain/booking.dart';

class SlotAlreadyBookedException implements Exception {
  final String message;
  const SlotAlreadyBookedException([this.message = 'This slot has already been booked by another user.']);

  @override
  String toString() => message;
}

class OfflineCacheException implements Exception {
  final List<Booking> cachedBookings;
  final Object originalError;
  const OfflineCacheException(this.cachedBookings, this.originalError);

  @override
  String toString() => 'OfflineCacheException: Showing cached data due to network error: $originalError';
}
