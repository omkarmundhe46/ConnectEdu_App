import 'dart:io';

import 'package:connectedu_app/dto/participant_response_dto.dart'; // Import the new DTO
import 'package:connectedu_app/models/event.dart';
import 'package:connectedu_app/models/my_registration.dart';
import 'package:connectedu_app/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class EventRepository {
  final ApiService _apiService;
  EventRepository(this._apiService);

  Future<List<Event>> getAllUpcomingEvents() async {
    try {
      // Use the new public endpoint we just enabled
      final response = await _apiService.dio.get('/api/events/upcoming');
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

  Future<List<Event>> searchEvents(String query) async {
    try {
      final response = await _apiService.dio.get(
        '/api/events/search',
        queryParameters: {'query': query},
      );
      final data = response.data as List;
      return data.map((eventJson) => Event.fromJson(eventJson)).toList();
    } catch (e) {
      debugPrint('Failed to search events: $e');
      return [];
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

  Future<List<MyRegistration>> getMyRegistrations() async {
    try {
      final response = await _apiService.dio.get('/api/events/my-registrations');
      final data = response.data as List;
      return data.map((json) => MyRegistration.fromJson(json)).toList();
    } on DioException catch (e) {
      debugPrint('Failed to load my registrations: ${e.response?.data ?? e.message}');
      throw Exception('Failed to load your registrations.');
    } catch (e) {
      debugPrint('Failed to load my registrations: $e');
      throw Exception('Failed to load your registrations.');
    }
  }

  Future<void> updateMeetingLink(int clubId, int eventId, String meetingLink) async {
    try {
      await _apiService.dio.put(
        '/api/clubs/$clubId/events/$eventId/meeting-link',
        data: meetingLink, // Send the raw string as the body
        options: Options(
          // Set the content type to plain text
          contentType: 'text/plain',
        ),
      );
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Failed to update meeting link.';
      debugPrint('Failed to update link: $message');
      throw Exception(message);
    } catch (e) {
      debugPrint('Failed to update link: $e');
      throw Exception('An unexpected error occurred.');
    }
  }

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

  Future<bool> checkRegistration(int clubId, int eventId) async {
    try {
      final response = await _apiService.dio.get(
        '/api/clubs/$clubId/events/$eventId/check-registration',
      );
      // The backend returns a boolean directly
      return response.data as bool;
    } on DioException catch (e) {
      debugPrint('Failed to check registration: ${e.response?.data ?? e.message}');
      return false; // Assume not registered if check fails
    } catch (e) {
      debugPrint('Failed to check registration: $e');
      return false;
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

  Future<void> downloadParticipantsExcel(int clubId, int eventId, String eventName) async {
    try {
      // 2. Get the temporary directory to save the file
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/participants_$eventName.xlsx';
      final file = File(filePath);

      debugPrint('Downloading Excel to: $filePath');

      // 3. Use Dio to download the file (ApiService's Dio will add the auth token)
      await _apiService.dio.download(
        '/api/clubs/$clubId/events/$eventId/participants/excel',
        file.path,
        options: Options(
          responseType: ResponseType.bytes, // Important for file downloads
        ),
      );

      debugPrint('Download complete.');

      // 4. Open the downloaded file
      final openResult = await OpenFile.open(file.path);
      if (openResult.type != ResultType.done) {
        debugPrint('Could not open file: ${openResult.message}');
        throw Exception('Could not open the downloaded file: ${openResult.message}');
      }
    } on DioException catch (e) {
      debugPrint('Failed to download Excel file: ${e.response?.data ?? e.message}');
      throw Exception('Failed to download Excel file.');
    } catch (e) {
      debugPrint('Failed to download/open Excel file: $e');
      throw Exception(e.toString());
    }
  }

}