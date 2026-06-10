class Venue {
  final String id;
  final String name;
  final String description;
  final String location;
  final String sport;
  final String imageUrl;

  const Venue({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.sport,
    required this.imageUrl,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      sport: json['sport'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'sport': sport,
      'image_url': imageUrl,
    };
  }

  Venue copyWith({
    String? id,
    String? name,
    String? description,
    String? location,
    String? sport,
    String? imageUrl,
  }) {
    return Venue(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      sport: sport ?? this.sport,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
