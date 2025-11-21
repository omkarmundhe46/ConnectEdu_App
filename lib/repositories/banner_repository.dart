import 'dart:io';
import 'package:connectedu_app/models/banner_model.dart';
import 'package:connectedu_app/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class BannerRepository {
  final ApiService _apiService;

  BannerRepository(this._apiService);

  // 1. Get Active Banners (Public - for Home Screen)
  Future<List<BannerModel>> getActiveBanners() async {
    try {
      final response = await _apiService.dio.get('/api/banners/active');
      final data = response.data as List;
      return data.map((json) => BannerModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching active banners: $e');
      return []; // Return empty list on error to avoid crashing UI
    }
  }

  // 2. Get Banners for a specific Club (For Club Admins)
  Future<List<BannerModel>> getClubBanners(int clubId) async {
    try {
      final response = await _apiService.dio.get('/api/banners/club/$clubId');
      final data = response.data as List;
      return data.map((json) => BannerModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load club banners: $e');
    }
  }

  // 3. Get College Banners (For College Admin)
  Future<List<BannerModel>> getCollegeBanners() async {
    try {
      final response = await _apiService.dio.get('/api/banners/college');
      final data = response.data as List;
      return data.map((json) => BannerModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load college banners: $e');
    }
  }

  // 4. Upload Image (Reusing your generic upload endpoint)
  Future<String> uploadBannerImage(File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _apiService.dio.post('/api/uploads', data: formData);
      return response.data['fileUrl'];
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // 5. Create Banner
  Future<void> createBanner({
    required String title,
    required String imageUrl,
    String? linkUrl,
    int? clubId,
  }) async {
    try {
      await _apiService.dio.post('/api/banners', data: {
        'title': title,
        'imageUrl': imageUrl,
        'linkUrl': linkUrl,
        'clubId': clubId,
      });
    } catch (e) {
      throw Exception('Failed to create banner: $e');
    }
  }

  // 6. Delete Banner
  Future<void> deleteBanner(int bannerId) async {
    try {
      await _apiService.dio.delete('/api/banners/$bannerId');
    } catch (e) {
      throw Exception('Failed to delete banner: $e');
    }
  }
}