import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final bool obscureText;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final VoidCallback? onSuffixTap;

  const CustomTextField({
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.validator,
    this.suffixIcon,
    this.onSuffixTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        suffixIcon: suffixIcon != null
            ? GestureDetector(
                onTap: onSuffixTap,
                child: suffixIcon,
              )
            : null,
      ),
      validator: validator,
    );
  }
} 