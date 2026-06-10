import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/booking.dart';
import '../../../core/network/api_client.dart';
import '../../../core/common/exceptions.dart';
import '../../../core/common/api_routes.dart';

abstract class BookingsRepository {
  Future<List<Booking>> getUserBookings(String userId);
  Future<void> bookSlot(String venueId, String date, String slotTime);
  Future<void> cancelBooking(int bookingId);
}

class BookingsRepositoryImpl implements BookingsRepository {
  final Dio _dio;

  BookingsRepositoryImpl(this._dio);

  @override
  Future<List<Booking>> getUserBookings(String userId) async {
    final cacheKey = 'user_bookings_$userId';
    try {
      final response = await _dio.get(ApiRoutes.userBookings(userId));
      
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
        ApiRoutes.bookings,
        data: {
          'venue_id': venueId,
          'date': date,
          'start_time': slotTime,
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
    await _dio.delete(ApiRoutes.cancelBooking(bookingId));
  }
}

final bookingsRepositoryProvider = Provider<BookingsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return BookingsRepositoryImpl(dio);
});
