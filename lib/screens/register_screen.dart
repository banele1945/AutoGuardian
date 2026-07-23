import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/custom_text_field.dart';
import '../auth/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _register() async {
    setState(() {
      _error = null;
    });
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _loading = true);
      final error = await _authService.register(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      setState(() => _loading = false);
      if (error == null) {
        // Show success and navigate to login
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Registration Successful'),
              content: Text('You can now log in with your credentials.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        setState(() => _error = error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color mainBlue = Color(0xFF1565C0);
    final Color accentBlue = Color(0xFF42A5F5);
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [mainBlue, accentBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo (custom branding)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.white, accentBlue.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.security,
                      color: mainBlue,
                      size: 48,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Create Account',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Sign up to get started',
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
                ),
                SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextField(
                        label: 'Username',
                        controller: _usernameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Username required';
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      CustomTextField(
                        label: 'Password',
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Password required';
                          if (value.length < 6) return 'Minimum 6 characters';
                          return null;
                        },
                        suffixIcon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onSuffixTap: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      SizedBox(height: 20),
                      CustomTextField(
                        label: 'Confirm Password',
                        controller: _confirmController,
                        obscureText: _obscureConfirm,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Confirm your password';
                          if (value != _passwordController.text) return 'Passwords do not match';
                          return null;
                        },
                        suffixIcon: Icon(
                          _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onSuffixTap: () {
                          setState(() {
                            _obscureConfirm = !_obscureConfirm;
                          });
                        },
                      ),
                      SizedBox(height: 8),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(_error!, style: TextStyle(color: Colors.red[200])),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _register,
                          child: _loading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text('Register', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainBlue,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account?', style: TextStyle(color: Colors.white)),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('Login', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 