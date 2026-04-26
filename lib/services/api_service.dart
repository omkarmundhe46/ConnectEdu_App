  // import 'package:connectedu_app/services/secure_storage_service.dart';
  // import 'package:dio/dio.dart';
  // import 'package:flutter/foundation.dart';
  //
  // class ApiService {
  //   final Dio _dio;
  //   final SecureStorageService _secureStorageService;
  //
  //
  //   static const String _baseUrl = kIsWeb ? 'http://localhost:8080' : 'http://10.218.112.92:8080';   // run on docker and run on phone
  //   // static const String _baseUrl = 'https://toniest-wilda-unfabulously.ngrok-free.dev';             //  with docker for oauth
  //   // static const String _baseUrl = 'https://0f10b25c57287b.lhr.life';             //  with docker for oauth
  //
  //   // static const String _baseUrl = 'http://10.82.198.92:8080'; // <-- Use YOUR phone address
  //
  //   static const String websocketUrl = kIsWeb ? 'ws://localhost:8080/ws' : 'ws://10.218.112.92:8080/ws';
  //
  //   ApiService(this._secureStorageService)
  //       : _dio = Dio(BaseOptions(
  //     baseUrl: _baseUrl,
  //     contentType: Headers.jsonContentType, // Default to JSON
  //   )) {
  //     // Add Interceptor to attach Token automatically
  //     _dio.interceptors.add(
  //       InterceptorsWrapper(
  //         onRequest: (options, handler) async {
  //           final token = await _secureStorageService.getToken();
  //           if (token != null) {
  //             options.headers['Authorization'] = 'Bearer $token';
  //           }
  //           // ADD THIS LINE TO BYPASS NGROK BROWSER WARNING
  //           options.headers['ngrok-skip-browser-warning'] = 'true';
  //           return handler.next(options);
  //         },
  //         onError: (DioException e, handler) {
  //           debugPrint('API Error: ${e.response?.statusCode} - ${e.response?.data}');
  //           return handler.next(e);
  //         },
  //       ),
  //     );
  //   }
  //
  //   Dio get dio => _dio;
  //
  //   Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
  //     return await _dio.get(path, queryParameters: queryParameters);
  //   }
  //
  //   Future<Response> post(String path, dynamic data) async {
  //     return await _dio.post(path, data: data);
  //   }
  // }


  import 'package:connectedu_app/services/secure_storage_service.dart';
  import 'package:dio/dio.dart';
  import 'package:flutter/foundation.dart';

  class ApiService {
    final Dio _dio;
    final SecureStorageService _secureStorageService;

    // // 1. UPDATE BASE URL TO YOUR PUBLIC TUNNEL
    // static const String _baseUrl = kIsWeb
    //     ? 'http://localhost:8080'
    //     : 'https://00040b541a3df9.lhr.life';
    //
    // // 2. UPDATE WEBSOCKET TO USE "wss://" FOR SECURE CONNECTIONS
    // static const String websocketUrl = kIsWeb
    //     ? 'ws://localhost:8080/ws'
    //     : 'wss://00040b541a3df9.lhr.life/ws';

    static const String _baseUrl = kIsWeb
        ? 'http://localhost:8080'
        : 'https://toniest-wilda-unfabulously.ngrok-free.dev';

    static const String websocketUrl = kIsWeb
        ? 'ws://localhost:8080/ws'
        : 'wss://toniest-wilda-unfabulously.ngrok-free.dev/ws';

    ApiService(this._secureStorageService)
        : _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      contentType: Headers.jsonContentType,
    )) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final token = await _secureStorageService.getToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            // You can actually remove the ngrok skip line if using localhost.run,
            // but leaving it hurts nothing.
            options.headers['ngrok-skip-browser-warning'] = 'true';
            return handler.next(options);
          },
          onError: (DioException e, handler) {
            debugPrint('API Error: ${e.response?.statusCode} - ${e.response?.data}');
            return handler.next(e);
          },
        ),
      );
    }

    Dio get dio => _dio;

    Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
      return await _dio.get(path, queryParameters: queryParameters);
    }

    Future<Response> post(String path, dynamic data) async {
      return await _dio.post(path, data: data);
    }
  }