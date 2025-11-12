import 'dart:io';
import 'package:connectedu_app/models/chat_message.dart';
import 'package:connectedu_app/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DiscussionRepository {
  final ApiService _apiService;

  DiscussionRepository(this._apiService);

  /// Fetches the message history for an event.
  Future<List<ChatMessage>> getMessageHistory(int clubId, int eventId) async {
    try {
      final response = await _apiService.dio.get(
        '/api/clubs/$clubId/events/$eventId/discussions/messages',
      );
      final data = response.data as List;
      return data.map((json) => ChatMessage.fromJson(json)).toList();
    } on DioException catch (e) {
      debugPrint('Failed to load message history: ${e.response?.data ?? e.message}');
      throw Exception('Failed to load message history.');
    } catch (e) {
      debugPrint('Failed to load message history: $e');
      throw Exception('An unexpected error occurred.');
    }
  }

  /// Uploads a file to the generic S3 upload endpoint.
  /// Returns the S3 URL.
  Future<String> uploadFile(File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _apiService.dio.post(
        '/api/uploads', // Your generic upload endpoint
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['fileUrl'];
      } else {
        throw Exception('File upload failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('File upload API error: ${e.response?.data ?? e.message}');
      throw Exception('File upload failed.');
    } catch (e) {
      debugPrint('File upload error: $e');
      throw Exception('An unexpected error occurred.');
    }
  }
}