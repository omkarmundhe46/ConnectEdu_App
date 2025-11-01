  import 'package:connectedu_app/services/secure_storage_service.dart';
  import 'package:dio/dio.dart';
  import 'package:flutter/foundation.dart';
  
  class ApiService {
    final Dio _dio;
    final SecureStorageService _secureStorageService;
  
    // Use 10.0.2.2 for the Android Emulator to connect to localhost on your machine.
    // For a real device, you must use your computer's network IP address.
    static const String _baseUrl = kIsWeb ? 'http://localhost:8080' : 'http://10.82.198.92:8080';
  
    ApiService(this._secureStorageService) : _dio = Dio(BaseOptions(baseUrl: _baseUrl)) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final token = await _secureStorageService.getToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            return handler.next(options);
          },
          onError: (DioException e, handler) {
            // You can add global error handling here, e.g., for 401 Unauthorized
            debugPrint('API Error: ${e.response?.statusCode} - ${e.response?.data}');
            return handler.next(e);
          },
        ),
      );
    }
  
    Dio get dio => _dio;
  }
  
