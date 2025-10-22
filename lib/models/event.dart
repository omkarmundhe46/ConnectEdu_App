class Event {
  final int id;
  final String name;
  final String description;
  final DateTime date;
  final String location;
  final int? clubId; // Make clubId nullable if it can be
  final String? imageUrl; // Add imageUrl (make it nullable)
  final String? meetingLink; // Add meetingLink (make it nullable)

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    required this.location,
    this.clubId,
    this.imageUrl, // Add to constructor
    this.meetingLink, // Add to constructor
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      location: json['location'],
      clubId: json['clubId'], // Keep as is, handle null if necessary
      imageUrl: json['imageUrl'], // Get the image URL
      meetingLink: json['meetingLink'], // Get the meeting link
    );
  }
}

