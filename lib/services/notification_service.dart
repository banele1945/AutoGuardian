import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationService extends ChangeNotifier {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  
  bool _notificationsEnabled = true;
  bool _soundAlertsEnabled = true;
  bool _vibrationEnabled = true;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get soundAlertsEnabled => _soundAlertsEnabled;
  bool get vibrationEnabled => _vibrationEnabled;

  NotificationService() {
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final notifications = await _storage.read(key: 'notifications_enabled');
      final soundAlerts = await _storage.read(key: 'sound_alerts_enabled');
      final vibration = await _storage.read(key: 'vibration_enabled');

      _notificationsEnabled = notifications != 'false';
      _soundAlertsEnabled = soundAlerts != 'false';
      _vibrationEnabled = vibration != 'false';

      notifyListeners();
    } catch (e) {
      print('Error loading notification settings: $e');
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      await _storage.write(key: 'notifications_enabled', value: enabled.toString());
      _notificationsEnabled = enabled;
      notifyListeners();
    } catch (e) {
      print('Error saving notification setting: $e');
    }
  }

  Future<void> setSoundAlertsEnabled(bool enabled) async {
    try {
      await _storage.write(key: 'sound_alerts_enabled', value: enabled.toString());
      _soundAlertsEnabled = enabled;
      notifyListeners();
    } catch (e) {
      print('Error saving sound alerts setting: $e');
    }
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    try {
      await _storage.write(key: 'vibration_enabled', value: enabled.toString());
      _vibrationEnabled = enabled;
      notifyListeners();
    } catch (e) {
      print('Error saving vibration setting: $e');
    }
  }

  // Method to show notification based on settings
  void showNotification(BuildContext context, String title, String message, {String? alertType}) {
    if (!_notificationsEnabled) return;

    // Show snackbar notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _getNotificationColor(alertType),
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );

    // Play sound if enabled
    if (_soundAlertsEnabled) {
      _playNotificationSound(alertType);
    }

    // Vibrate if enabled
    if (_vibrationEnabled) {
      _vibrate(alertType);
    }
  }

  Color _getNotificationColor(String? alertType) {
    if (alertType == null) return Colors.blue;
    
    switch (alertType.toLowerCase()) {
      case 'kill_switch_activated':
      case 'tampering':
      case 'unauthorized_access':
        return Colors.red;
      case 'low_battery':
      case 'touch_detection':
        return Colors.orange;
      case 'engine_start':
      case 'engine_stop':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  void _playNotificationSound(String? alertType) {
    // TODO: Implement actual sound playing
    // This would integrate with a sound library like audioplayers
    print('Playing notification sound for: $alertType');
  }

  void _vibrate(String? alertType) {
    // TODO: Implement actual vibration
    // This would integrate with vibration library
    print('Vibrating for alert: $alertType');
  }

  // Method to check if location tracking is enabled
  Future<bool> isLocationTrackingEnabled() async {
    try {
      final setting = await _storage.read(key: 'location_tracking_enabled');
      return setting != 'false';
    } catch (e) {
      print('Error checking location tracking setting: $e');
      return true; // Default to enabled
    }
  }

  // Method to check if auto-arm is enabled
  Future<bool> isAutoArmEnabled() async {
    try {
      final setting = await _storage.read(key: 'auto_arm_enabled');
      return setting != 'false';
    } catch (e) {
      print('Error checking auto-arm setting: $e');
      return true; // Default to enabled
    }
  }
} 