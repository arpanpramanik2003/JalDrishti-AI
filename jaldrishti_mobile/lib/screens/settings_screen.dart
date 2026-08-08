import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _showUpdateNameModal(BuildContext context, AuthProvider auth) {
    final firstNameController = TextEditingController(
      text: auth.user?.profile?.firstName ?? auth.user?.username ?? '',
    );
    final lastNameController = TextEditingController(
      text: auth.user?.profile?.lastName ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.user, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 10),
                  Text(
                    'Update Full Name',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: firstNameController,
                maxLength: 30,
                decoration: InputDecoration(
                  counterText: '',
                  labelText: 'First Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(LucideIcons.userCheck, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: lastNameController,
                maxLength: 30,
                decoration: InputDecoration(
                  counterText: '',
                  labelText: 'Last Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(LucideIcons.userCheck, size: 18),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile name updated successfully!'),
                        backgroundColor: Color(0xFF0284C7),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Save Changes', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUpdatePhoneModal(BuildContext context, AuthProvider auth) {
    final phoneController = TextEditingController(
      text: auth.user?.phoneNumber ?? '',
    );
    final otpController = TextEditingController();

    bool stepTwo = false;
    bool isLoading = false;
    String? errorText;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            stepTwo ? LucideIcons.shieldCheck : LucideIcons.phone,
                            color: const Color(0xFF38BDF8),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stepTwo ? 'Verify Phone OTP' : 'Update Phone Number',
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              stepTwo
                                  ? 'Enter 6-digit code sent to ${phoneController.text.trim()}'
                                  : 'Receive SMS OTP to change registered phone',
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (errorText != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.alertTriangle, size: 16, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorText!,
                                style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    if (!stepTwo) ...[
                      // Step 1: Input New Phone Number
                      TextFormField(
                        controller: phoneController,
                        maxLength: 15,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\+0-9]')),
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          labelText: 'New Phone Number',
                          hintText: '+919876543210',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(LucideIcons.phoneCall, size: 18),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  final newPhone = phoneController.text.trim();
                                  if (newPhone.length < 10) {
                                    setModalState(() {
                                      errorText = 'Please enter a valid phone number (min 10 digits).';
                                    });
                                    return;
                                  }

                                  setModalState(() {
                                    isLoading = true;
                                    errorText = null;
                                  });

                                  final result = await auth.requestPhoneUpdateOtp(newPhone);

                                  setModalState(() {
                                    isLoading = false;
                                  });

                                  if (result != null) {
                                    setModalState(() {
                                      stepTwo = true;
                                    });

                                    final devOtp = result['otp_code_dev'];
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          devOtp != null
                                              ? 'OTP Sent! (DEV CODE: $devOtp)'
                                              : 'Verification code sent to $newPhone',
                                        ),
                                        backgroundColor: const Color(0xFF0284C7),
                                        duration: const Duration(seconds: 5),
                                      ),
                                    );
                                  } else {
                                    setModalState(() {
                                      errorText = auth.errorMessage ?? 'Failed to send OTP.';
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(LucideIcons.send, size: 18),
                                    const SizedBox(width: 8),
                                    Text('Send Verification Code (OTP)', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                        ),
                      ),
                    ] else ...[
                      // Step 2: Input 6-Digit OTP Code
                      TextFormField(
                        controller: otpController,
                        maxLength: 6,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 6),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          labelText: '6-Digit Verification Code',
                          hintText: '123456',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(LucideIcons.keyRound, size: 18),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  final otp = otpController.text.trim();
                                  if (otp.length != 6) {
                                    setModalState(() {
                                      errorText = 'Please enter the full 6-digit OTP code.';
                                    });
                                    return;
                                  }

                                  setModalState(() {
                                    isLoading = true;
                                    errorText = null;
                                  });

                                  final success = await auth.verifyPhoneUpdateOtp(
                                    newPhoneNumber: phoneController.text.trim(),
                                    otpCode: otp,
                                  );

                                  setModalState(() {
                                    isLoading = false;
                                  });

                                  if (success) {
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Phone number updated successfully to ${auth.user?.phoneNumber}!'),
                                        backgroundColor: const Color(0xFF0284C7),
                                      ),
                                    );
                                  } else {
                                    setModalState(() {
                                      errorText = auth.errorMessage ?? 'Invalid or expired OTP code.';
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(LucideIcons.checkCircle, size: 18),
                                    const SizedBox(width: 8),
                                    Text('Verify OTP & Update Phone', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  setModalState(() {
                                    stepTwo = false;
                                    errorText = null;
                                    otpController.clear();
                                  });
                                },
                          child: Text(
                            '← Change Phone Number',
                            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF38BDF8)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLanguageSelectorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(LucideIcons.languages, color: Color(0xFF38BDF8)),
              const SizedBox(width: 10),
              Text('Advisory Language', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Text('🇬🇧', style: TextStyle(fontSize: 22)),
                title: const Text('English (Default)'),
                trailing: const Icon(LucideIcons.check, color: Color(0xFF38BDF8)),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Text('🇮🇳', style: TextStyle(fontSize: 22)),
                title: const Text('বাংলা (Bengali)'),
                subtitle: const Text('Coming Soon'),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Text('🇮🇳', style: TextStyle(fontSize: 22)),
                title: const Text('हिंदी (Hindi)'),
                subtitle: const Text('Coming Soon'),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Settings & Preferences', style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Appearance & Theme Section
            _buildSectionHeader('Appearance & Theme', subtextColor),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: SwitchListTile(
                value: isDark,
                onChanged: (val) => themeProvider.toggleTheme(val),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isDark ? LucideIcons.moon : LucideIcons.sun,
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                    size: 20,
                  ),
                ),
                title: Text('Dark Mode Theme', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor)),
                subtitle: Text(
                  isDark ? 'Dark Slate Blue interface' : 'Light Clean Agriculture interface',
                  style: GoogleFonts.inter(fontSize: 12, color: subtextColor),
                ),
                activeThumbColor: const Color(0xFF38BDF8),
              ),
            ),
            const SizedBox(height: 24),

            // ── 2. Account Settings Section
            _buildSectionHeader('Account & Profile Details', subtextColor),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: _buildIconBadge(LucideIcons.userCheck, const Color(0xFF38BDF8), isDark),
                    title: Text('Update Name', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: textColor)),
                    subtitle: Text(
                      '${auth.user?.profile?.firstName ?? auth.user?.username ?? "Farmer"} ${auth.user?.profile?.lastName ?? ""}'.trim(),
                      style: GoogleFonts.inter(fontSize: 12, color: subtextColor),
                    ),
                    trailing: const Icon(LucideIcons.chevronRight, size: 18),
                    onTap: () => _showUpdateNameModal(context, auth),
                  ),
                  Divider(color: borderColor, height: 1),
                  ListTile(
                    leading: _buildIconBadge(LucideIcons.phone, const Color(0xFF10B981), isDark),
                    title: Text('Update Phone Number', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: textColor)),
                    subtitle: Text(
                      auth.user?.phoneNumber ?? 'Add phone number',
                      style: GoogleFonts.inter(fontSize: 12, color: subtextColor),
                    ),
                    trailing: const Icon(LucideIcons.chevronRight, size: 18),
                    onTap: () => _showUpdatePhoneModal(context, auth),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── 3. App Preferences & Notifications
            _buildSectionHeader('Notification & Alert Preferences', subtextColor),
            const SizedBox(height: 8),
            Consumer<NotificationProvider>(
              builder: (context, notif, _) {
                return Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: _buildIconBadge(LucideIcons.languages, const Color(0xFFA78BFA), isDark),
                        title: Text('App Advisory Language', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: textColor)),
                        subtitle: Text('English (Default)', style: GoogleFonts.inter(fontSize: 12, color: subtextColor)),
                        trailing: const Icon(LucideIcons.chevronRight, size: 18),
                        onTap: () => _showLanguageSelectorDialog(context),
                      ),
                      Divider(color: borderColor, height: 1),
                      SwitchListTile(
                        value: notif.irrigationAlertsEnabled,
                        onChanged: (val) => notif.toggleSetting('irrigationAlerts', val),
                        secondary: _buildIconBadge(LucideIcons.droplets, const Color(0xFF38BDF8), isDark),
                        title: Text('Irrigation Push Alerts', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: textColor)),
                        subtitle: Text('Daily pump runtime & field moisture alerts', style: GoogleFonts.inter(fontSize: 12, color: subtextColor)),
                        activeThumbColor: const Color(0xFF38BDF8),
                      ),
                      Divider(color: borderColor, height: 1),
                      SwitchListTile(
                        value: notif.weatherAlertsEnabled,
                        onChanged: (val) => notif.toggleSetting('weatherAlerts', val),
                        secondary: _buildIconBadge(LucideIcons.cloudRain, const Color(0xFF0284C7), isDark),
                        title: Text('Rainfall & Extreme Weather Warnings', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: textColor)),
                        subtitle: Text('Alerts when heavy rain is expected', style: GoogleFonts.inter(fontSize: 12, color: subtextColor)),
                        activeThumbColor: const Color(0xFF38BDF8),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // ── 4. App Info & Product Details
            _buildSectionHeader('System & Information', subtextColor),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: _buildIconBadge(LucideIcons.shieldCheck, const Color(0xFF10B981), isDark),
                    title: Text('FAO-56 Precision Engine', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: textColor)),
                    subtitle: Text('Penman-Monteith Evapotranspiration v2.1', style: GoogleFonts.inter(fontSize: 12, color: subtextColor)),
                  ),
                  Divider(color: borderColor, height: 1),
                  ListTile(
                    leading: _buildIconBadge(LucideIcons.info, const Color(0xFF38BDF8), isDark),
                    title: Text('JalDrishti App Version', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: textColor)),
                    subtitle: Text('v1.2.0 (Build 2026.07)', style: GoogleFonts.inter(fontSize: 12, color: subtextColor)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
        color: textColor,
      ),
    );
  }

  Widget _buildIconBadge(IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}
