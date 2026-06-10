import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/booking.dart';
import 'bookings_repository.dart';

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

class BookingsRepositoryImpl implements BookingsRepository {
  final Dio _dio;

  BookingsRepositoryImpl(this._dio);

  @override
  Future<List<Booking>> getUserBookings(String userId) async {
    final cacheKey = 'user_bookings_$userId';
    try {
      final response = await _dio.get('/users/$userId/bookings');
      
      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data as Map<String, dynamic>)['bookings'] as List;

      final bookings = data.map((json) => Booking.fromJson(json as Map<String, dynamic>)).toList();

      // Cache the fetched bookings asynchronously
      try {
        final prefs = await SharedPreferences.getInstance();
        final jsonStringList = bookings.map((b) => jsonEncode(b.toJson())).toList();
        await prefs.setStringList(cacheKey, jsonStringList);
      } catch (cacheErr) {
        // Silently log cache writing errors
        // ignore: avoid_print
        print('Failed to cache bookings: $cacheErr');
      }

      return bookings;
    } on DioException catch (e) {
      // Check if it's a connection/network issue
      final isNetworkError = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.error != null;

      if (isNetworkError) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final cachedStrings = prefs.getStringList(cacheKey);
          if (cachedStrings != null && cachedStrings.isNotEmpty) {
            final cachedBookings = cachedStrings
                .map((s) => Booking.fromJson(jsonDecode(s) as Map<String, dynamic>))
                .toList();
            throw OfflineCacheException(cachedBookings, e);
          }
        } catch (cacheErr) {
          if (cacheErr is OfflineCacheException) rethrow;
          // ignore: avoid_print
          print('Failed to read bookings cache: $cacheErr');
        }
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }


  @override
  Future<void> bookSlot(String venueId, String date, String slotTime) async {
    try {
      await _dio.post(
        '/bookings',
        data: {
          'venue_id': venueId,
          'date': date,
          'slot_time': slotTime,
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw const SlotAlreadyBookedException();
      }
      rethrow;
    }
  }

  @override
  Future<void> cancelBooking(int bookingId) async {
    await _dio.delete('/bookings/$bookingId');
  }
}
