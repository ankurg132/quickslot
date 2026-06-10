import 'package:dio/dio.dart';
import '../domain/venue.dart';
import '../domain/venue_slot.dart';
import 'venues_repository.dart';

class VenuesRepositoryImpl implements VenuesRepository {
  final Dio _dio;

  VenuesRepositoryImpl(this._dio);

  @override
  Future<List<Venue>> getVenues() async {
    final response = await _dio.get('/venues');
    
    // Dio automatically parses JSON to List/Map if content-type is json
    final List<dynamic> data = response.data is List 
        ? response.data 
        : (response.data as Map<String, dynamic>)['venues'] as List;
        
    return data.map((json) => Venue.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<VenueSlot>> getVenueSlots(String venueId, String date) async {
    final response = await _dio.get(
      '/venues/$venueId/slots',
      queryParameters: {'date': date},
    );

    final List<dynamic> data = response.data is List
        ? response.data
        : (response.data as Map<String, dynamic>)['slots'] as List;

    return data.map((json) => VenueSlot.fromJson(json as Map<String, dynamic>)).toList();
  }
}
