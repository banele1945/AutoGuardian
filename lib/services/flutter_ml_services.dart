import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// AutoGuardian ML Service for Flutter App
/// Handles AI/ML integration and anomaly alerts
class AutoGuardianMLService {
  final String baseUrl;
  final String apiKey;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  AutoGuardianMLService({
    required this.baseUrl,
    required this.apiKey,
  }) {
    _initializeNotifications();
  }

  /// Initialize local notifications
  void _initializeNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    _notifications.initialize(initializationSettings);
  }

  /// Get anomaly prediction from ML API
  Future<Map<String, dynamic>> predictAnomaly(Map<String, dynamic> vehicleData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/predict'),
        headers: {
          'Authorization': 'ApiKey $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(vehicleData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to predict anomaly: ${response.statusCode}');
      }
    } catch (e) {
      print('ML API Error: $e');
      rethrow;
    }
  }

  /// Get user statistics from ML API
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_stats'),
        headers: {
          'Authorization': 'ApiKey $apiKey',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get stats: ${response.statusCode}');
      }
    } catch (e) {
      print('ML Stats Error: $e');
      throw Exception('Unable to connect to AI/ML service. Please check your connection and try again.');
    }
  }

  /// Train AI models for user
  Future<Map<String, dynamic>> trainModels() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/train_models'),
        headers: {
          'Authorization': 'ApiKey $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to train models: ${response.statusCode}');
      }
    } catch (e) {
      print('ML Training Error: $e');
      throw Exception('Unable to train AI models. Please check your connection and try again.');
    }
  }

  /// Update anomaly thresholds
  Future<Map<String, dynamic>> updateThresholds(Map<String, dynamic> thresholds) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update_thresholds'),
        headers: {
          'Authorization': 'ApiKey $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(thresholds),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update thresholds: ${response.statusCode}');
      }
    } catch (e) {
      print('ML Threshold Update Error: $e');
      rethrow;
    }
  }

  /// Show local notification for anomaly
  Future<void> showAnomalyNotification(Map<String, dynamic> anomalyData) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'autoguardian_anomaly',
      'Vehicle Anomaly Alerts',
      channelDescription: 'Alerts for vehicle anomalies detected by AI',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notifications.show(
      0,
      '🚨 Vehicle Anomaly Detected',
      anomalyData['reason'] ?? 'Unusual driving pattern detected',
      platformChannelSpecifics,
      payload: jsonEncode(anomalyData),
    );
  }

  /// Handle FCM notification for anomaly
  Future<void> handleAnomalyNotification(RemoteMessage message) async {
    try {
      final data = message.data;
      
      if (data['type'] == 'anomaly') {
        // Show local notification
        await showAnomalyNotification({
          'reason': data['reason'] ?? 'Anomaly detected',
          'confidence': double.tryParse(data['confidence'] ?? '0') ?? 0.0,
          'timestamp': data['timestamp'],
          'location': data['location'],
        });

        // Navigate to anomaly details screen
        // You can implement navigation logic here
        print('Anomaly notification received: ${data['reason']}');
      }
    } catch (e) {
      print('Error handling anomaly notification: $e');
    }
  }

  /// Get anomaly history from server
  Future<Map<String, dynamic>> getAnomalyHistory({int page = 1, int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/anomalies?page=$page&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get anomaly history: ${response.statusCode}');
      }
    } catch (e) {
      print('Anomaly History Error: $e');
      throw Exception('Unable to load anomaly history. Please check your connection and try again.');
    }
  }
}

/// Anomaly Alert Widget for Flutter UI
class AnomalyAlertWidget extends StatelessWidget {
  final Map<String, dynamic> anomalyData;
  final VoidCallback? onDismiss;

  const AnomalyAlertWidget({
    Key? key,
    required this.anomalyData,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red.shade600, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '🚨 Anomaly Detected',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red.shade600),
                  onPressed: onDismiss,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            anomalyData['reason'] ?? 'Unusual driving pattern detected',
            style: TextStyle(
              color: Colors.red.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Confidence: ${(anomalyData['confidence'] * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              if (anomalyData['timestamp'] != null)
                Text(
                  _formatTimestamp(anomalyData['timestamp']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
          if (anomalyData['location'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey.shade600, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${anomalyData['location']['latitude']?.toStringAsFixed(4)}, ${anomalyData['location']['longitude']?.toStringAsFixed(4)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}

/// ML Statistics Widget
class MLStatsWidget extends StatelessWidget {
  final Map<String, dynamic> stats;

  const MLStatsWidget({
    Key? key,
    required this.stats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              Text(
                'AI/ML Statistics',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Data Points',
                  '${stats['total_data_points'] ?? 0}',
                  Icons.data_usage,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Models Trained',
                  stats['models_trained'] == true ? 'Yes' : 'No',
                  Icons.model_training,
                ),
              ),
            ],
          ),
          if (stats['avg_speed'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Avg Speed',
                    '${stats['avg_speed'].toStringAsFixed(1)} km/h',
                    Icons.speed,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Max Speed',
                    '${stats['max_speed'].toStringAsFixed(1)} km/h',
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 