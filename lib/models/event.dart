class Event {
  final int id;
  final String name;
  final String description;
  final DateTime date;
  final String location;
  final int? clubId; // Make clubId nullable if it can be
  final String? imageUrl; // Add imageUrl (make it nullable)
  final String? meetingLink; // Add meetingLink (make it nullable)
  final String status; // ADD THIS FIELD (e.g., "UPCOMING", "COMPLETED")

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    required this.location,
    required this.status, // ADD TO CONSTRUCTOR
    this.clubId,
    this.imageUrl, // Add to constructor
    this.meetingLink, // Add to constructor
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    String determineStatus(DateTime eventDate) {
      // Basic status determination based on date
      return eventDate.isAfter(DateTime.now()) ? 'UPCOMING' : 'COMPLETED';
    }

    DateTime parsedDate = json['date'] != null ? DateTime.parse(json['date']) : DateTime.now();
    return Event(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      location: json['location'],
      clubId: json['clubId'], // Keep as is, handle null if necessary
      imageUrl: json['imageUrl'], // Get the image URL
      meetingLink: json['meetingLink'], // Get the meeting link
      // Determine status based on date if not provided by backend
      status: json['status'] ?? determineStatus(parsedDate),
    );
  }
}

