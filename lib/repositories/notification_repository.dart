import 'package:connectedu_app/models/notification_log.dart';
import 'package:connectedu_app/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

class NotificationRepository {
  final ApiService _apiService;
  NotificationRepository(this._apiService);

  Future<List<NotificationLog>> getMyNotifications() async {
    try {
      final response = await _apiService.dio.get('/api/notifications/my-notifications');
      final data = response.data as List;
      return data.map((json) => NotificationLog.fromJson(json)).toList();
    } on DioException catch (e) {
      debugPrint('Failed to load notifications: ${e.response?.data ?? e.message}');
      throw Exception('Failed to load notifications.');
    } catch (e) {
      debugPrint('Failed to load notifications: $e');
      throw Exception('Failed to load notifications.');
    }
  }
}