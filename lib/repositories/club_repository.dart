import 'package:connectedu_app/models/club.dart';
import 'package:connectedu_app/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

class ClubRepository {
  final ApiService _apiService;

  ClubRepository(this._apiService);

  Future<List<Club>> getAllClubs() async {
    try {
      final response = await _apiService.dio.get('/api/clubs');
      final data = response.data as List;
      return data.map((clubJson) => Club.fromJson(clubJson)).toList();
    } on DioException catch (e) { // Catch errors
      debugPrint('Failed to load clubs: ${e.response?.data ?? e.message}');
      throw Exception('Failed to load clubs.');
    } catch (e) {
      debugPrint('Failed to load clubs: $e');
      throw Exception('Failed to load clubs.');
    }
  }
}

