import 'package:connectedu_app/dto/participant_response_dto.dart'; // Import the new DTO
import 'package:connectedu_app/models/event.dart';
import 'package:connectedu_app/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class EventRepository {
  final ApiService _apiService;
  EventRepository(this._apiService);

  Future<List<Event>> getAllUpcomingEvents() async {
    try {
      final response = await _apiService.dio.get('/internal/api/events/upcoming');
      final data = response.data as List;
      return data.map((eventJson) => Event.fromJson(eventJson)).toList();
    } on DioException catch (e) {
      debugPrint('Failed to load upcoming events: ${e.response?.data ?? e.message}');
      throw Exception('Failed to load upcoming events.');
    } catch (e) {
      debugPrint('Failed to load upcoming events: $e');
      throw Exception('Failed to load upcoming events.');
    }
  }

  Future<List<Event>> getEventsByClub(int clubId) async {
    try {
      final response = await _apiService.dio.get('/api/clubs/$clubId/events');
      final data = response.data as List;
      return data.map((eventJson) => Event.fromJson(eventJson)).toList();
    } on DioException catch (e) {
      debugPrint('Failed to load events for club $clubId: ${e.response?.data ?? e.message}');
      throw Exception('Failed to load events.');
    } catch (e) {
      debugPrint('Failed to load events for club $clubId: $e');
      throw Exception('Failed to load events.');
    }
  }

  // --- ADD THIS METHOD ---
  // This is required by EventDetailBloc
  Future<List<ParticipantResponseDto>> getEventParticipants(int clubId, int eventId) async {
    try {
      final response = await _apiService.dio.get(
        '/api/clubs/$clubId/events/$eventId/participants', // Use gateway URL
      );
      final data = response.data as List;
      // Ensure the json is cast to the correct type before parsing
      return data.map((json) => ParticipantResponseDto.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 403) {
        debugPrint('getEventParticipants failed (404/403), returning empty list. This is OK.');
        return []; // Return an empty list instead of throwing an error
      }
      debugPrint('Failed to load participants: ${e.response?.data ?? e.message}');
      throw Exception('Failed to load participants.');
    } catch (e) {
      debugPrint('Failed to load participants: $e');
      throw Exception('Failed to load participants.');
    }
  }

  // --- ADD NEW METHODS FOR EVENT CRUD ---

  Future<Event> createEvent(int clubId, Map<String, dynamic> eventData) async {
    try {
      final response = await _apiService.dio.post(
        '/api/clubs/$clubId/events',
        data: eventData,
      );
      return Event.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Failed to create event.';
      debugPrint('Failed to create event: $message');
      throw Exception(message);
    } catch (e) {
      debugPrint('Failed to create event: $e');
      throw Exception('An unexpected error occurred.');
    }
  }

  Future<Event> updateEvent(int clubId, int eventId, Map<String, dynamic> eventData) async {
    try {
      final response = await _apiService.dio.put(
        '/api/clubs/$clubId/events/$eventId',
        data: eventData,
      );
      return Event.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Failed to update event.';
      debugPrint('Failed to update event: $message');
      throw Exception(message);
    } catch (e) {
      debugPrint('Failed to update event: $e');
      throw Exception('An unexpected error occurred.');
    }
  }

  Future<void> deleteEvent(int clubId, int eventId) async {
    try {
      await _apiService.dio.delete('/api/clubs/$clubId/events/$eventId');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Failed to delete event.';
      debugPrint('Failed to delete event: $message');
      throw Exception(message);
    } catch (e) {
      debugPrint('Failed to delete event: $e');
      throw Exception('An unexpected error occurred.');
    }
  }
}