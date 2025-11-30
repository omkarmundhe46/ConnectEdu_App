import 'package:flutter/foundation.dart';

class Club {
  final int id;
  final String name;
  final String description;
  final int adminId;
  final String category; // New Field
  final String? logoUrl;

  const Club({
    required this.id,
    required this.name,
    required this.description,
    required this.adminId,
    required this.category, // Required
    this.logoUrl,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      adminId: json['adminId'] as int,
      // Default to 'ALL' if the backend sends null (e.g. for old data)
      category: json['category'] ?? 'ALL',
      logoUrl: json['logoUrl'] as String?,
    );
  }

  Club copyWith({
    int? id,
    String? name,
    String? description,
    int? adminId,
    String? category, // Add to copyWith
    String? logoUrl,
  }) {
    return Club(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      adminId: adminId ?? this.adminId,
      category: category ?? this.category, // Update here
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }
}