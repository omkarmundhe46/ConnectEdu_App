import 'package:connectedu_app/models/club.dart';
import 'package:connectedu_app/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class ClubRepository {
  final ApiService _apiService;
  ClubRepository(this._apiService);

  Future<List<Club>> getAllClubs() async {
    try {
      final response = await _apiService.dio.get('/api/clubs'); // Endpoint via Gateway
      final data = response.data as List;
      // The updated Club.fromJson will now handle the mapping
      return data.map((clubJson) => Club.fromJson(clubJson)).toList();
    } on DioException catch (e) {
      debugPrint('Failed to load clubs: ${e.response?.data ?? e.message}');
      throw Exception('Failed to load clubs.');
    } catch (e) {
      debugPrint('Failed to load clubs: $e');
      throw Exception('Failed to load clubs.');
    }
  }

  Future<Club> createClub(String name, String description, String adminEmail, String? logoUrl) async {
    try {
      final response = await _apiService.dio.post(
        '/api/clubs',
        data: {
          'name': name,
          'description': description,
          'adminEmail': adminEmail,
          'logoUrl': logoUrl,
        },
      );
      return Club.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('Failed to create club: ${e.response?.data ?? e.message}');
      throw Exception('Failed to create club: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      debugPrint('Failed to create club: $e');
      throw Exception('Failed to create club.');
    }
  }

  Future<Club> updateClub(int clubId, String name, String description, String adminEmail, String? logoUrl) async {
    try {
      final response = await _apiService.dio.put(
        '/api/clubs/$clubId',
        data: {
          'name': name,
          'description': description,
          'adminEmail': adminEmail,
          'logoUrl': logoUrl,
        },
      );
      return Club.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('Failed to update club: ${e.response?.data ?? e.message}');
      throw Exception('Failed to update club: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      debugPrint('Failed to update club: $e');
      throw Exception('Failed to update club.');
    }
  }

  Future<void> deleteClub(int clubId) async {
    try {
      await _apiService.dio.delete('/api/clubs/$clubId');
    } on DioException catch (e) {
      debugPrint('Failed to delete club: ${e.response?.data ?? e.message}');
      throw Exception('Failed to delete club: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      debugPrint('Failed to delete club: $e');
      throw Exception('Failed to delete club.');
    }
  }
}

