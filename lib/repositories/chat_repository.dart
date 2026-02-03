import 'package:connectedu_app/models/chat_message_model.dart';
import 'package:connectedu_app/services/api_service.dart';
import 'package:dio/dio.dart'; // Import Dio for Response types if needed

class ChatRepository {
  final ApiService _apiService;

  // We don't need StorageService here anymore because ApiService handles the token!
  ChatRepository(this._apiService);


  Future<List<ChatMessageModel>> getChatHistory() async {
    try {
      final response = await _apiService.get('/api/chat/history');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        // Map list to Model
        return data.map((json) => ChatMessageModel.fromHistoryJson(json)).toList();
      } else {
        return []; // Return empty if failed, don't crash
      }
    } catch (e) {
      // If offline or error, just return empty list so user can still chat
      return [];
    }
  }


  Future<ChatMessageModel> sendMessage(String message) async {
    // 1. Prepare Body
    final body = {
      'message': message,
    };

    try {
      // 2. Send POST Request
      // We pass 'body' directly as the second argument (positional), not named 'body:'
      // We do not pass 'headers' because ApiService interceptor adds the token.
      final Response response = await _apiService.post(
        '/api/chat/ask',
        body,
      );

      if (response.statusCode == 200) {
        // Dio automatically parses JSON into Map if headers are correct
        final data = response.data;
        return ChatMessageModel.fromJson(data);
      } else {
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } on DioException catch (e) {
      // Handle Dio specific errors (like 401, 403, 500)
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }
      throw Exception('Network error: ${e.message}');
    }
  }
}