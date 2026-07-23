import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

const String deviceUid = 'ESP32-123456'; // TODO: Replace with actual device UID
final _storage = FlutterSecureStorage();

class LiveLocationScreen extends StatefulWidget {
  const LiveLocationScreen({Key? key}) : super(key: key);

  @override
  State<LiveLocationScreen> createState() => _LiveLocationScreenState();
}

class _LiveLocationScreenState extends State<LiveLocationScreen> {
  LatLng? _carLocation;
  LatLng? _lastLocation;
  String? _error;
  IO.Socket? _socket;
  bool _isConnecting = false;
  DateTime? _lastUpdateTime;
  List<LatLng> _trail = [];
  bool _isMoving = false;
  GoogleMapController? _mapController;
  bool _autoFollow = true;
  String _mapType = 'normal'; // 'normal', 'satellite', 'hybrid', 'terrain'
  LatLng? _userLocation;
  bool _isGettingDirections = false;

  final Color mainBlue = const Color(0xFF1565C0);
  final Color accentBlue = const Color(0xFF42A5F5);

  @override
  void initState() {
    super.initState();
    _loadMapSettings();
    _initLiveLocation();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _socket?.dispose();
    super.dispose();
  }

  Future<void> _loadMapSettings() async {
    try {
      final mapType = await _storage.read(key: 'map_type');
      if (mapType != null && mounted) {
        setState(() {
          _mapType = mapType;
        });
      }
    } catch (e) {
      print('Error loading map settings: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permission permanently denied');
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  Future<void> _showDirections() async {
    if (_carLocation == null || _userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to get location data'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isGettingDirections = true;
    });

    try {
      // Create Google Maps directions URL
      final String directionsUrl = 
        'https://www.google.com/maps/dir/?api=1&origin=${_userLocation!.latitude},${_userLocation!.longitude}&destination=${_carLocation!.latitude},${_carLocation!.longitude}&travelmode=driving';

      // Launch Google Maps app or browser
      final Uri url = Uri.parse(directionsUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open directions'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error launching directions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting directions'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGettingDirections = false;
        });
      }
    }
  }

  Future<void> _initLiveLocation() async {
    // Check if location tracking is enabled
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    final isLocationEnabled = await notificationService.isLocationTrackingEnabled();
    
    if (!isLocationEnabled) {
      if (mounted) {
        setState(() {
          _error = 'Location tracking is disabled in settings.';
        });
      }
      return;
    }

    await _fetchLatestLocation();
    _connectSocket();
  }

  Future<void> _fetchLatestLocation() async {
    try {
      final token = await _storage.read(key: 'jwt');
      if (token == null) return;
      final url = Uri.parse('http://10.0.2.2:5000/api/gps?device_uid=$deviceUid&limit=1');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> logs = data['logs'];
        if (logs.isNotEmpty) {
          final gps = logs[0];
          final double lat = double.parse(gps['latitude'].toString());
          final double lng = double.parse(gps['longitude'].toString());
          setState(() {
            _carLocation = LatLng(lat, lng);
            _lastLocation = LatLng(lat, lng);
          });
        }
      }
    } catch (e) {
      print('Error fetching latest location: $e');
    }
  }

  void _connectSocket() async {
    if (_isConnecting) return;
    _isConnecting = true;
    final token = await _storage.read(key: 'jwt');
    if (token == null) {
      if (mounted) setState(() {
        _error = 'Not authenticated. Please log in again.';
      });
      _isConnecting = false;
      return;
    }
    _socket?.dispose();
    _socket = IO.io(
      'http://10.0.2.2:5000',
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .setQuery({'device_uid': deviceUid, 'token': token})
        .build(),
    );

    _socket!.onConnect((_) {
      print('Socket connected');
      if (mounted) setState(() {
        _error = null;
      });
      _isConnecting = false;
    });

    _socket!.on('gps_update', (data) {
      print('GPS update event received: $data');
      try {
        if (data == null) {
          print('gps_update data is null');
          if (mounted) setState(() {
            _error = 'No location data received.';
          });
          return;
        }
        final gps = (data['logs'] != null && data['logs'].isNotEmpty) ? data['logs'][0] : data;
        print('Parsed GPS: $gps');
        final double lat = double.parse(gps['latitude'].toString());
        final double lng = double.parse(gps['longitude'].toString());
        final double speed = double.tryParse(gps['speed'].toString()) ?? 0.0;
        final newLocation = LatLng(lat, lng);
        final DateTime updateTime = DateTime.tryParse(gps['timestamp'].toString()) ?? DateTime.now();
        bool moving = speed > 0.1;
        if (_lastLocation == null ||
            (_lastLocation!.latitude - newLocation.latitude).abs() > 0.00001 ||
            (_lastLocation!.longitude - newLocation.longitude).abs() > 0.00001) {
          if (mounted) setState(() {
            _carLocation = newLocation;
            _lastLocation = newLocation;
            _lastUpdateTime = updateTime;
            _isMoving = moving;
            if (moving) {
              _trail.add(newLocation);
              if (_trail.length > 20) _trail.removeAt(0);
            } else {
              _trail.clear();
            }
            _error = null;
          });
          print('Marker set at: $lat, $lng');
          if (_autoFollow && _mapController != null) {
            _mapController!.animateCamera(CameraUpdate.newLatLngZoom(newLocation, 17.0));
          }
        } else {
          print('Location unchanged, skipping setState');
        }
      } catch (e) {
        print('Error parsing gps_update: $e');
        if (mounted) setState(() {
          _error = 'Error parsing location update.';
        });
      }
    });

    _socket!.onDisconnect((_) {
      print('Socket disconnected');
      if (mounted) setState(() {
        _error = 'Socket disconnected. Reconnecting...';
      });
      _isConnecting = false;
      Future.delayed(const Duration(seconds: 2), _connectSocket);
    });

    _socket!.onError((err) {
      print('Socket error: $err');
      if (mounted) setState(() {
        _error = 'Socket error: $err. Reconnecting...';
      });
      _isConnecting = false;
      Future.delayed(const Duration(seconds: 2), _connectSocket);
    });
  }

  @override
  Widget build(BuildContext context) {
    String lastUpdateText = '';
    if (_lastUpdateTime != null) {
      final now = DateTime.now();
      final diff = now.difference(_lastUpdateTime!);
      if (diff.inSeconds < 60) {
        lastUpdateText = 'Last updated: ${diff.inSeconds} seconds ago';
      } else if (diff.inMinutes < 60) {
        lastUpdateText = 'Last updated: ${diff.inMinutes} minutes ago';
      } else {
        lastUpdateText = 'Last updated: ${_lastUpdateTime!.toLocal()}';
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Location'),
        backgroundColor: mainBlue,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.layers),
            onSelected: (value) async {
              setState(() {
                _mapType = value;
              });
              // Save the map type setting
              try {
                await _storage.write(key: 'map_type', value: value);
              } catch (e) {
                print('Error saving map type setting: $e');
              }
              if (_carLocation != null && _mapController != null) {
                _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_carLocation!, 17.0));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'normal', child: Text('Standard')),
              const PopupMenuItem(value: 'satellite', child: Text('Satellite')),
              const PopupMenuItem(value: 'hybrid', child: Text('Hybrid')),
              const PopupMenuItem(value: 'terrain', child: Text('Terrain')),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (lastUpdateText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
                  child: Text(
                    lastUpdateText,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                ),
              Expanded(
                child: _carLocation == null
                    ? Center(
                        child: _error != null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                                  SizedBox(height: 12),
                                  Text(_error!, style: TextStyle(color: Colors.red, fontSize: 16)),
                                  SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _initLiveLocation,
                                    child: const Text('Retry'),
                                    style: ElevatedButton.styleFrom(backgroundColor: mainBlue),
                                  ),
                                ],
                              )
                            : CircularProgressIndicator(color: mainBlue),
                      )
                    : Listener(
                        onPointerDown: (_) {
                          if (_autoFollow) {
                            setState(() {
                              _autoFollow = false;
                            });
                          }
                        },
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _carLocation!,
                            zoom: 16,
                          ),
                          mapType: _getGoogleMapType(_mapType),
                          polylines: _isMoving && _trail.length > 1
                              ? {
                                  Polyline(
                                    polylineId: const PolylineId('car_trail'),
                                    points: _trail,
                                    color: Colors.blueAccent,
                                    width: 5,
                                  ),
                                }
                              : {},
                          markers: {
                            Marker(
                              markerId: const MarkerId('car'),
                              position: _carLocation!,
                              icon: BitmapDescriptor.defaultMarkerWithHue(_isMoving ? BitmapDescriptor.hueBlue : BitmapDescriptor.hueAzure),
                            ),
                          },
                          onMapCreated: (controller) {
                            _mapController = controller;
                          },
                          onCameraMoveStarted: () {
                            if (_autoFollow) {
                              setState(() {
                                _autoFollow = false;
                              });
                            }
                          },
                        ),
                      ),
              ),
            ],
          ),
          if (_carLocation != null) ...[
            // Center car button - moved to top right
            Positioned(
              top: 24,
              right: 24,
              child: FloatingActionButton(
                heroTag: 'center_car',
                backgroundColor: mainBlue,
                onPressed: () {
                  setState(() {
                    _autoFollow = true;
                  });
                  if (_carLocation != null && _mapController != null) {
                    _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_carLocation!, 17.0));
                  }
                },
                child: const Icon(Icons.my_location),
              ),
            ),
            // Directions button - bottom right
            Positioned(
              bottom: 20,
              right: 24,
              child: FloatingActionButton(
                heroTag: 'directions',
                backgroundColor: Colors.green,
                onPressed: _isGettingDirections ? null : _showDirections,
                child: _isGettingDirections 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.directions, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  MapType _getGoogleMapType(String type) {
    switch (type) {
      case 'satellite':
        return MapType.satellite;
      case 'hybrid':
        return MapType.hybrid;
      case 'terrain':
        return MapType.terrain;
      default:
        return MapType.normal;
    }
  }
} 