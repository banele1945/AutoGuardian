import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeService extends ChangeNotifier {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoading = true;

  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;

  ThemeService() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final themeString = await _storage.read(key: 'theme');
      if (themeString != null) {
        switch (themeString.toLowerCase()) {
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          case 'auto':
            _themeMode = ThemeMode.system;
            break;
          default:
            _themeMode = ThemeMode.light;
        }
      }
    } catch (e) {
      print('Error loading theme: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setTheme(String theme) async {
    try {
      await _storage.write(key: 'theme', value: theme);
      
      switch (theme.toLowerCase()) {
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        case 'auto':
          _themeMode = ThemeMode.system;
          break;
        default:
          _themeMode = ThemeMode.light;
      }
      
      notifyListeners();
    } catch (e) {
      print('Error saving theme: $e');
    }
  }

  ThemeData getLightTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFF1565C0);
          }
          return null;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFF1565C0).withOpacity(0.5);
          }
          return null;
        }),
      ),
    );
  }

  ThemeData getDarkTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF1E1E1E),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFF1565C0);
          }
          return null;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFF1565C0).withOpacity(0.5);
          }
          return null;
        }),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: Colors.white,
        iconColor: Color(0xFF1565C0),
      ),
    );
  }
} 