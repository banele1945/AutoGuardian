import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/car_status_service.dart';
import '../auth/kill_switch_service.dart';
import '../auth/auth_service.dart';
import '../auth/alerts_service.dart';
import '../widgets/password_confirmation_dialog.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../screens/alert_detail_screen.dart'; // Added import for AlertDetailScreen

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final Color mainBlue = const Color(0xFF1565C0);
  final Color accentBlue = const Color(0xFF42A5F5);
  final String deviceUid = 'ESP32-123456'; // Hardcoded for demo
  final CarStatusService _carStatusService = CarStatusService();
  final KillSwitchService _killSwitchService = KillSwitchService();
  final AuthService _authService = AuthService();
  final AlertsService _alertsService = AlertsService();
  
  String _username = 'User'; // Default username

  Map<String, dynamic>? _carStatus;
  bool _loading = true;
  String? _error;
  bool _killSwitchLoading = false;
  String _systemStatus = 'UNKNOWN'; // ARMED, DISARMED, KILLED
  bool _passwordAvailable = false;
  List<Map<String, dynamic>> _recentAlerts = [];
  int _unreadAlertCount = 0;
  IO.Socket? _killSwitchSocket;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserInfo();
    _fetchCarStatus();
    _connectToKillSwitchSocket();
    _checkPasswordAvailability();
    _fetchAlerts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh alerts when screen becomes active
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAlerts();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _killSwitchSocket?.disconnect();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh alerts when app becomes active
    if (state == AppLifecycleState.resumed) {
      _fetchAlerts();
    }
  }

  // Add this method to be called when returning from other screens
  void _refreshOnReturn() {
    if (mounted) {
      _fetchAlerts();
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      final username = await _authService.getUsername();
      if (mounted) {
        setState(() {
          _username = username ?? 'User';
        });
      }
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  Future<void> _checkPasswordAvailability() async {
    final isAvailable = await _authService.isPasswordVerificationAvailable();
    if (mounted) {
      setState(() {
        _passwordAvailable = isAvailable;
      });
    }
  }

  Future<void> _fetchCarStatus() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final status = await _carStatusService.fetchCarStatus(deviceUid);
    if (status != null) {
      setState(() {
        _carStatus = status;
        _systemStatus = status['status'] ?? 'UNKNOWN';
        _loading = false;
      });
    } else {
      setState(() {
        _error = 'Failed to fetch car status.';
        _loading = false;
      });
    }
  }

  Future<void> _fetchAlerts() async {
    try {
      final alerts = await _alertsService.fetchAlerts(deviceUid);
      if (mounted) {
        setState(() {
          _recentAlerts = alerts?.take(2).toList() ?? [];
          _unreadAlertCount = alerts?.where((alert) => alert['read_status'] != true).length ?? 0;
        });
      }
    } catch (e) {
      print('Error fetching alerts: $e');
      // Don't show error to user, just log it
    }
  }

  void _updateAlertCount() {
    _refreshOnReturn();
  }

  void _connectToKillSwitchSocket() {
    _killSwitchSocket = _killSwitchService.connectToKillSwitchSocket(
      deviceUid: deviceUid,
      onKillSwitchCommand: (data) {
        if (mounted) {
          setState(() {
            _systemStatus = data['action'] ?? 'UNKNOWN';
          });
          _showKillSwitchNotification(data);
        }
      },
      onConnect: () {
        print('Kill switch socket connected');
      },
      onDisconnect: () {
        print('Kill switch socket disconnected');
      },
      onError: (error) {
        print('Kill switch socket error: $error');
      },
    );
  }

  void _showKillSwitchNotification(Map<String, dynamic> data) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kill switch ${data['action']} command received'),
        backgroundColor: data['action'] == 'KILL' ? Colors.red : Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _showKillSwitchConfirmation() async {
    // Check if password verification is available
    final isPasswordAvailable = await _authService.isPasswordVerificationAvailable();
    if (!isPasswordAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password verification not set up. Please log out and log in again.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    // First confirmation
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text(
              'Emergency Kill Switch',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to activate the emergency kill switch? This will immediately disable the engine.',
          style: GoogleFonts.poppins(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[500]),
            child: Text('Yes, Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (firstConfirm != true) return;

    // Password confirmation
    final passwordConfirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PasswordConfirmationDialog(
        title: 'Security Verification',
        message: 'This action requires your password for security verification.',
        confirmButtonText: 'ACTIVATE KILL SWITCH',
        confirmButtonColor: Colors.red,
      ),
    );

    if (passwordConfirmed == true) {
      await _executeKillSwitch();
    }
  }

  Future<void> _executeKillSwitch() async {
    setState(() {
      _killSwitchLoading = true;
    });

    try {
      final result = await _killSwitchService.sendKillSwitchCommand(
        deviceUid: deviceUid,
        action: 'KILL',
        reason: 'emergency_activation',
      );

      if (result != null) {
        setState(() {
          _systemStatus = 'KILLED';
          _killSwitchLoading = false;
        });
        
        // Show notification using notification service
        final notificationService = Provider.of<NotificationService>(context, listen: false);
        notificationService.showNotification(
          context,
          'Kill Switch Activated',
          'Emergency kill switch has been activated. Engine is now disabled.',
          alertType: 'kill_switch_activated',
        );
      } else {
        setState(() {
          _killSwitchLoading = false;
        });
        
        // Show notification using notification service
        final notificationService = Provider.of<NotificationService>(context, listen: false);
        notificationService.showNotification(
          context,
          'Kill Switch Failed',
          'Failed to activate kill switch. Please try again.',
          alertType: 'system_error',
        );
      }
    } catch (e) {
      setState(() {
        _killSwitchLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _showDisarmConfirmation() async {
    // Check if password verification is available
    final isPasswordAvailable = await _authService.isPasswordVerificationAvailable();
    if (!isPasswordAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password verification not set up. Please log out and log in again.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    // First confirmation
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.lock_open, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text(
              'Disarm System',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to disarm the system? This will allow normal engine operation.',
          style: GoogleFonts.poppins(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600]),
            child: Text('Yes, Disarm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (firstConfirm != true) return;

    // Password confirmation
    final passwordConfirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PasswordConfirmationDialog(
        title: 'Security Verification',
        message: 'This action requires your password for security verification.',
        confirmButtonText: 'DISARM SYSTEM',
        confirmButtonColor: Colors.green,
      ),
    );

    if (passwordConfirmed == true) {
      await _executeDisarm();
    }
  }

  Future<void> _executeDisarm() async {
    setState(() {
      _killSwitchLoading = true;
    });

    try {
      final result = await _killSwitchService.sendKillSwitchCommand(
        deviceUid: deviceUid,
        action: 'DISARM',
        reason: 'user_disarm',
      );

      if (result != null) {
        setState(() {
          _systemStatus = 'DISARMED';
          _killSwitchLoading = false;
        });
        
        // Show notification using notification service
        final notificationService = Provider.of<NotificationService>(context, listen: false);
        notificationService.showNotification(
          context,
          'System Disarmed',
          'The anti-theft system has been disarmed successfully.',
          alertType: 'system_disarmed',
        );
      } else {
        setState(() {
          _killSwitchLoading = false;
        });
        
        // Show notification using notification service
        final notificationService = Provider.of<NotificationService>(context, listen: false);
        notificationService.showNotification(
          context,
          'Disarm Failed',
          'Failed to disarm the system. Please try again.',
          alertType: 'system_error',
        );
      }
    } catch (e) {
      setState(() {
        _killSwitchLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Color _getStatusColor() {
    switch (_systemStatus) {
      case 'ARMED':
        return Colors.green;
      case 'DISARMED':
        return Colors.orange;
      case 'KILLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (_systemStatus) {
      case 'ARMED':
        return Icons.lock;
      case 'DISARMED':
        return Icons.lock_open;
      case 'KILLED':
        return Icons.power_settings_new;
      default:
        return Icons.help_outline;
    }
  }

  IconData _getAlertIcon(String type) {
    // Convert to lowercase for case-insensitive matching
    final lowerType = type.toLowerCase();
    
    switch (lowerType) {
      case 'movement':
        return Icons.directions_car;
      case 'tampering':
        return Icons.security;
      case 'low_battery':
        return Icons.battery_alert;
      case 'engine_start':
        return Icons.power;
      case 'engine_stop':
        return Icons.power_off;
      case 'kill_switch_activated':
      case 'kill_switch':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  IconData _getSeverityIcon(String severity, String type) {
    // Convert to lowercase for case-insensitive matching
    final lowerType = type.toLowerCase();
    final lowerSeverity = severity.toLowerCase();
    
    // For high severity alerts, show warning/error icons
    if (lowerSeverity == 'high') {
      switch (lowerType) {
        case 'engine_shutdown':
        case 'kill_switch_activated':
        case 'kill_switch':
        case 'tampering':
        case 'unauthorized_access':
          return Icons.error; // Red error icon
        case 'low_battery':
        case 'touch_detection':
          return Icons.warning; // Orange warning icon
        default:
          return Icons.priority_high;
      }
    }
    
    // For medium severity, show warning icon for certain types
    if (lowerSeverity == 'medium') {
      switch (lowerType) {
        case 'gps_movement':
        case 'movement':
        case 'engine_start':
        case 'engine_stop':
        case 'kill_switch_activated':
        case 'kill_switch':
          return Icons.warning; // Orange warning icon
        default:
          return _getAlertIcon(type);
      }
    }
    
    // For low severity, use the default alert icon
    return _getAlertIcon(type);
  }

  Color _getAlertColor(String type) {
    switch (type) {
      case 'movement':
        return Colors.blue;
      case 'tampering':
        return Colors.red;
      case 'low_battery':
        return Colors.orange;
      case 'engine_start':
        return Colors.green;
      case 'engine_stop':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getAlertTitle(String type) {
    switch (type) {
      case 'movement':
        return 'Car Movement Detected';
      case 'tampering':
        return 'Tampering Alert';
      case 'low_battery':
        return 'Low Battery';
      case 'engine_start':
        return 'Engine Started';
      case 'engine_stop':
        return 'Engine Stopped';
      default:
        return 'New Alert';
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return '${date.hour}:${date.minute}';
    } catch (e) {
      return timestamp;
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to logout? You will need to log in again to access AutoGuardian.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _performLogout();
            },
            child: Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: mainBlue),
        ),
      );

      // Perform logout
      await _authService.logout();
      
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to login screen and clear navigation stack
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during logout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [mainBlue, accentBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.security, color: mainBlue, size: 32),
                  ),
                  SizedBox(height: 12),
                  Text('AutoGuardian', style: GoogleFonts.poppins(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(_username, style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70)),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.directions_car),
              title: Text('Trip History'),
              onTap: () async {
                Navigator.pop(context); // Close drawer
                await Navigator.pushNamed(context, '/trips');
              },
            ),
            ListTile(
              leading: Icon(Icons.psychology),
              title: Text('AI/ML Dashboard'),
              onTap: () async {
                Navigator.pop(context); // Close drawer
                await Navigator.pushNamed(context, '/ml-dashboard');
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () async {
                Navigator.pop(context); // Close drawer
                await Navigator.pushNamed(context, '/settings');
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                _showLogoutConfirmation();
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(
          'AutoGuardian',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: mainBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications),
                onPressed: () async {
                  await Navigator.pushNamed(context, '/alerts');
                  // Refresh alerts when returning from alerts screen
                  _refreshOnReturn();
                },
              ),
              if (_unreadAlertCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadAlertCount > 99 ? '99+' : _unreadAlertCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [mainBlue.withOpacity(0.05), accentBlue.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Car Status Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _loading
                      ? Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Column(
                              children: [
                                Icon(Icons.error, color: Colors.red, size: 32),
                                SizedBox(height: 8),
                                Text(_error!, style: TextStyle(color: Colors.red)),
                                SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _fetchCarStatus,
                                  child: Text('Retry'),
                                  style: ElevatedButton.styleFrom(backgroundColor: mainBlue),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Icon(Icons.directions_car, color: mainBlue, size: 40),
                                SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Car Status', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                                      SizedBox(height: 4),
                                      Text(
                                        _systemStatus,
                                        style: TextStyle(
                                          color: _getStatusColor(),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text('Engine: ${_carStatus?['engine_status'] ?? '-'}', style: TextStyle(color: Colors.grey[700])),
                                      if (_carStatus?['timestamp'] != null)
                                        Text('Updated: ${_carStatus!['timestamp']}', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Icon(
                                  _getStatusIcon(),
                                  color: _getStatusColor(),
                                  size: 28,
                                ),
                              ],
                            ),
                ),
              ),
              SizedBox(height: 20),
              // Live Location Card (tappable)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.pushNamed(context, '/live-location');
                  },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: accentBlue, size: 40),
                      SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Live Location', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                              Text('Tap to view your car\'s real-time location on the map.', style: TextStyle(color: Colors.grey[700])),
                          ],
                        ),
                      ),
                        Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 20),
                    ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Kill Switch Button
              Card(
                color: _systemStatus == 'KILLED' ? Colors.grey[100] : 
                       _systemStatus == 'DISARMED' ? Colors.green[50] : Colors.red[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _systemStatus == 'KILLED' ? Icons.power_settings_new : 
                            _systemStatus == 'DISARMED' ? Icons.lock_open : Icons.power_settings_new,
                            color: _systemStatus == 'KILLED' ? Colors.grey : 
                                   _systemStatus == 'DISARMED' ? Colors.green : Colors.red,
                            size: 40,
                          ),
                      SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                                Text('System Control', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                                Text(
                                  _systemStatus == 'KILLED' 
                                    ? 'Engine disabled - System ready to disarm' 
                                    : _systemStatus == 'DISARMED'
                                    ? 'System disarmed - Engine operational'
                                    : 'Remotely disable engine',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                            if (!_passwordAvailable) ...[
                              SizedBox(height: 4),
                              Text(
                                '⚠️ Password verification not set up',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          // Kill Switch Button (only show when not killed)
                          if (_systemStatus != 'KILLED')
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _killSwitchLoading 
                                  ? null 
                                  : _showKillSwitchConfirmation,
                                child: _killSwitchLoading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'KILL ENGINE',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          // Disarm Button (only show when killed or armed)
                          if (_systemStatus == 'KILLED' || _systemStatus == 'ARMED')
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(left: _systemStatus != 'ARMED' ? 12 : 0),
                                child: ElevatedButton(
                                  onPressed: _killSwitchLoading 
                                    ? null 
                                    : _showDisarmConfirmation,
                                  child: _killSwitchLoading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        'DISARM',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              // AI/ML Status Widget
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: InkWell(
                  onTap: () async {
                    await Navigator.pushNamed(context, '/ml-dashboard');
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.psychology, color: mainBlue, size: 32),
                            SizedBox(width: 12),
                            Text('AI/ML Status', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                            Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: Text(
                                'Active',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AI Learning Active',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Monitoring driving patterns for anomalies',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Alerts/Events Preview
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: InkWell(
                  onTap: () async {
                    await Navigator.pushNamed(context, '/alerts');
                    // Refresh alerts when returning from alerts screen
                    _refreshOnReturn();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
                            SizedBox(width: 12),
                            Text('Recent Alerts', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                            Spacer(),
                            if (_unreadAlertCount > 0)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$_unreadAlertCount new',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 12),
                        if (_recentAlerts.isNotEmpty)
                          ..._recentAlerts.map((alert) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Stack(
                              children: [
                                Icon(
                                  _getSeverityIcon(alert['severity'] ?? 'medium', alert['type']),
                                  color: _getAlertColor(alert['type']),
                                ),
                                // Add severity indicator for high priority alerts
                                if ((alert['severity'] ?? 'medium') == 'high')
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                              _getAlertTitle(alert['type']),
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              alert['message'] ?? 'No description available',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              _formatTimestamp(alert['timestamp']),
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AlertDetailScreen(
                                    alert: alert,
                                    onAlertUpdated: _updateAlertCount,
                                  ),
                                ),
                              ).then((_) {
                                // Refresh alerts when returning from detail view
                                _refreshOnReturn();
                              });
                            },
                          )).toList()
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text('No recent alerts.', style: TextStyle(color: Colors.grey)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 