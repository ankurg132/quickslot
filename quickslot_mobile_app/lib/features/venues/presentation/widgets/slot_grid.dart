import 'package:flutter/material.dart';
import '../../domain/venue_slot.dart';
import '../../../../core/theme/app_theme.dart';

class SlotGrid extends StatelessWidget {
  final List<VenueSlot> slots;
  final VenueSlot? selectedSlot;
  final Function(VenueSlot) onSlotSelected;
  final String pricePerHour;

  const SlotGrid({
    super.key,
    required this.slots,
    required this.selectedSlot,
    required this.onSlotSelected,
    required this.pricePerHour,
  });

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_rounded, size: 48, color: AppTheme.secondaryTextColor),
              SizedBox(height: 12),
              Text(
                'No slots configured for this date.',
                style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final isSelected = selectedSlot?.time == slot.time;
        return _SlotCard(
          slot: slot,
          isSelected: isSelected,
          pricePerHour: pricePerHour,
          onTap: () => onSlotSelected(slot),
        );
      },
    );
  }
}

class _SlotCard extends StatelessWidget {
  final VenueSlot slot;
  final bool isSelected;
  final String pricePerHour;
  final VoidCallback onTap;

  const _SlotCard({
    required this.slot,
    required this.isSelected,
    required this.pricePerHour,
    required this.onTap,
  });

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

  @override
  Widget build(BuildContext context) {
    Color cardBg;
    Color borderCol;
    Color textCol;
    Color subtitleCol;
    bool isClickable = false;
    bool lineThrough = false;

    if (slot.isBooked && !slot.isBookedByMe) {
      // Booked by others (Disabled)
      cardBg = const Color(0xFFF1F5F9); // bg-surface-variant / light gray
      borderCol = const Color(0xFFE2E8F0);
      textCol = const Color(0xFF94A3B8); // Slate Grey
      subtitleCol = const Color(0xFF94A3B8);
      lineThrough = true;
    } else if (isSelected || slot.isBookedByMe) {
      // Selected or already booked by current user (Solid primary)
      cardBg = AppTheme.primaryColor;
      borderCol = AppTheme.primaryColor;
      textCol = Colors.white;
      subtitleCol = Colors.white70;
      isClickable = !slot.isBookedByMe; // Tapping my booked slot does nothing in details
    } else {
      // Available slot
      cardBg = Colors.white;
      borderCol = AppTheme.borderColor;
      textCol = AppTheme.textColor;
      subtitleCol = AppTheme.secondaryTextColor;
      isClickable = true;
    }

    return InkWell(
      onTap: isClickable ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderCol, width: isSelected ? 2.0 : 1.2),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatSlotTime(slot.time),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textCol,
                fontFamily: 'Inter',
                decoration: lineThrough ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              slot.isBooked && !slot.isBookedByMe
                  ? 'Booked'
                  : (slot.isBookedByMe ? 'My Slot' : '$pricePerHour/hr'),
              style: TextStyle(
                fontSize: 11,
                color: subtitleCol,
                fontWeight: isSelected || slot.isBookedByMe ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
