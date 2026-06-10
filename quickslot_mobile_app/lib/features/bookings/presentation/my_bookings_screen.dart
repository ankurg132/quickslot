import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../application/my_bookings_notifier.dart';
import '../domain/booking.dart';
import '../../../core/theme/app_theme.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsNotifierProvider);

    // Listen to notifier state changes for UI side effects like snackbars
    ref.listen<AsyncValue<List<Booking>>>(myBookingsNotifierProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action failed: ${next.error}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (previous is AsyncLoading && next is AsyncData && previous?.hasValue == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final isOffline = ref.watch(isOfflineBookingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'MY BOOKINGS',
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          if (isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Color(0xFFFFFBEB), // soft warm yellow
                border: Border(
                  bottom: BorderSide(color: Color(0xFFFDE68A), width: 1.0), // amber-200
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cloud_off_rounded, color: Color(0xFFD97706), size: 18), // amber-600
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You are offline. Showing cached bookings.',
                      style: TextStyle(
                        color: Color(0xFF92400E), // amber-800
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: bookingsAsync.when(
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
                        'Failed to fetch your bookings',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        err.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: AppTheme.secondaryTextColor),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.invalidate(myBookingsNotifierProvider);
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (bookings) {
                if (bookings.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.bookmark_border_rounded,
                              size: 60,
                              color: AppTheme.accentColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Active Bookings',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'You have not booked any sports slots yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: AppTheme.secondaryTextColor),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => context.go('/venues'),
                            child: const Text('Browse Venues'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return _BookingCard(booking: booking);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  final Booking booking;

  const _BookingCard({required this.booking});

  Future<void> _confirmCancellation(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          title: const Text(
            'Cancel Booking?',
            style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold, fontFamily: 'Manrope'),
          ),
          content: Text(
            'Are you sure you want to cancel your slot at ${booking.venueName} on ${booking.date} at ${booking.slotTime}?',
            style: const TextStyle(color: AppTheme.secondaryTextColor, fontFamily: 'Inter'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No, Keep It', style: TextStyle(color: AppTheme.secondaryTextColor)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes, Cancel', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await ref.read(myBookingsNotifierProvider.notifier).cancelBooking(booking.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.venueName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.accentColor),
                      const SizedBox(width: 6),
                      Text(
                        booking.date,
                        style: const TextStyle(fontSize: 13, color: AppTheme.secondaryTextColor),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.accentColor),
                      const SizedBox(width: 6),
                      Text(
                        booking.slotTime,
                        style: const TextStyle(fontSize: 13, color: AppTheme.secondaryTextColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
              tooltip: 'Cancel booking',
              onPressed: () => _confirmCancellation(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}
