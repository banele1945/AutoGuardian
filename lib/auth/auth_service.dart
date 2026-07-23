import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  // Use 10.0.2.2 for Android emulator to access host machine's localhost
  static const String _baseUrl = 'http://10.0.2.2:5000/api';
  static const _storage = FlutterSecureStorage();
  final Dio _dio = Dio();

  Future<String?> login({required String username, required String password}) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );
      if (response.statusCode == 200 && response.data['token'] != null) {
        await _storage.write(key: 'jwt', value: response.data['token']);
        // Store password for kill switch verification
        await _storage.write(key: 'user_password', value: password);
        return null; // Success
      } else {
        return 'Invalid response from server.';
      }
    } catch (e) {
      if (e is DioError && e.response != null) {
        return e.response?.data['message'] ?? 'Login failed.';
      }
      return 'Login failed. Please check your connection.';
    }
  }

  Future<String?> register({required String username, required String password}) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/auth/registration',
        data: {
          'username': username,
          'password': password,
        },
      );
      if (response.statusCode == 200) {
        return null; // Success
      } else {
        return 'Registration failed.';
      }
    } catch (e) {
      if (e is DioError && e.response != null) {
        return e.response?.data['message'] ?? 'Registration failed.';
      }
      return 'Registration failed. Please check your connection.';
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt');
    await _storage.delete(key: 'user_password'); // Clear stored password for security
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt');
  }

  Future<bool> isPasswordVerificationAvailable() async {
    final password = await _storage.read(key: 'user_password');
    return password != null && password.isNotEmpty;
  }

  Future<String?> getUsername() async {
    try {
      final token = await _storage.read(key: 'jwt');
      if (token == null) return null;

      final response = await _dio.get(
        '$_baseUrl/auth/profile',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200 && response.data['username'] != null) {
        return response.data['username'];
      }
      return null;
    } catch (e) {
      print('Error getting username: $e');
      return null;
    }
  }
} 