import 'package:jwt_decoder/jwt_decoder.dart';

class User {
  final int id;
  final String email;
  final String name;
  final String role;
  final int? managedClubId;
  final String? phone;
  final String? profileImageUrl;
  final String department;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.managedClubId,
    this.phone,
    this.profileImageUrl,
    required this.department,
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
          : int.tryParse(decodedToken['userId'].toString()) ?? 0,
      email: decodedToken['sub'] ?? '',
      name: decodedToken['name'] ?? 'User',
      role: primaryRole,
      managedClubId: managedId,
      phone: decodedToken['phone'] as String?,
      profileImageUrl: decodedToken['profileImageUrl'] as String?,
      department: decodedToken['department'] as String? ?? 'Not Set',
    );
  }
}
