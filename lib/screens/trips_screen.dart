import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/trip_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'trip_detail_screen.dart';

class TripsScreen extends StatefulWidget {
  @override
  _TripsScreenState createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  final Color mainBlue = const Color(0xFF1565C0);
  final String deviceUid = 'ESP32-123456';
  final TripService _tripService = TripService();
  
  List<Map<String, dynamic>> _trips = [];
  List<String> _availableDates = [];
  String _selectedDate = '';
  bool _loading = true;
  String? _error;
  IO.Socket? _tripSocket;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _connectToTripSocket();
  }

  @override
  void dispose() {
    _tripSocket?.disconnect();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    await _loadAvailableDates();
    // Set a default date (today) if no dates are available
    if (_availableDates.isNotEmpty) {
      _selectedDate = _availableDates.first;
    } else {
      // Set today's date as default
      final today = DateTime.now();
      _selectedDate = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    }
    await _loadTrips();
    
    // If we have trips but no available dates, extract dates from trips
    if (_trips.isNotEmpty && _availableDates.isEmpty) {
      final Set<String> tripDates = {};
      print('Extracting dates from ${_trips.length} trips...'); // Debug
      for (final trip in _trips) {
        final startTime = trip['start_time'];
        print('Processing trip start_time: $startTime'); // Debug
        if (startTime != null) {
          DateTime dateTime;
          if (startTime is String) {
            dateTime = DateTime.parse(startTime);
          } else if (startTime is int) {
            dateTime = DateTime.fromMillisecondsSinceEpoch(startTime * 1000);
          } else {
            print('Skipping trip with invalid start_time type: ${startTime.runtimeType}'); // Debug
            continue;
          }
          final dateString = '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
          tripDates.add(dateString);
          print('Added date: $dateString'); // Debug
        }
      }
      
      print('Extracted dates: $tripDates'); // Debug
      if (mounted) {
        print('Before setState - _selectedDate: $_selectedDate, _availableDates: $_availableDates'); // Debug
        setState(() {
          _availableDates = tripDates.toList()..sort((a, b) => b.compareTo(a)); // Sort newest first
          print('Final available dates: $_availableDates'); // Debug
          if (_selectedDate.isEmpty || !_availableDates.contains(_selectedDate)) {
            _selectedDate = _availableDates.first;
            print('Updated selected date to: $_selectedDate'); // Debug
          }
        });
        print('After setState - _selectedDate: $_selectedDate, _availableDates: $_availableDates'); // Debug
      }
    }
    
    await _connectToTripSocket();
  }

  Future<void> _loadAvailableDates() async {
    try {
      final dates = await _tripService.fetchAvailableDates(deviceUid);
      print('Available dates from server: $dates'); // Debug print
      if (mounted) {
        setState(() {
          _availableDates = dates;
        });
      }
    } catch (e) {
      print('Error loading available dates: $e');
    }
  }

  Future<void> _loadTrips() async {
    if (_selectedDate.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final trips = await _tripService.fetchTrips(deviceUid, _selectedDate);
      print('Trips for date $_selectedDate: $trips'); // Debug print
      if (mounted) {
        setState(() {
          _trips = trips ?? [];
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

  Future<void> _connectToTripSocket() async {
    _tripSocket = await _tripService.connectToTripSocket(
      deviceUid: deviceUid,
      onTripStarted: (data) {
        if (mounted) {
          _showTripNotification('Trip Started', data);
          _loadTrips(); // Refresh trips list
        }
      },
      onTripEnded: (data) {
        if (mounted) {
          _showTripNotification('Trip Ended', data);
          _loadTrips(); // Refresh trips list
        }
      },
      onTripUpdated: (data) {
        if (mounted) {
          _loadTrips(); // Refresh trips list
        }
      },
      onConnect: () {
        print('Trip socket connected');
      },
      onDisconnect: () {
        print('Trip socket disconnected');
      },
      onError: (error) {
        print('Trip socket error: $error');
      },
    );
  }

  void _showTripNotification(String title, Map<String, dynamic> data) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.directions_car, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                                              '$title - Trip ${data['trip_number'] ?? 'Unknown'}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: title.contains('Started') ? Colors.green : Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final dateTime = DateTime.parse(date);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return date;
    }
  }

  String _formatTime(dynamic timestamp) {
    try {
      DateTime dateTime;
      
      if (timestamp is int) {
        // Handle Unix timestamp (seconds since epoch)
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      } else if (timestamp is String) {
        // Handle ISO string format
        dateTime = DateTime.parse(timestamp);
      } else {
        return 'Unknown';
      }
      
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown';
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
      
      if (hours > 0) {
        return '${hours}h ${minutes}m';
      } else {
        return '${minutes}m';
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
      return '${(doubleValue * 1000).toStringAsFixed(0)}m';
    } else {
      return '${doubleValue.toStringAsFixed(1)}km';
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building TripsScreen - _selectedDate: $_selectedDate, _availableDates: $_availableDates'); // Debug
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Trip History',
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
             onPressed: _loadTrips,
             tooltip: 'Refresh trips',
           ),
         ],
      ),
      body: Column(
        children: [
          // Date Selector
          Container(
            padding: EdgeInsets.all(16),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Date',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                                                              DropdownButtonFormField<String>(
                       value: _selectedDate.isNotEmpty ? _selectedDate : null,
                       // Debug the dropdown value
                       onTap: () {
                         print('Dropdown tapped - current value: $_selectedDate, available: $_availableDates'); // Debug
                       },
                       decoration: InputDecoration(
                         border: OutlineInputBorder(
                           borderRadius: BorderRadius.circular(8),
                         ),
                         contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                       ),
                       items: _availableDates.isNotEmpty 
                         ? _availableDates.map((date) {
                             print('Creating dropdown item for date: $date'); // Debug
                             return DropdownMenuItem(
                               value: date,
                               child: Text(_formatDate(date)),
                             );
                           }).toList()
                         : [
                             // Show today as default option
                             DropdownMenuItem(
                               value: _selectedDate,
                               child: Text('Today (${_formatDate(_selectedDate)})'),
                             ),
                           ],
                       onChanged: (value) {
                         print('Dropdown onChanged called with value: $value'); // Debug
                         if (value != null) {
                           print('Setting selected date to: $value'); // Debug
                           setState(() {
                             _selectedDate = value;
                           });
                           _loadTrips();
                         }
                       },
                     ),
                  ],
                ),
              ),
            ),
          ),
          
          // Trips List
          Expanded(
            child: _loading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: mainBlue),
                        SizedBox(height: 16),
                        Text(
                          'Loading trips...',
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
                              onPressed: _loadTrips,
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _trips.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No trips found',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Trips will appear here when you start driving',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadTrips,
                            child: ListView.builder(
                              padding: EdgeInsets.all(16),
                              itemCount: _trips.length,
                              itemBuilder: (context, index) {
                                final trip = _trips[index];
                                return Card(
                                  margin: EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                                                         onTap: () {
                                       Navigator.push(
                                         context,
                                         MaterialPageRoute(
                                           builder: (context) => TripDetailScreen(
                                             tripId: trip['id'].toString(),
                                             deviceUid: deviceUid,
                                             tripData: trip, // Pass trip data as fallback
                                           ),
                                         ),
                                       );
                                     },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: mainBlue.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.directions_car,
                                                  color: mainBlue,
                                                  size: 24,
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Trip ${trip['trip_number'] ?? 'Unknown'}',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      '${_formatTime(trip['start_time'])} - ${_formatTime(trip['end_time'])}',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 14,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                color: Colors.grey[400],
                                                size: 16,
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildTripInfo(
                                                  'Duration',
                                                  _formatDuration(trip['start_time'], trip['end_time']),
                                                  Icons.access_time,
                                                ),
                                              ),
                                              Expanded(
                                                child: _buildTripInfo(
                                                  'Distance',
                                                  _formatDistance(trip['distance']),
                                                  Icons.straighten,
                                                ),
                                              ),
                                              Expanded(
                                                child: _buildTripInfo(
                                                  'Status',
                                                  trip['status'] ?? 'Completed',
                                                  Icons.check_circle,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripInfo(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
} 