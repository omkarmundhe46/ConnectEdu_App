import 'package:jwt_decoder/jwt_decoder.dart';

class User {
  final int id;
  final String email;
  final String name; // ADD THIS FIELD
  final String role; // Stores the primary role
  final int? managedClubId; // Use int? for nullable integer

  User({
    required this.id,
    required this.email,
    required this.name, // ADD TO CONSTRUCTOR
    required this.role,
    this.managedClubId,
  });

  // --- THIS IS THE FIX ---
  // Updated factory constructor to handle the decoded token map correctly.
  factory User.fromToken(Map<String, dynamic> decodedToken) {
    // Safely extract the roles list. It might be null or not a list.
    final rolesList = decodedToken['roles'] as List<dynamic>?;

    // Determine the primary role (e.g., take the first one if the list exists)
    String primaryRole = 'USER'; // Default role if none found
    if (rolesList != null && rolesList.isNotEmpty) {
      // Remove the "ROLE_" prefix if it exists
      primaryRole = (rolesList.first as String).replaceFirst('ROLE_', '');
    }

    // Safely extract managedClubId (might be null or Integer)
    int? managedId = null;
    if (decodedToken['managedClubId'] != null) {
      managedId = decodedToken['managedClubId'] is int
          ? decodedToken['managedClubId']
          : int.tryParse(decodedToken['managedClubId'].toString());
    }

    return User(
      // Safely extract userId (might be Integer)
      id: decodedToken['userId'] is int
          ? decodedToken['userId']
          : int.tryParse(decodedToken['userId'].toString()) ?? 0, // Default to 0 if parsing fails
      email: decodedToken['sub'] ?? '', // 'sub' claim usually holds the email/username
      name: decodedToken['name'] ?? 'User', // --- EXTRACT NAME (Add 'name' claim to JWT in user-service) ---
      role: primaryRole,
      managedClubId: managedId,
    );
  }
}
