enum SlotStatus {
  available,
  booked,
  bookedByMe,
}

class VenueSlot {
  final String time; // e.g. '06:00'
  final SlotStatus status;

  const VenueSlot({
    required this.time,
    required this.status,
  });

  factory VenueSlot.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'available';
    SlotStatus status;
    switch (statusStr) {
      case 'booked_by_me':
        status = SlotStatus.bookedByMe;
        break;
      case 'booked':
        status = SlotStatus.booked;
        break;
      case 'available':
      default:
        status = SlotStatus.available;
        break;
    }
    return VenueSlot(
      time: json['time'] as String? ?? json['slot_time'] as String? ?? '',
      status: status,
    );
  }

  Map<String, dynamic> toJson() {
    String statusStr;
    switch (status) {
      case SlotStatus.bookedByMe:
        statusStr = 'booked_by_me';
        break;
      case SlotStatus.booked:
        statusStr = 'booked';
        break;
      case SlotStatus.available:
        statusStr = 'available';
        break;
    }
    return {
      'time': time,
      'status': statusStr,
    };
  }

  bool get isAvailable => status == SlotStatus.available;
  bool get isBookedByMe => status == SlotStatus.bookedByMe;
  bool get isBooked => status == SlotStatus.booked || status == SlotStatus.bookedByMe;

  VenueSlot copyWith({
    String? time,
    SlotStatus? status,
  }) {
    return VenueSlot(
      time: time ?? this.time,
      status: status ?? this.status,
    );
  }
}
