class ApiRoutes {
  /// GET /venues
  static const String venues = '/venues';

  /// GET /venues/{id}/slots
  static String venueSlots(String venueId) => '/venues/$venueId/slots';

  /// GET /users/{id}/bookings
  static String userBookings(String userId) => '/users/$userId/bookings';

  /// POST /bookings
  static const String bookings = '/bookings';

  /// DELETE /bookings/{id}
  static String cancelBooking(int bookingId) => '/bookings/$bookingId';
}
