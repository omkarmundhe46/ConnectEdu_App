import 'dart:io';
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
}