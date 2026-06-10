import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/venue.dart';
import '../domain/venue_slot.dart';
import 'venues_repository_impl.dart';
import '../../../core/network/api_client.dart';

abstract class VenuesRepository {
  Future<List<Venue>> getVenues();
  Future<List<VenueSlot>> getVenueSlots(String venueId, String date);
}

final venuesRepositoryProvider = Provider<VenuesRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return VenuesRepositoryImpl(dio);
});
