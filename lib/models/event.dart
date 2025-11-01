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
  final String? contactName1;
  final String? contactPhone1;
  final String? contactName2;
  final String? contactPhone2;

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
    this.contactName1,
    this.contactPhone1,
    this.contactName2,
    this.contactPhone2,
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
      contactName1: json['contactName1'],
      contactPhone1: json['contactPhone1'],
      contactName2: json['contactName2'],
      contactPhone2: json['contactPhone2'],
    );
  }
}

