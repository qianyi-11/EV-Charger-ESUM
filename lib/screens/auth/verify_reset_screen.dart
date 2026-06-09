import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_form_field.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/glass_container.dart';

class VerifyResetScreen extends StatefulWidget {
  final String email;

  const VerifyResetScreen({super.key, required this.email});

  @override
  State<VerifyResetScreen> createState() => _VerifyResetScreenState();
}

class _VerifyResetScreenState extends State<VerifyResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (!AuthService.isValidPassword(value)) {
      return AuthService.passwordRequirementsText;
    }
    return null;
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await AuthService.instance.confirmPasswordReset(
        email: widget.email,
        code: _codeController.text,
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated. You can sign in now.'),
          backgroundColor: AppColors.secondaryBg,
        ),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.dangerRed),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Reset Password',
      subtitle: 'Enter the verification code sent to ${widget.email}',
      child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(14),
                child: Text(
                'Check your email for the verification code. '
                'In development, the code is also printed in the server terminal.',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.95),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AuthFormField(
                controller: _codeController,
                label: 'Verification code',
                hint: 'Paste code from email',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Verification code is required' : null,
              ),
              const SizedBox(height: 16),
              AuthFormField(
                controller: _passwordController,
                label: 'New password',
                hint: '8–16 chars, upper, lower, number, symbol',
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),
              AuthFormField(
                controller: _confirmController,
                label: 'Confirm new password',
                hint: 'Re-enter new password',
                obscureText: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please confirm your password';
                  if (v != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricBlue,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Text(
                          'Update Password',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}
