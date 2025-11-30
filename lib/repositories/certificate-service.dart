import 'dart:io';
import 'package:connectedu_app/models/certificate_template.dart';
import 'package:connectedu_app/models/event_certificate_config.dart';
import 'package:connectedu_app/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class CertificateRepository {
  final ApiService _apiService;
  CertificateRepository(this._apiService);

  /// Downloads the user's certificate for a specific event
  /// and opens it using the device's default PDF viewer.
  Future<void> downloadCertificate(int eventId, int userId, String eventName) async {
    try {
      // 1. Get the app's temporary directory (no permissions needed)
      final directory = await getTemporaryDirectory();

      // Sanitize the event name for the filename
      final safeEventName = eventName.replaceAll(RegExp(r'[\s\W]+'), '_');
      final filePath = '${directory.path}/Certificate_$safeEventName.pdf';
      final file = File(filePath);

      debugPrint('Downloading certificate to: $filePath');

      // 2. Use Dio to download the file from the backend
      // The ApiService interceptor will automatically add the auth token.
      await _apiService.dio.download(
        '/api/certificates/event/$eventId/user/$userId/download',
        file.path,
        options: Options(
          responseType: ResponseType.bytes, // Important for file downloads
        ),
      );

      debugPrint('Download complete.');

      // 3. Open the downloaded file using the open_file package
      final openResult = await OpenFile.open(file.path);
      if (openResult.type != ResultType.done) {
        debugPrint('Could not open file: ${openResult.message}');
        throw Exception('Could not open the downloaded file: ${openResult.message}');
      }
    } on DioException catch (e) {
      debugPrint('Failed to download certificate: ${e.response?.data ?? e.message}');
      // Handle backend error (e.g., 425 Too Early)
      if (e.response?.statusCode == 425) {
        throw Exception('Certificate is not yet available for download.');
      }
      throw Exception('Failed to download certificate.');
    } catch (e) {
      debugPrint('Failed to download/open certificate: $e');
      throw Exception(e.toString());
    }
  }


  // 1. Get Available Templates
  Future<List<CertificateTemplate>> getTemplates(String? category) async {
    try {
      final response = await _apiService.dio.get(
        '/api/certificates/config/templates',
        queryParameters: category != null ? {'category': category} : null,
      );
      final data = response.data as List;
      return data.map((json) => CertificateTemplate.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching templates: $e');
      return [];
    }
  }

  // 2. Get Existing Config
  Future<EventCertificateConfig?> getConfig(int eventId) async {
    try {
      final response = await _apiService.dio.get('/api/certificates/config/event/$eventId');
      if (response.data == null || response.data == "") return null;
      return EventCertificateConfig.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  // 3. Save Config (Updated to match new simplified backend)
  Future<void> saveConfig(int eventId, String templateId) async {
    try {
      await _apiService.dio.post(
        '/api/certificates/config/event/$eventId',
        queryParameters: {'template': templateId},
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to save certificate config');
    } catch (e) {
      throw Exception('Failed to save config: $e');
    }
  }

  // 4. Reuse the DiscussionRepository's uploadFile logic?
  // Ideally, you should move 'uploadFile' to a shared 'FileRepository' or keep using DiscussionRepository.
  // For now, let's assume you can access the upload endpoint here too.
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