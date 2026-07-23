import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CarStatusService {
  static const String _baseUrl = 'http://10.0.2.2:5000/api';
  static const _storage = FlutterSecureStorage();
  final Dio _dio = Dio();

  Future<Map<String, dynamic>?> fetchCarStatus(String deviceUid) async {
    final token = await _storage.read(key: 'jwt');
    if (token == null) return null;
    try {
      final response = await _dio.get(
        '$_baseUrl/car-status/$deviceUid',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
} 