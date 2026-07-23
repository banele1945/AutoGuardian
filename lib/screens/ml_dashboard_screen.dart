import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/flutter_ml_services.dart';
import 'dart:convert';

class MLDashboardScreen extends StatefulWidget {
  const MLDashboardScreen({Key? key}) : super(key: key);

  @override
  State<MLDashboardScreen> createState() => _MLDashboardScreenState();
}

class _MLDashboardScreenState extends State<MLDashboardScreen> {
  final _storage = FlutterSecureStorage();
  AutoGuardianMLService? _mlService;
  
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _anomalies = [];
  bool _isLoading = true;
  bool _isTraining = false;
  String? _error;

  final Color mainBlue = const Color(0xFF1565C0);
  final Color accentBlue = const Color(0xFF42A5F5);

  @override
  void initState() {
    super.initState();
    _initializeMLService().then((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _initializeMLService() async {
    try {
      final token = await _storage.read(key: 'jwt');
      if (token == null) {
        setState(() {
          _error = 'Authentication required';
          _isLoading = false;
        });
        return;
      }

      _mlService = AutoGuardianMLService(
        baseUrl: 'http://10.0.2.2:5000/api/ml',
        apiKey: token,
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize ML service: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    if (_mlService == null) {
      setState(() {
        _error = 'ML service not initialized';
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load statistics and anomalies in parallel
      final results = await Future.wait([
        _mlService!.getUserStats(),
        _mlService!.getAnomalyHistory(),
      ]);

      setState(() {
        _stats = results[0];
        _anomalies = List<Map<String, dynamic>>.from(results[1]['anomalies'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _trainModels() async {
    if (_mlService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ML service not initialized'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isTraining = true;
      });

      await _mlService!.trainModels();
      
      // Reload data after training
      await _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI models trained successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to train models: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isTraining = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI/ML Dashboard'),
        backgroundColor: mainBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: mainBlue))
          : _error != null
              ? _buildErrorWidget()
              : _buildDashboardContent(),
      floatingActionButton: _mlService != null && _error == null
          ? FloatingActionButton.extended(
              onPressed: _isTraining ? null : _trainModels,
              backgroundColor: mainBlue,
              icon: _isTraining
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.psychology),
              label: Text(_isTraining ? 'Training...' : 'Train AI'),
            )
          : null,
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 64),
          SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: mainBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI/ML Statistics
          MLStatsWidget(stats: _stats),
          
          SizedBox(height: 24),
          
          // Recent Anomalies
          _buildAnomaliesSection(),
          
          SizedBox(height: 24),
          
          // AI Insights
          _buildInsightsSection(),
        ],
      ),
    );
  }

  Widget _buildAnomaliesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text(
              'Recent Anomalies',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Spacer(),
            Text(
              '${_anomalies.length} detected',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        if (_anomalies.isEmpty)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No anomalies detected - driving patterns are normal',
                    style: TextStyle(color: Colors.green[700]),
                  ),
                ),
              ],
            ),
          )
        else
          ..._anomalies.take(3).map((anomaly) => AnomalyAlertWidget(
            anomalyData: anomaly,
            onDismiss: () {
              setState(() {
                _anomalies.remove(anomaly);
              });
            },
          )),
      ],
    );
  }

  Widget _buildInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.insights, color: mainBlue),
            SizedBox(width: 8),
            Text(
              'AI Insights',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        _buildInsightCard(
          'Driving Safety Score',
          _calculateSafetyScore(),
          Icons.security,
          Colors.green,
        ),
        SizedBox(height: 8),
        _buildInsightCard(
          'Route Consistency',
          _calculateRouteConsistency(),
          Icons.route,
          Colors.blue,
        ),
        SizedBox(height: 8),
        _buildInsightCard(
          'Speed Compliance',
          _calculateSpeedCompliance(),
          Icons.speed,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildInsightCard(String title, double score, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${(score * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: score,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeWidth: 4,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateSafetyScore() {
    if (_anomalies.isEmpty) return 1.0;
    final anomalyCount = _anomalies.length;
    final baseScore = 1.0 - (anomalyCount * 0.1);
    return baseScore.clamp(0.0, 1.0);
  }

  double _calculateRouteConsistency() {
    // Mock calculation based on available data
    final totalTrips = _stats['total_trips'] ?? 0;
    final uniqueRoutes = _stats['unique_routes'] ?? 0;
    
    if (totalTrips == 0) return 0.8; // Default score
    
    final consistency = uniqueRoutes / totalTrips;
    return (1.0 - consistency).clamp(0.0, 1.0);
  }

  double _calculateSpeedCompliance() {
    final avgSpeed = _stats['avg_speed'] ?? 0.0;
    final maxSpeed = _stats['max_speed'] ?? 0.0;
    
    if (avgSpeed == 0) return 0.9; // Default score
    
    // Calculate compliance based on speed limits
    final speedLimit = 120.0; // km/h
    final avgCompliance = (speedLimit - avgSpeed) / speedLimit;
    final maxCompliance = (speedLimit - maxSpeed) / speedLimit;
    
    return ((avgCompliance + maxCompliance) / 2).clamp(0.0, 1.0);
  }
} 