import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../application/venues_notifier.dart';
import '../application/venue_slots_notifier.dart';
import '../domain/venue.dart';
import '../domain/venue_slot.dart';
import 'widgets/slot_grid.dart';
import '../../bookings/application/my_bookings_notifier.dart';
import '../../bookings/data/bookings_repository_impl.dart';
import '../../../core/theme/app_theme.dart';

class VenueDetailScreen extends ConsumerStatefulWidget {
  final String venueId;

  const VenueDetailScreen({
    super.key,
    required this.venueId,
  });

  @override
  ConsumerState<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

enum SlotTimeFilter {
  all('All Slots'),
  morning('Morning (6am-12pm)'),
  afternoon('Afternoon (12pm-5pm)'),
  evening('Evening (5pm-10pm)');

  final String label;
  const SlotTimeFilter(this.label);
}

class _VenueDetailScreenState extends ConsumerState<VenueDetailScreen> {
  late DateTime _selectedDate;
  VenueSlot? _selectedSlot;
  SlotTimeFilter _selectedTimeFilter = SlotTimeFilter.all;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(DateTime.now());
  }

  String _getPriceForVenue(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('badminton')) return '\$15';
    if (lowerName.contains('turf') || lowerName.contains('soccer') || lowerName.contains('football')) {
      return '\$35';
    }
    if (lowerName.contains('basketball')) return '\$25';
    if (lowerName.contains('tennis')) return '\$20';
    return '\$25';
  }

  String _formatSlotTime(String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final ampm = hour >= 12 ? 'PM' : 'AM';
      final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$formattedHour:$minute $ampm';
    } catch (e) {
      return time;
    }
  }

  String _formatTotalPrice(String pricePerHour) {
    final cleaned = pricePerHour.replaceAll('\$', '');
    try {
      final val = double.parse(cleaned);
      return '\$${val.toStringAsFixed(2)}';
    } catch (e) {
      return '$pricePerHour.00';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateUtils.dateOnly(DateTime.now()),
      lastDate: DateUtils.dateOnly(DateTime.now().add(const Duration(days: 30))),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = DateUtils.dateOnly(picked);
        _selectedSlot = null; // Clear selection when date changes
      });
    }
  }

  Future<void> _handleBookSlot(WidgetRef ref, VenueSlot slot, Venue venue) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    
    if (!mounted) return;
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
            'Confirm Booking',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColor, fontFamily: 'Manrope'),
          ),
          content: Text(
            'Do you want to book ${venue.name} on $dateStr at ${_formatSlotTime(slot.time)}?',
            style: const TextStyle(color: AppTheme.secondaryTextColor, fontFamily: 'Inter'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.secondaryTextColor)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Book Now', style: TextStyle(color: AppTheme.primaryColor)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    // Show loading dialog overlay
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
    );

    try {
      // Call bookSlot in notifier
      await ref.read(myBookingsNotifierProvider.notifier).bookSlot(
        widget.venueId,
        dateStr,
        slot.time,
      );

      // Dismiss loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully booked slot!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Refresh slots grid & clear selection
      ref.invalidate(venueSlotsNotifierProvider('${widget.venueId}:$dateStr'));
      setState(() {
        _selectedSlot = null;
      });
    } catch (e) {
      // Dismiss loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      if (e is SlotAlreadyBookedException) {
        // Handle concurrency failure
        _showConflictDialog(ref, slot, dateStr);
      } else {
        // Handle generic error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error booking slot: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showConflictDialog(WidgetRef ref, VenueSlot slot, String dateStr) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text(
                'Slot Already Taken!',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColor, fontFamily: 'Manrope'),
              ),
            ],
          ),
          content: Text(
            'Apologies, the ${_formatSlotTime(slot.time)} slot was just booked by another user. We are refreshing the availability grid.',
            style: const TextStyle(color: AppTheme.secondaryTextColor, fontFamily: 'Inter'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Refresh slot grid immediately
                ref.invalidate(venueSlotsNotifierProvider('${widget.venueId}:$dateStr'));
                setState(() {
                  _selectedSlot = null;
                });
              },
              child: const Text('OK', style: TextStyle(color: AppTheme.accentColor)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateItem(DateTime date) {
    final isSelected = DateUtils.isSameDay(date, _selectedDate);
    final weekdayStr = DateFormat('E').format(date).toUpperCase();
    final dayStr = DateFormat('d').format(date);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = DateUtils.dateOnly(date);
          _selectedSlot = null; // Reset selection on date change
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 64,
        height: 80,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentColor.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              weekdayStr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.primaryColor : AppTheme.secondaryTextColor,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              dayStr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textColor,
                fontFamily: 'Manrope',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenityChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF), // soft light container background
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textColor,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  List<VenueSlot> _filterSlots(List<VenueSlot> slots) {
    return slots.where((slot) {
      try {
        final hour = int.parse(slot.time.split(':')[0]);
        switch (_selectedTimeFilter) {
          case SlotTimeFilter.morning:
            return hour < 12;
          case SlotTimeFilter.afternoon:
            return hour >= 12 && hour < 17;
          case SlotTimeFilter.evening:
            return hour >= 17;
          case SlotTimeFilter.all:
            return true;
        }
      } catch (e) {
        return true;
      }
    }).toList();
  }

  Widget _buildTimeFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: SlotTimeFilter.values.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final filter = SlotTimeFilter.values[index];
            final isSelected = _selectedTimeFilter == filter;
            return ChoiceChip(
              label: Text(
                filter.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.secondaryTextColor,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedTimeFilter = filter;
                  });
                }
              },
              selectedColor: AppTheme.primaryColor,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                  width: 1.0,
                ),
              ),
              showCheckmark: false,
              elevation: 0,
              pressElevation: 0,
            );
          },
        ),
      ),
    );
  }

  Widget? _buildBottomBar(Venue venue, String pricePerHour) {
    if (_selectedSlot == null) return null;

    final formattedDateText = "${DateFormat('E d MMM').format(_selectedDate)} • ${_formatSlotTime(_selectedSlot!.time)}";
    final totalPriceText = _formatTotalPrice(pricePerHour);

    return Container(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: MediaQuery.of(context).padding.bottom + 16.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formattedDateText,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.secondaryTextColor,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                totalPriceText,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => _handleBookSlot(ref, _selectedSlot!, venue),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Book Now',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final venuesAsync = ref.watch(venuesNotifierProvider);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final slotsAsync = ref.watch(venueSlotsNotifierProvider('${widget.venueId}:$dateStr'));

    return venuesAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('QuickSlot'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textColor),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('QuickSlot'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textColor),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text('Error loading venue details: $err'),
            ],
          ),
        ),
      ),
      data: (venues) {
        final venue = venues.firstWhere(
          (v) => v.id == widget.venueId,
          orElse: () => Venue(id: widget.venueId, name: 'Unknown Venue', description: '', location: '', sport: '', imageUrl: ''),
        );

        final pricePerHour = _getPriceForVenue(venue.name);

        // Generate next 14 days starting from today
        final today = DateUtils.dateOnly(DateTime.now());
        final dates = List.generate(14, (index) => today.add(Duration(days: index)));

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: const Text(
              'QuickSlot',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
                fontFamily: 'Manrope',
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1.0),
              child: Divider(color: AppTheme.borderColor, height: 1.0, thickness: 1.0),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textColor, size: 20),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: AppTheme.textColor, size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sharing venue details...'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                // Hero Photo Container (rounded corner card style)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        if (venue.imageUrl.isNotEmpty)
                          Image.network(
                            venue.imageUrl,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 220,
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image_rounded, size: 48),
                            ),
                          )
                        else
                          Container(
                            height: 220,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_rounded, size: 48),
                          ),
                        
                        // Floating Rating Badge
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
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
                                  color: AppTheme.accentColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '4.8',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textColor,
                                    fontFamily: 'JetBrains Mono',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Venue Overview Info Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sport Badge & Price Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (venue.sport.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  venue.sport.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                    letterSpacing: 0.5,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            Text(
                              '$pricePerHour/hr',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryColor,
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Title
                        Text(
                          venue.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                            fontFamily: 'Manrope',
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Location Row
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: AppTheme.secondaryTextColor,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                venue.location,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.secondaryTextColor,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (venue.description.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            venue.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.secondaryTextColor,
                              height: 1.4,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Divider(color: AppTheme.borderColor, height: 1),
                        const SizedBox(height: 16),
                        // Amenities
                        const Text(
                          'Amenities',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                            fontFamily: 'Manrope',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildAmenityChip(Icons.directions_car_rounded, 'Parking'),
                            _buildAmenityChip(Icons.ac_unit_rounded, 'A/C'),
                            _buildAmenityChip(Icons.shower_rounded, 'Showers'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Date Picker Timeline Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Select Date',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _selectDate(context),
                            child: Row(
                              children: [
                                Text(
                                  DateFormat('MMMM yyyy').format(_selectedDate),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.edit_calendar_rounded,
                                  size: 16,
                                  color: AppTheme.primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: dates.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            return _buildDateItem(dates[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Slots Grid Header
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'Available Times',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                _buildTimeFilterSection(),
                const SizedBox(height: 8),

                // Slots Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: slotsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(color: AppTheme.primaryColor),
                      ),
                    ),
                    error: (err, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const Icon(Icons.cloud_off_rounded, size: 40, color: Colors.redAccent),
                            const SizedBox(height: 8),
                            const Text('Failed to load slots'),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                ref.read(venueSlotsNotifierProvider('${widget.venueId}:$dateStr').notifier).refresh();
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (slots) {
                      final filtered = _filterSlots(slots);
                      return SlotGrid(
                        slots: filtered,
                        selectedSlot: _selectedSlot,
                        pricePerHour: pricePerHour,
                        onSlotSelected: (slot) {
                          setState(() {
                            _selectedSlot = slot;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomBar(venue, pricePerHour),
        );
      },
    );
  }
}
