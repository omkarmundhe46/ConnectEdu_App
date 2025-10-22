import 'package:connectedu_app/models/event.dart';
import 'package:connectedu_app/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

class EventRepository {
  final ApiService _apiService;

  EventRepository(this._apiService);

  Future<List<Event>> getAllUpcomingEvents() async {
    try {
      // Use the correct internal endpoint via the gateway
      final response = await _apiService.dio.get('/internal/api/events/upcoming');
      final data = response.data as List;
      return data.map((eventJson) => Event.fromJson(eventJson)).toList();
    } on DioException catch (e) { // Catch errors
      debugPrint('Failed to load upcoming events: ${e.response?.data ?? e.message}');
      throw Exception('Failed to load upcoming events.');
    } catch (e) {
      debugPrint('Failed to load upcoming events: $e');
      throw Exception('Failed to load upcoming events.');
    }
  }

  // Calls GET /api/clubs/{clubId}/events via the Gateway
  Future<List<Event>> getEventsByClub(int clubId) async {
    try {
      final response = await _apiService.dio.get('/api/clubs/$clubId/events');
      final data = response.data as List;
      return data.map((eventJson) => Event.fromJson(eventJson)).toList();
    } on DioException catch (e) {
      debugPrint('Failed to load events for club $clubId: ${e.response?.data ?? e.message}');
      // Return empty list on error for counting purposes, prevents crash
      return [];
    } catch (e) {
      debugPrint('Failed to load events for club $clubId: $e');
      return []; // Return empty list on error
    }
  }
}

