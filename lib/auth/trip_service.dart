import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';

class TripService {
  final String baseUrl = 'http://10.0.2.2:5000';
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt');
  }

  // Fetch trips for a specific date
  Future<List<Map<String, dynamic>>?> fetchTrips(String deviceUid, String date) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('$baseUrl/api/trips/$deviceUid?date=$date'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['trips'] ?? []);
      } else {
        throw Exception('Failed to fetch trips (status ${response.statusCode})');
      }
    } catch (e) {
      print('Error fetching trips: $e');
      return null;
    }
  }

  // Fetch trip details by ID
  Future<Map<String, dynamic>?> fetchTripDetails(String deviceUid, String tripId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('$baseUrl/api/trips/$deviceUid/$tripId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['trip'];
      } else {
        throw Exception('Failed to fetch trip details (status ${response.statusCode})');
      }
    } catch (e) {
      print('Error fetching trip details: $e');
      return null;
    }
  }

  // Fetch available dates with trips
  Future<List<String>> fetchAvailableDates(String deviceUid) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('$baseUrl/api/trips/$deviceUid/dates'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['dates'] ?? []);
      } else {
        throw Exception('Failed to fetch available dates (status ${response.statusCode})');
      }
    } catch (e) {
      print('Error fetching available dates: $e');
      return [];
    }
  }

  // Connect to Socket.io for real-time trip updates
  Future<IO.Socket> connectToTripSocket({
    required String deviceUid,
    required Function(Map<String, dynamic>) onTripStarted,
    required Function(Map<String, dynamic>) onTripEnded,
    required Function(Map<String, dynamic>) onTripUpdated,
    required VoidCallback onConnect,
    required VoidCallback onDisconnect,
    required Function(String) onError,
  }) async {
    final token = await _getToken();
    return IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'query': {
        'device_uid': deviceUid,
        'token': token,
      },
    })
      ..connect()
      ..on('connect', (data) {
        print('Trip socket connected');
        onConnect();
      })
      ..on('disconnect', (data) {
        print('Trip socket disconnected');
        onDisconnect();
      })
      ..on('error', (data) {
        print('Trip socket error: $data');
        onError(data.toString());
      })
      ..on('trip_started', (data) {
        print('Trip started: $data');
        onTripStarted(data);
      })
      ..on('trip_ended', (data) {
        print('Trip ended: $data');
        onTripEnded(data);
      })
      ..on('trip_updated', (data) {
        print('Trip updated: $data');
        onTripUpdated(data);
      });
  }
} 