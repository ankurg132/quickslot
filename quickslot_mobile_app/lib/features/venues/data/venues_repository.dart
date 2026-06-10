import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/venue.dart';
import '../domain/venue_slot.dart';
import '../../../core/network/api_client.dart';
import '../../../core/common/api_routes.dart';

abstract class VenuesRepository {
  Future<List<Venue>> getVenues();
  Future<List<VenueSlot>> getVenueSlots(String venueId, String date);
}

class VenuesRepositoryImpl implements VenuesRepository {
  final Dio _dio;

  VenuesRepositoryImpl(this._dio);

  @override
  Future<List<Venue>> getVenues() async {
    final response = await _dio.get(ApiRoutes.venues);
    
    // Dio automatically parses JSON to List/Map if content-type is json
    final List<dynamic> data = response.data is List 
        ? response.data 
        : (response.data as Map<String, dynamic>)['venues'] as List;
        
    return data.map((json) => Venue.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<VenueSlot>> getVenueSlots(String venueId, String date) async {
    final response = await _dio.get(
      ApiRoutes.venueSlots(venueId),
      queryParameters: {'date': date},
    );

    final List<dynamic> data = response.data is List
        ? response.data
        : (response.data as Map<String, dynamic>)['slots'] as List;

    return data.map((json) => VenueSlot.fromJson(json as Map<String, dynamic>)).toList();
  }
}

final venuesRepositoryProvider = Provider<VenuesRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return VenuesRepositoryImpl(dio);
});
