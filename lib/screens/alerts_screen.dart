import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/alerts_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import 'alert_detail_screen.dart'; // Added import for AlertDetailScreen

class AlertsScreen extends StatefulWidget {
  @override
  _AlertsScreenState createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final Color mainBlue = const Color(0xFF1565C0);
  final Color accentBlue = const Color(0xFF42A5F5);
  final String deviceUid = 'ESP32-123456';
  final AlertsService _alertsService = AlertsService();
  
  List<Map<String, dynamic>> _alerts = [];
  bool _loading = true;
  String? _error;
  IO.Socket? _alertsSocket;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
    _connectToAlertsSocket();
  }

  @override
  void dispose() {
    _alertsSocket?.disconnect();
    super.dispose();
  }

  Future<void> _fetchAlerts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final alerts = await _alertsService.fetchAlerts(deviceUid);
      
      if (mounted) {
        setState(() {
          _alerts = alerts ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final success = await _alertsService.markAllAsRead(deviceUid);
      if (success && mounted) {
        setState(() {
          for (var alert in _alerts) {
            alert['read_status'] = true;
          }
        });
        
        // Notify parent screens about the update
        // This will update the home screen alert count
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Trigger a rebuild of parent widgets
            setState(() {});
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All alerts marked as read'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark all as read: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _connectToAlertsSocket() {
    _alertsSocket = _alertsService.connectToAlertsSocket(
      deviceUid: deviceUid,
      onNewAlert: (data) {
        if (mounted) {
          setState(() {
            _alerts.insert(0, data);
          });
          _showAlertNotification(data);
        }
      },
      onConnect: () {
        print('Alerts socket connected');
      },
      onDisconnect: () {
        print('Alerts socket disconnected');
      },
      onError: (error) {
        print('Alerts socket error: $error');
      },
    );
  }

  void _showAlertNotification(Map<String, dynamic> alert) {
    // Use notification service to show notification based on settings
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    notificationService.showNotification(
      context,
      _getAlertTitle(alert['type']),
      alert['message'] ?? 'New alert received',
      alertType: alert['type'],
    );
  }

  IconData _getAlertIcon(String? type) {
    if (type == null) return Icons.notifications;
    
    // Convert to lowercase for case-insensitive matching
    final lowerType = type.toLowerCase();
    
    switch (lowerType) {
      case 'engine_shutdown':
        return Icons.power_settings_new;
      case 'unauthorized_access':
        return Icons.security;
      case 'touch_detection':
        return Icons.touch_app;
      case 'gps_movement':
        return Icons.location_on;
      case 'system_status':
        return Icons.settings;
      case 'kill_switch_activated':
      case 'kill_switch':
        return Icons.warning;
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
      default:
        return Icons.notifications;
    }
  }

  IconData _getSeverityIcon(String? severity, String? type) {
    if (type == null) return Icons.notifications;
    
    // Convert to lowercase for case-insensitive matching
    final lowerType = type.toLowerCase();
    final lowerSeverity = severity?.toLowerCase() ?? 'medium';
    
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

  Color _getAlertColor(String? type) {
    if (type == null) return Colors.grey;
    
    // Convert to lowercase for case-insensitive matching
    final lowerType = type.toLowerCase();
    
    switch (lowerType) {
      case 'engine_shutdown':
      case 'kill_switch_activated':
      case 'kill_switch':
      case 'tampering':
        return Colors.red;
      case 'unauthorized_access':
      case 'low_battery':
        return Colors.orange;
      case 'touch_detection':
        return Colors.amber;
      case 'gps_movement':
      case 'movement':
        return Colors.blue;
      case 'system_status':
      case 'engine_start':
        return Colors.green;
      case 'engine_stop':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getAlertTitle(String? type) {
    if (type == null) return 'New Alert';
    
    // Convert to lowercase for case-insensitive matching
    final lowerType = type.toLowerCase();
    
    switch (lowerType) {
      case 'engine_shutdown':
        return 'Engine Shutdown Attempt';
      case 'unauthorized_access':
        return 'Unauthorized Access Detected';
      case 'touch_detection':
        return 'Vehicle Touch Detected';
      case 'gps_movement':
        return 'GPS Movement Alert';
      case 'system_status':
        return 'System Status Changed';
      case 'kill_switch_activated':
      case 'kill_switch':
        return 'Kill Switch Activated';
      case 'movement':
        return 'Car Movement Detected';
      case 'tampering':
        return 'Tampering Alert';
      case 'low_battery':
        return 'Low Battery Warning';
      case 'engine_start':
        return 'Engine Started';
      case 'engine_stop':
        return 'Engine Stopped';
      default:
        return 'New Alert';
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Unknown time';
    
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Invalid time';
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Security Alerts',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: mainBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_alerts.any((alert) => alert['read_status'] != true))
            IconButton(
              icon: Icon(Icons.mark_email_read),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchAlerts,
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: mainBlue),
                  SizedBox(height: 16),
                  Text(
                    'Loading alerts...',
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        _error!,
                        style: GoogleFonts.poppins(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchAlerts,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _alerts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No alerts yet',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Security alerts will appear here',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchAlerts,
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _alerts.length,
                        itemBuilder: (context, index) {
                          final alert = _alerts[index];
                          final isRead = alert['read_status'] == true;
                          final severity = alert['severity'] ?? 'medium';
                          
                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isRead ? Colors.grey[300]! : _getAlertColor(alert['type']).withOpacity(0.3),
                                width: isRead ? 1 : 2,
                              ),
                            ),
                            elevation: isRead ? 1 : 3,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AlertDetailScreen(
                                      alert: alert,
                                      onAlertUpdated: () {
                                        // Refresh alerts when an alert is updated
                                        _fetchAlerts();
                                      },
                                    ),
                                  ),
                                ).then((_) {
                                  // Refresh alerts when returning from detail view
                                  _fetchAlerts();
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: ListTile(
                                leading: Stack(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: _getAlertColor(alert['type']).withOpacity(0.1),
                                      child: Icon(
                                        _getSeverityIcon(severity, alert['type']),
                                        color: _getAlertColor(alert['type']),
                                      ),
                                    ),
                                    if (!isRead)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                        ),
                                      ),
                                    // Add severity indicator for high priority alerts
                                    if (severity == 'high')
                                      Positioned(
                                        left: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                          child: Icon(
                                            Icons.priority_high,
                                            color: Colors.white,
                                            size: 10,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _getAlertTitle(alert['type']),
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                                          color: isRead ? Colors.grey[600] : Colors.grey[800],
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getSeverityColor(severity).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        severity.toUpperCase(),
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: _getSeverityColor(severity),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (alert['message'] != null) ...[
                                      SizedBox(height: 4),
                                      Text(
                                        alert['message'],
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          _formatTimestamp(alert['timestamp']),
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                        Spacer(),
                                        if (!isRead)
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'NEW',
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey[400],
                                  size: 16,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
} 