import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class AlertsService {
  final String _baseUrl = 'http://10.0.2.2:5000';
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<List<Map<String, dynamic>>?> fetchAlerts(String deviceUid) async {
    try {
      final token = await _storage.read(key: 'jwt');
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/alerts/$deviceUid'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['alerts'] ?? []);
      } else {
        throw Exception('Failed to fetch alerts (status ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error fetching alerts: $e');
    }
  }

  Future<bool> markAlertAsRead(String alertId) async {
    try {
      final token = await _storage.read(key: 'jwt');
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/api/alerts/$alertId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error marking alert as read: $e');
    }
  }

  Future<bool> markAllAsRead(String deviceUid) async {
    try {
      final token = await _storage.read(key: 'jwt');
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/api/alerts/$deviceUid/mark-all-read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error marking all alerts as read: $e');
    }
  }

  Future<bool> deleteAlert(String alertId) async {
    try {
      final token = await _storage.read(key: 'jwt');
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/api/alerts/$alertId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting alert: $e');
    }
  }

  IO.Socket? connectToAlertsSocket({
    required String deviceUid,
    required Function(Map<String, dynamic>) onNewAlert,
    required Function() onConnect,
    required Function() onDisconnect,
    required Function(String) onError,
  }) {
    final socket = IO.io(_baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'query': {
        'device_uid': deviceUid,
        'token': _storage.read(key: 'jwt'),
      },
    });

    socket.onConnect((_) {
      print('Alerts socket connected');
      onConnect();
    });

    socket.onDisconnect((_) {
      print('Alerts socket disconnected');
      onDisconnect();
    });

    socket.onError((error) {
      print('Alerts socket error: $error');
      onError(error.toString());
    });

    socket.on('new_alert', (data) {
      onNewAlert(Map<String, dynamic>.from(data));
    });

    return socket;
  }
} 