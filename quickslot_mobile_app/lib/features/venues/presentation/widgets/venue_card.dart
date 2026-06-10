import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/venue.dart';
import '../../application/venue_slots_notifier.dart';
import '../../application/saved_venues_notifier.dart';
import '../../../../core/theme/app_theme.dart';

class VenueCard extends ConsumerWidget {
  final Venue venue;

  const VenueCard({super.key, required this.venue});

  String _getDescription(Venue venue) {
    if (venue.description.isNotEmpty) return venue.description;
    final lowerName = venue.name.toLowerCase();
    if (lowerName.contains('badminton')) {
      return 'Premium indoor courts with professional wooden flooring and excellent lighting. Perfect for singles and doubles.';
    }
    if (lowerName.contains('turf') ||
        lowerName.contains('soccer') ||
        lowerName.contains('football')) {
      return 'FIFA certified 5A-side artificial turf under floodlights. Perfect for evening matches. Bibs and water included.';
    }
    if (lowerName.contains('basketball')) {
      return 'Standard size indoor basketball court with fiberglass backboards and clean high-grip flooring.';
    }
    if (lowerName.contains('tennis')) {
      return 'Professional acrylic hardcourt with professional net setup. Perfect for tournament prep or leisure play.';
    }
    return 'Top-rated sports venue equipped with state-of-the-art amenities. Perfect for recreational and competitive play.';
  }

  String _getPriceForVenue(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('badminton')) return '400';
    if (lowerName.contains('turf') ||
        lowerName.contains('soccer') ||
        lowerName.contains('football')) {
      return '1200';
    }
    if (lowerName.contains('basketball')) return '800';
    if (lowerName.contains('tennis')) return '600';
    return '500';
  }

  double _getRating(String id) {
    final val = id.codeUnits.reduce((a, b) => a + b) % 10;
    return 4.0 + (val / 10); // yields 4.0 to 4.9
  }

  int _getReviewCount(String id) {
    return (id.codeUnits.reduce((a, b) => a + b) % 80) +
        20; // yields 20 to 99 reviews
  }

  String _getDistance(String id) {
    final val = (id.codeUnits.reduce((a, b) => a + b) % 40) / 10 + 1.2;
    return "${val.toStringAsFixed(1)} km away";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final price = _getPriceForVenue(venue.name);
    final distance = _getDistance(venue.id);
    final rating = _getRating(venue.id);
    final reviews = _getReviewCount(venue.id);
    final description = _getDescription(venue);

    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final slotsAsync = ref.watch(
      venueSlotsNotifierProvider('${venue.id}:$dateStr'),
    );

    // Saved status
    final savedVenueIds = ref.watch(savedVenuesProvider);
    final isSaved = savedVenueIds.contains(venue.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/venues/${venue.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Image with Badges
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  if (venue.imageUrl.isNotEmpty)
                    Image.network(
                      venue.imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 180,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image_rounded,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 180,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image_rounded,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),

                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${rating.toStringAsFixed(1)} ($reviews)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B), // Slate-800
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Details Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Price Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          venue.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                            fontFamily: 'Manrope',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹$price',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F766E), // Emerald Green
                              fontFamily: 'Manrope',
                            ),
                          ),
                          const Text(
                            '/hr',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.secondaryTextColor,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Location and Distance Row
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppTheme.secondaryTextColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '$distance • ${venue.location}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.secondaryTextColor,
                            fontFamily: 'Inter',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Short Description
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569), // Slate-600
                      height: 1.4,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),

                  // Next Available Slots Section
                  const Text(
                    'Next Available Slots',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                      fontFamily: 'JetBrains Mono',
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Slot chips fetched from API provider
                  slotsAsync.when(
                    loading: () => const SizedBox(
                      height: 28,
                      child: Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    error: (err, stack) => const Text(
                      'No slots available',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                    data: (slots) {
                      final availableSlots = slots
                          .where((s) => s.isAvailable)
                          .toList();
                      if (availableSlots.isEmpty) {
                        return const Text(
                          'No slots available today',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.secondaryTextColor,
                          ),
                        );
                      }

                      return Row(
                        children: availableSlots.take(2).map((slot) {
                          // Format time
                          String displayTime = slot.time;
                          try {
                            final parts = displayTime.split(':');
                            final hour = int.parse(parts[0]);
                            final ampm = hour >= 12 ? 'PM' : 'AM';
                            final formattedHour = hour > 12
                                ? hour - 12
                                : (hour == 0 ? 12 : hour);
                            displayTime = "$formattedHour:${parts[1]} $ampm";
                          } catch (_) {}

                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFEFF4FF,
                              ), // Soft blue background
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              displayTime,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                                fontFamily: 'Inter',
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
