import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class PasswordConfirmationDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmButtonText;
  final Color confirmButtonColor;

  const PasswordConfirmationDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.confirmButtonText,
    required this.confirmButtonColor,
  }) : super(key: key);

  @override
  State<PasswordConfirmationDialog> createState() => _PasswordConfirmationDialogState();
}

class _PasswordConfirmationDialogState extends State<PasswordConfirmationDialog> {
  final TextEditingController _passwordController = TextEditingController();
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _validatePassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get stored password
      final storedPassword = await _storage.read(key: 'user_password');
      
      if (storedPassword == null) {
        setState(() {
          _errorMessage = 'No password found. Please log out and log in again to set up password verification.';
          _isLoading = false;
        });
        return;
      }

      if (_passwordController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter your password.';
          _isLoading = false;
        });
        return;
      }

      if (_passwordController.text == storedPassword) {
        _onPasswordValid();
      } else {
        setState(() {
          _errorMessage = 'Incorrect password. Please try again.';
          _isLoading = false;
        });
        // Clear the password field for security
        _passwordController.clear();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error validating password. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _onPasswordValid() {
    setState(() {
      _isLoading = false;
    });
    Navigator.of(context).pop(true); // Return true for success
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.security, color: Colors.red, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.message,
            style: GoogleFonts.poppins(fontSize: 16),
          ),
          SizedBox(height: 20),
          Text(
            'Enter your password to confirm:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey[600],
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              hintText: 'Enter password',
              hintStyle: TextStyle(color: Colors.grey[500]),
            ),
            onSubmitted: (_) => _validatePassword(),
          ),
          if (_errorMessage != null) ...[
            SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _validatePassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.confirmButtonColor == Colors.red 
              ? Colors.red[600] 
              : widget.confirmButtonColor == Colors.green 
              ? Colors.green[600] 
              : widget.confirmButtonColor,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  widget.confirmButtonText,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }
} 