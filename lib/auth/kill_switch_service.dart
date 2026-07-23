import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class KillSwitchService {
  final String _baseUrl = 'http://10.0.2.2:5000';
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  // Send kill switch command
  Future<Map<String, dynamic>?> sendKillSwitchCommand({
    required String deviceUid,
    required String action,
    required String reason,
  }) async {
    try {
      final token = await _storage.read(key: 'jwt');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/kill-switch'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'device_uid': deviceUid,
          'action': action,
          'reason': reason,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to send kill switch command: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending kill switch command: $e');
      return null;
    }
  }

  // Get kill switch history
  Future<List<Map<String, dynamic>>?> getKillSwitchHistory(String deviceUid) async {
    try {
      final token = await _storage.read(key: 'jwt');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/kill-switch/$deviceUid'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['history'] ?? []);
      } else {
        throw Exception('Failed to get kill switch history: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting kill switch history: $e');
      return null;
    }
  }

  // Update command status
  Future<bool> updateCommandStatus({
    required String deviceUid,
    required String status,
    String? commandId,
  }) async {
    try {
      final token = await _storage.read(key: 'jwt');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/api/kill-switch/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'device_uid': deviceUid,
          'status': status,
          if (commandId != null) 'command_id': commandId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating command status: $e');
      return false;
    }
  }

  // Connect to Socket.io for real-time updates
  IO.Socket? connectToKillSwitchSocket({
    required String deviceUid,
    required Function(Map<String, dynamic>) onKillSwitchCommand,
    required Function() onConnect,
    required Function() onDisconnect,
    required Function(String) onError,
  }) {
    try {
      final socket = IO.io(_baseUrl, IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setQuery({'device_uid': deviceUid})
          .build());

      socket.onConnect((_) {
        print('Kill switch socket connected');
        onConnect();
      });

      socket.on('kill_switch_command', (data) {
        print('Kill switch command received: $data');
        onKillSwitchCommand(Map<String, dynamic>.from(data));
      });

      socket.onDisconnect((_) {
        print('Kill switch socket disconnected');
        onDisconnect();
      });

      socket.onError((error) {
        print('Kill switch socket error: $error');
        onError(error.toString());
      });

      return socket;
    } catch (e) {
      print('Error connecting to kill switch socket: $e');
      return null;
    }
  }
} 