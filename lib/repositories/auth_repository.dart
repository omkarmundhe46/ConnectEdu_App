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

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      debugPrint('Attempting to change password...');
      final response = await _apiService.dio.post(
        '/api/users/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('Password change successful.');
      } else {
        throw Exception('Password change failed: ${response.data}');
      }
    } on DioException catch (e) {
      debugPrint('Change password API error: ${e.response?.data ?? e.message}');
      throw Exception(e.response?.data ?? 'An error occurred.');
    } catch (e) {
      debugPrint('Change password error: $e');
      throw Exception(e.toString());
    }
  }
  Future<void> verifyResetOtp({required String email, required String otp}) async {
    try {
      debugPrint('Verifying reset OTP...');
      final response = await _apiService.dio.post(
        '/auth/verify-reset-otp',
        data: {'email': email, 'otp': otp},
      );

      if (response.statusCode == 200) {
        debugPrint('OTP is valid.');
      } else {
        throw Exception('Invalid OTP.');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Invalid OTP.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      debugPrint('Requesting password reset for: $email');
      final response = await _apiService.dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        debugPrint('Password reset OTP sent.');
      } else {
        throw Exception('Request failed: ${response.data}');
      }
    } on DioException catch (e) {
      debugPrint('Reset request API error: ${e.response?.data ?? e.message}');
      // Extract clean error message if possible
      throw Exception(e.response?.data ?? 'Failed to send reset code.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      debugPrint('Resetting password...');
      final response = await _apiService.dio.post(
        '/auth/reset-password-with-otp',
        data: {
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('Password reset successful.');
      } else {
        throw Exception('Reset failed: ${response.data}');
      }
    } on DioException catch (e) {
      debugPrint('Reset API error: ${e.response?.data ?? e.message}');
      throw Exception(e.response?.data ?? 'Failed to reset password.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<User> loginWithToken(String token) async {
    try {
      debugPrint('Logging in with received token...');
      await _secureStorageService.saveToken(token);

      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final user = User.fromToken(decodedToken);

      debugPrint('Token saved and user created: ${user.email}');
      return user;
    } catch (e) {
      debugPrint('Failed to login with token: $e');
      throw Exception('Invalid token received.');
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String department,
  }) async {
    try {
      debugPrint('Attempting registration for: $email');
      final response = await _apiService.dio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'department': department,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Registration successful for: $email. Verification required.');
        // No token is returned, so we just return successfully.
      } else {
        debugPrint('Registration failed with status: ${response.statusCode}');
        throw Exception('Registration failed: ${response.data}');
      }
    } on DioException catch (e) {
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

  Future<void> verifyOtp({required String email, required String otp}) async {
    try {
      debugPrint('Attempting to verify OTP for: $email');
      final response = await _apiService.dio.post(
        '/auth/verify-otp',
        data: {'email': email, 'otp': otp},
      );

      if (response.statusCode == 200) {
        debugPrint('OTP verification successful.');
      } else {
        throw Exception('OTP verification failed: ${response.data}');
      }
    } on DioException catch (e) {
      debugPrint('OTP verification API error: ${e.response?.data ?? e.message}');
      throw Exception(e.response?.data ?? 'Invalid or expired OTP.');
    } catch (e) {
      debugPrint('OTP verification error: $e');
      throw Exception(e.toString());
    }
  }

  Future<void> resendOtp({required String email}) async {
    try {
      debugPrint('Attempting to resend OTP to: $email');
      final response = await _apiService.dio.post(
        '/auth/resend-otp',
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        debugPrint('Resend OTP request successful.');
      } else {
        throw Exception('Resend OTP failed: ${response.data}');
      }
    } on DioException catch (e) {
      debugPrint('Resend OTP API error: ${e.response?.data ?? e.message}');
      throw Exception(e.response?.data ?? 'Could not resend code.');
    } catch (e) {
      debugPrint('Resend OTP error: $e');
      throw Exception(e.toString());
    }
  }
}