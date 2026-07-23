import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/alerts_service.dart';

class AlertDetailScreen extends StatefulWidget {
  final Map<String, dynamic> alert;
  final VoidCallback? onAlertUpdated;

  const AlertDetailScreen({
    Key? key, 
    required this.alert,
    this.onAlertUpdated,
  }) : super(key: key);

  @override
  _AlertDetailScreenState createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  final Color mainBlue = const Color(0xFF1565C0);
  final AlertsService _alertsService = AlertsService();
  bool _isLoading = false;

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
    switch (type) {
      case 'engine_shutdown':
      case 'kill_switch_activated':
      case 'tampering':
        return Colors.red;
      case 'unauthorized_access':
        return Colors.orange;
      case 'touch_detection':
        return Colors.amber;
      case 'gps_movement':
      case 'movement':
        return Colors.blue;
      case 'system_status':
      case 'engine_start':
        return Colors.green;
      case 'low_battery':
        return Colors.orange;
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

  String _getSeverityText(String? severity) {
    switch (severity) {
      case 'high':
        return 'High Priority';
      case 'medium':
        return 'Medium Priority';
      case 'low':
        return 'Low Priority';
      default:
        return 'Medium Priority';
    }
  }

  Color _getSeverityColor(String? severity) {
    switch (severity) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Unknown time';
    
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid time';
    }
  }

  Future<void> _markAsRead() async {
    if (widget.alert['read_status'] == true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _alertsService.markAlertAsRead(widget.alert['id'].toString());
      if (success && mounted) {
        setState(() {
          widget.alert['read_status'] = true;
          _isLoading = false;
        });
        
        // Notify parent screens about the update
        widget.onAlertUpdated?.call();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alert marked as read'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark as read: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final isRead = alert['read_status'] == true;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Alert Details',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: mainBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!isRead)
            IconButton(
              icon: _isLoading 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.mark_email_read),
              onPressed: _isLoading ? null : _markAsRead,
              tooltip: 'Mark as read',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alert Header Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getAlertColor(alert['type']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getSeverityIcon(alert['severity'], alert['type']),
                            color: _getAlertColor(alert['type']),
                            size: 32,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getAlertTitle(alert['type']),
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getSeverityColor(alert['severity']).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getSeverityText(alert['severity']),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _getSeverityColor(alert['severity']),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isRead)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'READ',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 16),
                    if (alert['message'] != null && alert['message'].toString().isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          alert['message'],
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            
            // Alert Details Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alert Information',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildDetailRow('Device ID', alert['device_uid'] ?? 'Unknown'),
                    _buildDetailRow('Alert Type', alert['type'] ?? 'Unknown'),
                    _buildDetailRow('Severity', _getSeverityText(alert['severity'])),
                    _buildDetailRow('Timestamp', _formatTimestamp(alert['timestamp'])),
                    _buildDetailRow('Status', isRead ? 'Read' : 'Unread'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            
            // Action Buttons
            if (!isRead)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _markAsRead,
                      icon: _isLoading 
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(Icons.mark_email_read),
                      label: Text('Mark as Read'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 