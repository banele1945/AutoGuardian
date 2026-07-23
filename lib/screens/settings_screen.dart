import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/notification_service.dart';
import '../auth/password_change_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Color mainBlue = const Color(0xFF1565C0);
  final Color accentBlue = const Color(0xFF42A5F5);
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final PasswordChangeService _passwordChangeService = PasswordChangeService();

  // Settings state
  bool _notificationsEnabled = true;
  bool _locationTrackingEnabled = true;

  bool _soundAlertsEnabled = true;
  bool _vibrationEnabled = true;
  String _mapType = 'standard';
  String _language = 'English';
  String _theme = 'Light';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final notifications = await _storage.read(key: 'notifications_enabled');
      final locationTracking = await _storage.read(key: 'location_tracking_enabled');

      final soundAlerts = await _storage.read(key: 'sound_alerts_enabled');
      final vibration = await _storage.read(key: 'vibration_enabled');
      final mapType = await _storage.read(key: 'map_type');
      final language = await _storage.read(key: 'language');
      final theme = await _storage.read(key: 'theme');

      if (mounted) {
        setState(() {
          _notificationsEnabled = notifications != 'false';
          _locationTrackingEnabled = locationTracking != 'false';

          _soundAlertsEnabled = soundAlerts != 'false';
          _vibrationEnabled = vibration != 'false';
          _mapType = mapType ?? 'standard';
          _language = language ?? 'English';
          _theme = theme ?? 'Light';
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  Future<void> _saveSetting(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      print('Error saving setting: $e');
    }
  }

  Future<void> _saveBoolSetting(String key, bool value) async {
    await _saveSetting(key, value.toString());
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: mainBlue,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: mainBlue),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: mainBlue,
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    String? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: mainBlue),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
      trailing: trailing != null 
        ? Text(trailing, style: GoogleFonts.poppins(color: mainBlue, fontWeight: FontWeight.w500))
        : Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: mainBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Notifications Section
          _buildSectionHeader('Notifications'),
          _buildSwitchTile(
            title: 'Push Notifications',
            subtitle: 'Receive alerts and updates',
            value: _notificationsEnabled,
            onChanged: (value) async {
              setState(() => _notificationsEnabled = value);
              await _saveBoolSetting('notifications_enabled', value);
              // Update notification service
              final notificationService = Provider.of<NotificationService>(context, listen: false);
              await notificationService.setNotificationsEnabled(value);
            },
            icon: Icons.notifications,
          ),
          _buildSwitchTile(
            title: 'Sound Alerts',
            subtitle: 'Play sounds for important alerts',
            value: _soundAlertsEnabled,
            onChanged: (value) async {
              setState(() => _soundAlertsEnabled = value);
              await _saveBoolSetting('sound_alerts_enabled', value);
              // Update notification service
              final notificationService = Provider.of<NotificationService>(context, listen: false);
              await notificationService.setSoundAlertsEnabled(value);
            },
            icon: Icons.volume_up,
          ),
          _buildSwitchTile(
            title: 'Vibration',
            subtitle: 'Vibrate for critical alerts',
            value: _vibrationEnabled,
            onChanged: (value) async {
              setState(() => _vibrationEnabled = value);
              await _saveBoolSetting('vibration_enabled', value);
              // Update notification service
              final notificationService = Provider.of<NotificationService>(context, listen: false);
              await notificationService.setVibrationEnabled(value);
            },
            icon: Icons.vibration,
          ),

          // Security Section
          _buildSectionHeader('Security'),
          _buildSwitchTile(
            title: 'Location Tracking',
            subtitle: 'Track vehicle location in real-time',
            value: _locationTrackingEnabled,
            onChanged: (value) {
              setState(() => _locationTrackingEnabled = value);
              _saveBoolSetting('location_tracking_enabled', value);
            },
            icon: Icons.location_on,
          ),


          // Map Settings
          _buildSectionHeader('Map Settings'),
          _buildListTile(
            title: 'Map Type',
            subtitle: 'Choose your preferred map style',
            icon: Icons.map,
            trailing: _mapType.capitalize(),
            onTap: () {
              _showMapTypeDialog();
            },
          ),

          // App Settings
          _buildSectionHeader('App Settings'),
          _buildListTile(
            title: 'Language',
            subtitle: 'Choose your preferred language',
            icon: Icons.language,
            trailing: _language,
            onTap: () {
              _showLanguageDialog();
            },
          ),
          _buildListTile(
            title: 'Theme',
            subtitle: 'Choose light or dark theme',
            icon: Icons.palette,
            trailing: _theme,
            onTap: () {
              _showThemeDialog();
            },
          ),

          // Account Section
          _buildSectionHeader('Account'),
          _buildListTile(
            title: 'Change Password',
            subtitle: 'Update your account password',
            icon: Icons.lock,
            onTap: () {
              _showChangePasswordDialog();
            },
          ),
          _buildListTile(
            title: 'Device Information',
            subtitle: 'View connected device details',
            icon: Icons.device_hub,
            onTap: () {
              _showDeviceInfoDialog();
            },
          ),

          // About Section
          _buildSectionHeader('About'),
          _buildListTile(
            title: 'App Version',
            subtitle: 'Current version information',
            icon: Icons.info,
            trailing: '1.0.0',
            onTap: () {
              _showAboutDialog();
            },
          ),
          _buildListTile(
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            icon: Icons.privacy_tip,
            onTap: () {
              _showPrivacyPolicyDialog();
            },
          ),
          _buildListTile(
            title: 'Terms of Service',
            subtitle: 'Read our terms of service',
            icon: Icons.description,
            onTap: () {
              _showTermsDialog();
            },
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showMapTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Map Type', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('Standard'),
              value: 'standard',
              groupValue: _mapType,
              onChanged: (value) {
                setState(() => _mapType = value!);
                _saveSetting('map_type', value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('Satellite'),
              value: 'satellite',
              groupValue: _mapType,
              onChanged: (value) {
                setState(() => _mapType = value!);
                _saveSetting('map_type', value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('Hybrid'),
              value: 'hybrid',
              groupValue: _mapType,
              onChanged: (value) {
                setState(() => _mapType = value!);
                _saveSetting('map_type', value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('Terrain'),
              value: 'terrain',
              groupValue: _mapType,
              onChanged: (value) {
                setState(() => _mapType = value!);
                _saveSetting('map_type', value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Language', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('English'),
              value: 'English',
              groupValue: _language,
              onChanged: (value) {
                setState(() => _language = value!);
                _saveSetting('language', value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Theme', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('Light'),
              value: 'Light',
              groupValue: _theme,
              onChanged: (value) async {
                setState(() => _theme = value!);
                await _saveSetting('theme', value!);
                // Update theme service
                final themeService = Provider.of<ThemeService>(context, listen: false);
                await themeService.setTheme(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('Dark'),
              value: 'Dark',
              groupValue: _theme,
              onChanged: (value) async {
                setState(() => _theme = value!);
                await _saveSetting('theme', value!);
                // Update theme service
                final themeService = Provider.of<ThemeService>(context, listen: false);
                await themeService.setTheme(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('Auto'),
              value: 'Auto',
              groupValue: _theme,
              onChanged: (value) async {
                setState(() => _theme = value!);
                await _saveSetting('theme', value!);
                // Update theme service
                final themeService = Provider.of<ThemeService>(context, listen: false);
                await themeService.setTheme(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool _isLoading = false;
    bool _showCurrentPassword = false;
    bool _showNewPassword = false;
    bool _showConfirmPassword = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Change Password', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current Password
              TextField(
                controller: currentPasswordController,
                obscureText: !_showCurrentPassword,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_showCurrentPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setDialogState(() {
                        _showCurrentPassword = !_showCurrentPassword;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 12),
              
              // New Password
              TextField(
                controller: newPasswordController,
                obscureText: !_showNewPassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_showNewPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setDialogState(() {
                        _showNewPassword = !_showNewPassword;
                      });
                    },
                  ),
                ),
                onChanged: (value) {
                  // Show password strength indicator
                  if (value.isNotEmpty) {
                    final strength = _passwordChangeService.getPasswordStrength(value);
                    // You can add a strength indicator widget here
                  }
                },
              ),
              SizedBox(height: 8),
              
              // Password strength indicator
              if (newPasswordController.text.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Text(
                        'Password strength: ${_passwordChangeService.getPasswordStrength(newPasswordController.text)['strength']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 12),
              
              // Confirm Password
              TextField(
                controller: confirmPasswordController,
                obscureText: !_showConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_showConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setDialogState(() {
                        _showConfirmPassword = !_showConfirmPassword;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                setDialogState(() {
                  _isLoading = true;
                });

                try {
                  final result = await _passwordChangeService.changePassword(
                    currentPassword: currentPasswordController.text,
                    newPassword: newPasswordController.text,
                    confirmPassword: confirmPasswordController.text,
                  );

                  Navigator.pop(context);

                  if (result['success']) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message']),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['error']),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              },
              child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text('Change Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: mainBlue)
            ),
          ],
        ),
      ),
    );
  }

  void _showDeviceInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Device Information', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Device ID', 'ESP32-123456'),
            _buildInfoRow('Device Type', 'ESP32 Microcontroller'),
            _buildInfoRow('Connection', 'Connected'),
            _buildInfoRow('Last Seen', '2 minutes ago'),
            _buildInfoRow('Firmware Version', 'v1.2.0'),
            _buildInfoRow('Signal Strength', 'Strong'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
            style: ElevatedButton.styleFrom(backgroundColor: mainBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About AutoGuardian', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0', style: GoogleFonts.poppins()),
            Text('Build: 2024.01.15', style: GoogleFonts.poppins()),
            SizedBox(height: 8),
            Text(
              'AutoGuardian is a comprehensive vehicle security system that provides real-time monitoring, GPS tracking, and remote control capabilities.',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
            style: ElevatedButton.styleFrom(backgroundColor: mainBlue),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Privacy Policy', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            'Your privacy is important to us. This app collects location data and vehicle information to provide security services. All data is encrypted and stored securely.',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
            style: ElevatedButton.styleFrom(backgroundColor: mainBlue),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Terms of Service', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            'By using AutoGuardian, you agree to our terms of service. The app is provided "as is" and we are not responsible for any damages or losses.',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
            style: ElevatedButton.styleFrom(backgroundColor: mainBlue),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
} 