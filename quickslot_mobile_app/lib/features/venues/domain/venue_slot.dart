enum SlotStatus {
  available,
  booked,
  bookedByMe,
}

class VenueSlot {
  final String time; // e.g. '06:00'
  final SlotStatus status;
  final String? bookedBy;

  const VenueSlot({
    required this.time,
    required this.status,
    this.bookedBy,
  });

  factory VenueSlot.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'available';
    final bookedBy = json['booked_by'] as String? ?? json['bookedBy'] as String?;
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
      time: json['time'] as String? ?? json['slot_time'] as String? ?? json['start_time'] as String? ?? '',
      status: status,
      bookedBy: bookedBy,
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
      if (bookedBy != null) 'booked_by': bookedBy,
    };
  }

  bool get isAvailable => status == SlotStatus.available;
  bool get isBookedByMe => status == SlotStatus.bookedByMe;
  bool get isBooked => status == SlotStatus.booked || status == SlotStatus.bookedByMe;

  VenueSlot copyWith({
    String? time,
    SlotStatus? status,
    String? bookedBy,
  }) {
    return VenueSlot(
      time: time ?? this.time,
      status: status ?? this.status,
      bookedBy: bookedBy ?? this.bookedBy,
    );
  }
}
