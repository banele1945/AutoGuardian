import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/live_location_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/alert_detail_screen.dart';
import 'screens/trips_screen.dart';
import 'screens/trip_detail_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/ml_dashboard_screen.dart';
import 'services/theme_service.dart';
import 'services/notification_service.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await FirebaseService.initialize();
  
  try {
    await dotenv.load();
  } catch (e) {
    print('Warning: Could not load .env file: $e');
    print('Please ensure .env file exists in project root with GOOGLE_MAPS_API_KEY');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeService()),
        ChangeNotifierProvider(create: (context) => NotificationService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'AutoGuardian',
            themeMode: themeService.themeMode,
            theme: themeService.getLightTheme().copyWith(
              textTheme: GoogleFonts.poppinsTextTheme(themeService.getLightTheme().textTheme),
            ),
            darkTheme: themeService.getDarkTheme().copyWith(
              textTheme: GoogleFonts.poppinsTextTheme(themeService.getDarkTheme().textTheme),
            ),
            home: LoginScreen(),
            routes: {
              '/live-location': (context) => const LiveLocationScreen(),
              '/alerts': (context) => AlertsScreen(),
              '/trips': (context) => TripsScreen(),
              '/settings': (context) => SettingsScreen(),
              '/ml-dashboard': (context) => const MLDashboardScreen(),
              // Note: AlertDetailScreen is navigated to via MaterialPageRoute with parameters
            },
          );
        },
      ),
    );
  }
}
