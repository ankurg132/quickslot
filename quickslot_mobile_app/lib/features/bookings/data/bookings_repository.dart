import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/booking.dart';
import 'bookings_repository_impl.dart';
import '../../../core/network/api_client.dart';

abstract class BookingsRepository {
  Future<List<Booking>> getUserBookings(String userId);
  Future<void> bookSlot(String venueId, String date, String slotTime);
  Future<void> cancelBooking(int bookingId);
}

final bookingsRepositoryProvider = Provider<BookingsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return BookingsRepositoryImpl(dio);
});
