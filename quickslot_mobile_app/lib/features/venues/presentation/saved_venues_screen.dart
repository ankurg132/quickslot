import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/venue_card.dart';
import '../application/venues_notifier.dart';
import '../application/saved_venues_notifier.dart';
import '../../../../core/theme/app_theme.dart';

class SavedVenuesScreen extends ConsumerWidget {
  const SavedVenuesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venuesAsync = ref.watch(venuesNotifierProvider);
    final savedVenueIds = ref.watch(savedVenuesProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'SAVED VENUES',
          style: TextStyle(
            color: AppTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(color: AppTheme.borderColor, height: 1.0, thickness: 1.0),
        ),
      ),
      body: venuesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 60, color: Colors.redAccent),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load saved venues',
                  style: TextStyle(fontSize: 18, color: AppTheme.textColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppTheme.secondaryTextColor),
                ),
              ],
            ),
          ),
        ),
        data: (venues) {
          final savedVenues = venues.where((v) => savedVenueIds.contains(v.id)).toList();

          if (savedVenues.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bookmark_outline_rounded,
                        size: 64,
                        color: AppTheme.accentColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No Saved Venues',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap the bookmark icon on any venue in the Explore list to save it for quick access.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.secondaryTextColor,
                        height: 1.5,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: savedVenues.length,
            itemBuilder: (context, index) {
              final venue = savedVenues[index];
              return VenueCard(venue: venue);
            },
          );
        },
      ),
    );
  }
}
