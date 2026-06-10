class Booking {
  final int id;
  final String venueId;
  final String venueName;
  final String date;
  final String slotTime;
  final String userId;

  const Booking({
    required this.id,
    required this.venueId,
    required this.venueName,
    required this.date,
    required this.slotTime,
    required this.userId,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as int? ?? 0,
      venueId: (json['venue_id'] ?? json['venueId'] ?? '').toString(),
      venueName: json['venue_name'] as String? ?? json['venueName'] as String? ?? '',
      date: json['date'] as String? ?? '',
      slotTime: json['slot_time'] as String? ?? json['slotTime'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'venue_id': venueId,
      'venue_name': venueName,
      'date': date,
      'slot_time': slotTime,
      'user_id': userId,
    };
  }

  Booking copyWith({
    int? id,
    String? venueId,
    String? venueName,
    String? date,
    String? slotTime,
    String? userId,
  }) {
    return Booking(
      id: id ?? this.id,
      venueId: venueId ?? this.venueId,
      venueName: venueName ?? this.venueName,
      date: date ?? this.date,
      slotTime: slotTime ?? this.slotTime,
      userId: userId ?? this.userId,
    );
  }
}
