import 'package:connectedu_app/models/analytics_models.dart';
import 'package:connectedu_app/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AnalyticsRepository {
  final ApiService _apiService;

  AnalyticsRepository(this._apiService);

  // For College Admin
  Future<AnalyticsData> getGlobalAnalytics() async {
    try {
      final response = await _apiService.dio.get('/api/analytics/global');
      return AnalyticsData.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching global analytics: $e');
      throw Exception('Failed to load analytics');
    }
  }

  // For Club Admin
  Future<AnalyticsData> getClubAnalytics(int clubId) async {
    try {
      final response = await _apiService.dio.get('/api/analytics/club/$clubId');
      return AnalyticsData.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching club analytics: $e');
      throw Exception('Failed to load analytics');
    }
  }
}