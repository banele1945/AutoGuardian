import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/trip_service.dart';

class TripDetailScreen extends StatefulWidget {
  final String tripId;
  final String deviceUid;
  final Map<String, dynamic>? tripData; // Add trip data from list as fallback

  const TripDetailScreen({
    Key? key,
    required this.tripId,
    required this.deviceUid,
    this.tripData,
  }) : super(key: key);

  @override
  _TripDetailScreenState createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final Color mainBlue = const Color(0xFF1565C0);
  final TripService _tripService = TripService();
  
  Map<String, dynamic>? _tripDetails;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTripDetails();
  }

  Future<void> _loadTripDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final details = await _tripService.fetchTripDetails(widget.deviceUid, widget.tripId);
      print('Trip details for ID ${widget.tripId}: $details'); // Debug print
      if (mounted) {
        setState(() {
          _tripDetails = details;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error fetching trip details: $e');
      // If trip details API fails, use the trip data from the list as fallback
      if (widget.tripData != null) {
        print('Using fallback trip data: ${widget.tripData}');
        if (mounted) {
          setState(() {
            _tripDetails = widget.tripData;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = e.toString();
            _loading = false;
          });
        }
      }
    }
  }

  String _formatDateTime(dynamic timestamp) {
    try {
      DateTime dateTime;
      
      if (timestamp is int) {
        // Handle Unix timestamp (seconds since epoch)
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      } else if (timestamp is String) {
        // Handle ISO string format
        dateTime = DateTime.parse(timestamp);
      } else {
        return 'Invalid time';
      }
      
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid time';
    }
  }

  String _formatDuration(dynamic startTime, dynamic endTime) {
    try {
      DateTime start, end;
      
      // Handle start time
      if (startTime is int) {
        start = DateTime.fromMillisecondsSinceEpoch(startTime * 1000);
      } else if (startTime is String) {
        start = DateTime.parse(startTime);
      } else {
        return 'Unknown';
      }
      
      // Handle end time
      if (endTime is int) {
        end = DateTime.fromMillisecondsSinceEpoch(endTime * 1000);
      } else if (endTime is String) {
        end = DateTime.parse(endTime);
      } else {
        return 'Unknown';
      }
      
      final duration = end.difference(start);
      
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      final seconds = duration.inSeconds % 60;
      
      if (hours > 0) {
        return '${hours}h ${minutes}m ${seconds}s';
      } else if (minutes > 0) {
        return '${minutes}m ${seconds}s';
      } else {
        return '${seconds}s';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatDistance(dynamic distance) {
    if (distance == null) return 'Unknown';
    final doubleValue = distance is int ? distance.toDouble() : distance as double?;
    if (doubleValue == null) return 'Unknown';
    if (doubleValue < 1) {
      return '${(doubleValue * 1000).toStringAsFixed(0)} meters';
    } else {
      return '${doubleValue.toStringAsFixed(2)} kilometers';
    }
  }

  String _formatSpeed(dynamic speed) {
    if (speed == null) return 'Unknown';
    final doubleValue = speed is int ? speed.toDouble() : speed as double?;
    if (doubleValue == null) return 'Unknown';
    return '${doubleValue.toStringAsFixed(1)} km/h';
  }

  String _formatFuel(dynamic fuel) {
    if (fuel == null) return 'Unknown';
    final doubleValue = fuel is int ? fuel.toDouble() : fuel as double?;
    if (doubleValue == null) return 'Unknown';
    return '${doubleValue.toStringAsFixed(1)} L';
  }

  String _formatIdleTime(dynamic idleTime) {
    if (idleTime == null) return '0 minutes';
    
    int seconds;
    if (idleTime is int) {
      seconds = idleTime;
    } else if (idleTime is String) {
      seconds = int.tryParse(idleTime) ?? 0;
    } else {
      return '0 minutes';
    }
    
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    
    if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    } else {
      return '${remainingSeconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Trip Details',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: mainBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadTripDetails,
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
                    'Loading trip details...',
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
                        onPressed: _loadTripDetails,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _tripDetails == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Trip not found',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Trip Header
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
                                          color: mainBlue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.directions_car,
                                          color: mainBlue,
                                          size: 32,
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Trip ${widget.tripData?['trip_number'] ?? _tripDetails!['trip_number'] ?? 'Unknown'}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              _formatDateTime(_tripDetails!['start_time']),
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _tripDetails!['status'] ?? 'Completed',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
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

                          // Trip Statistics
                          Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Trip Statistics',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatCard(
                                          'Duration',
                                          _formatDuration(_tripDetails!['start_time'], _tripDetails!['end_time']),
                                          Icons.access_time,
                                          Colors.blue,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: _buildStatCard(
                                          'Distance',
                                          _formatDistance(_tripDetails!['distance']),
                                          Icons.straighten,
                                          Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatCard(
                                          'Avg Speed',
                                          _formatSpeed(_tripDetails!['average_speed']),
                                          Icons.speed,
                                          Colors.orange,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: _buildStatCard(
                                          'Fuel Used',
                                          _formatFuel(_tripDetails!['fuel_consumed']),
                                          Icons.local_gas_station,
                                          Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20),

                          // Trip Details
                          Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Trip Information',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  _buildDetailRow('Start Time', _formatDateTime(_tripDetails!['start_time'])),
                                  _buildDetailRow('End Time', _formatDateTime(_tripDetails!['end_time'])),
                                  _buildDetailRow('Start Location', _tripDetails!['start_location'] ?? 'Unknown'),
                                  _buildDetailRow('End Location', _tripDetails!['end_location'] ?? 'Unknown'),
                                  _buildDetailRow('Max Speed', _formatSpeed(_tripDetails!['max_speed'])),
                                  _buildDetailRow('Idle Time', _formatIdleTime(_tripDetails!['idle_time'])),
                                  _buildDetailRow('Stops Made', '${_tripDetails!['stops_count'] ?? 0}'),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20),

                          // Route Information (if available)
                          if (_tripDetails!['route_points'] != null && (_tripDetails!['route_points'] as List).isNotEmpty)
                            Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 2,
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Route Information',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Route points: ${(_tripDetails!['route_points'] as List).length} coordinates recorded',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Note: Route visualization will be available in future updates',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
            width: 120,
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