import 'package:flutter/foundation.dart';

// No Equatable or Equatable props needed if not comparing objects.
class Club {
  final int id;
  final String name;
  final String description;
  final int adminId;
  final String? logoUrl; // The URL for the club's logo from S3

  const Club({
    required this.id,
    required this.name,
    required this.description,
    required this.adminId,
    this.logoUrl, // Make this optional
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      adminId: json['adminId'] as int,
      logoUrl: json['logoUrl'] as String?, // Map the logoUrl, can be null
    );
  }

  // copyWith method for easier updates in BLoC
  Club copyWith({
    int? id,
    String? name,
    String? description,
    int? adminId,
    String? logoUrl,
  }) {
    return Club(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      adminId: adminId ?? this.adminId,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }
}

