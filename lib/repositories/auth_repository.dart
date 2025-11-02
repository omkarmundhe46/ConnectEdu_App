import 'package:connectedu_app/models/user.dart';
import 'package:connectedu_app/services/api_service.dart';
import 'package:connectedu_app/services/secure_storage_service.dart';
import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint

class AuthRepository {
  final ApiService _apiService;
  final SecureStorageService _secureStorageService;

  AuthRepository(this._apiService, this._secureStorageService);


  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String department, // Add department
  }) async {
    try {
      debugPrint('Attempting registration for: $email');
      final response = await _apiService.dio.post(
        '/auth/register', // Use the correct public endpoint
        data: {
          'name': name,
          'email': email,
          'password': password,
          'department': department, // Send department
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Registration successful for: $email');
        return true; // Indicate success
      } else {
        debugPrint('Registration failed with status: ${response.statusCode}');
        throw Exception('Registration failed: ${response.data}');
      }
    } on DioException catch (e) { // Catch Dio specific errors
      debugPrint('Registration API error: ${e.response?.data ?? e.message}');
      throw Exception('Registration failed: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      debugPrint('Registration error: $e');
      throw Exception('Registration failed: ${e.toString()}');
    }
  }


  Future<User> login(String email, String password) async {
    try {
      debugPrint('Attempting login for: $email');
      final response = await _apiService.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data != null) {
        final String token = response.data['token'];
        debugPrint('Login successful, received token: $token');
        await _secureStorageService.saveToken(token);

        // Decode token to get user details
        final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        debugPrint('Decoded token: $decodedToken');

        // --- FIX 1: Pass the Map, not a String ---
        // Remove the incorrect 'as String' cast
        final user = User.fromToken(decodedToken);

        return user;
      } else {
        debugPrint('Login failed with status: ${response.statusCode}');
        throw Exception('Login failed');
      }
    } catch (e) {
      debugPrint('Login error: $e');
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    await _secureStorageService.deleteToken();
  }

  Future<bool> hasToken() async {
    final token = await _secureStorageService.getToken();
    return token != null;
  }

  Future<User?> getUserFromToken() async {
    final token = await _secureStorageService.getToken();
    if (token != null) {
      try {
        // --- FIX 2: Decode the token string FIRST, then pass the Map ---
        final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        return User.fromToken(decodedToken);
      } catch (e) {
        debugPrint('Error decoding token or creating user: $e');
        await logout(); // Log out if token is invalid
        return null;
      }
    }
    return null;
  }

  Future<User> updateProfile({String? phone, String? profileImageUrl}) async {
    try {
      debugPrint('Attempting to update profile...');
      final response = await _apiService.dio.put(
        '/api/users/profile',
        data: {
          'phone': phone,
          'profileImageUrl': profileImageUrl,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final String token = response.data['token'];
        debugPrint('Profile update successful, received new token.');
        await _secureStorageService.saveToken(token); // Save the new token

        final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        final user = User.fromToken(decodedToken);
        return user;
      } else {
        debugPrint('Profile update failed with status: ${response.statusCode}');
        throw Exception('Profile update failed');
      }
    } on DioException catch (e) {
      debugPrint('Profile update API error: ${e.response?.data ?? e.message}');
      throw Exception('Profile update failed: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      debugPrint('Profile update error: $e');
      throw Exception('Profile update failed: ${e.toString()}');
    }
  }

}