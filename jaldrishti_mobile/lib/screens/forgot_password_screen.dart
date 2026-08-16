import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _otpSent = false;
  bool _obscurePassword = true;
  String? _statusMessage;
  String? _devOtp;

  @override
  void dispose() {
    _identifierController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _handleRequestOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final result = await auth.requestPasswordResetOtp(_identifierController.text.trim());

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _otpSent = true;
        _statusMessage = result['message'];
        _devOtp = result['otp_code_dev'];
        if (_devOtp != null) {
          _otpController.text = _devOtp!;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_statusMessage ?? 'OTP Sent! Check your mobile messages.'),
          backgroundColor: const Color(0xFF0284C7),
        ),
      );
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.resetPasswordWithOtp(
      phoneNumber: _identifierController.text.trim(),
      otpCode: _otpController.text.trim(),
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Password Reset Successfully! Please sign in with your new password.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                  ),
                  child: const Icon(
                    LucideIcons.keyRound,
                    size: 44,
                    color: Color(0xFF38BDF8),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Reset Password',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _otpSent
                      ? 'Enter the 6-digit OTP code sent to your mobile & set a new password.'
                      : 'Enter your phone number or username to receive a 6-digit verification OTP.',
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Main Form Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF334155)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Phone or Username Input
                        TextFormField(
                          controller: _identifierController,
                          enabled: !_otpSent,
                          maxLength: 50,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r"[<>'\\;]")),
                          ],
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Registered Username or Phone',
                            labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                            prefixIcon: const Icon(LucideIcons.phone, color: Color(0xFF38BDF8)),
                            counterText: '',
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty) ? 'Please enter username or phone' : null,
                        ),

                        if (_otpSent) ...[
                          const SizedBox(height: 16),

                          // Dev OTP Alert Banner
                          if (_devOtp != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF38BDF8)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.smartphone, color: Color(0xFF38BDF8), size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '📱 Dev SMS OTP: $_devOtp (Pre-filled for fast testing)',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // 6-Digit OTP Code Input
                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 6,
                            ),
                            decoration: InputDecoration(
                              labelText: '6-Digit Verification OTP',
                              labelStyle: const TextStyle(color: Color(0xFF94A3B8), letterSpacing: 0),
                              prefixIcon: const Icon(LucideIcons.shieldCheck, color: Color(0xFF38BDF8)),
                              counterText: '',
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (val) =>
                                (val == null || val.trim().length != 6) ? 'Enter 6-digit OTP code' : null,
                          ),
                          const SizedBox(height: 16),

                          // New Password Input
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: _obscurePassword,
                            maxLength: 64,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'New Password',
                              labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                              prefixIcon: const Icon(LucideIcons.lock, color: Color(0xFF38BDF8)),
                              counterText: '',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                                  color: const Color(0xFF94A3B8),
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (val) =>
                                (val == null || val.length < 6) ? 'Password must be at least 6 characters' : null,
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Action Button
                        ElevatedButton(
                          onPressed: auth.isLoading
                              ? null
                              : (_otpSent ? _handleResetPassword : _handleRequestOtp),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  _otpSent ? 'Confirm Reset & Sign In' : 'Send OTP Verification Code',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
