import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';

class PasswordChangeService {
  final String _baseUrl = 'http://10.0.2.2:5000';
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      // Get JWT token
      final token = await _storage.read(key: 'jwt');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // Validate passwords
      final validationResult = _validatePasswords(newPassword, confirmPassword);
      if (!validationResult['valid']) {
        return {
          'success': false,
          'error': validationResult['error'],
        };
      }

      // Make API request
      final response = await http.put(
        Uri.parse('$_baseUrl/api/users/change-password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // Update stored password for kill switch verification
        await _storage.write(key: 'user_password', value: newPassword);
        
        return {
          'success': true,
          'message': responseData['message'] ?? 'Password changed successfully',
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to change password',
        };
      }
    } catch (e) {
      print('Password change error: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  Map<String, dynamic> _validatePasswords(String newPassword, String confirmPassword) {
    // Check if passwords match
    if (newPassword != confirmPassword) {
      return {
        'valid': false,
        'error': 'New passwords do not match',
      };
    }

    // Check minimum length
    if (newPassword.length < 6) {
      return {
        'valid': false,
        'error': 'Password must be at least 6 characters long',
      };
    }

    // Check for common passwords (basic check)
    final commonPasswords = [
      'password',
      '123456',
      'qwerty',
      'admin',
      'user',
      'test',
    ];
    
    if (commonPasswords.contains(newPassword.toLowerCase())) {
      return {
        'valid': false,
        'error': 'Password is too common. Please choose a stronger password',
      };
    }

    // Check for basic strength (at least one letter and one number)
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(newPassword);
    final hasNumber = RegExp(r'[0-9]').hasMatch(newPassword);
    
    if (!hasLetter || !hasNumber) {
      return {
        'valid': false,
        'error': 'Password must contain at least one letter and one number',
      };
    }

    return {
      'valid': true,
      'error': null,
    };
  }

  // Method to check password strength
  Map<String, dynamic> getPasswordStrength(String password) {
    int score = 0;
    List<String> feedback = [];

    // Length check
    if (password.length >= 8) {
      score += 2;
    } else if (password.length >= 6) {
      score += 1;
    } else {
      feedback.add('Password should be at least 6 characters long');
    }

    // Character variety checks
    if (RegExp(r'[a-z]').hasMatch(password)) score += 1;
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 1;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 1;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score += 1;

    // Determine strength level
    String strength;
    Color strengthColor;
    
    if (score >= 4) {
      strength = 'Strong';
      strengthColor = Colors.green;
    } else if (score >= 2) {
      strength = 'Medium';
      strengthColor = Colors.orange;
    } else {
      strength = 'Weak';
      strengthColor = Colors.red;
    }

    return {
      'score': score,
      'strength': strength,
      'color': strengthColor,
      'feedback': feedback,
    };
  }
} 