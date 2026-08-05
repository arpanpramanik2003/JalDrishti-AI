import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/home_dashboard_screen.dart';
import '../screens/pest_advisory_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/profile_screen.dart';
import '../widgets/server_config_dialog.dart';

class AppDrawer extends StatelessWidget {
  final String activeRoute;

  const AppDrawer({super.key, this.activeRoute = 'dashboard'});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final drawerBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final accentColor = const Color(0xFF38BDF8);
    final itemSelectedBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFE0F2FE);

    final userName = auth.user?.profile?.firstName ?? auth.user?.username ?? 'Farmer';
    final userPhone = auth.user?.phoneNumber ?? '+91 **********';
    final location = auth.user?.profile?.locationName ?? 'Kolkata, WB';

    return Drawer(
      backgroundColor: drawerBg,
      child: Column(
        children: [
          // Drawer Header
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0284C7), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icons/android-chrome-192x192.png',
                      height: 48,
                      width: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Icon(LucideIcons.user, color: accentColor, size: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(LucideIcons.phone, size: 12, color: Color(0xFF38BDF8)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              userPhone,
                              style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(LucideIcons.mapPin, size: 12, color: Color(0xFF38BDF8)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Menu List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              children: [
                _buildDrawerItem(
                  context,
                  icon: LucideIcons.layoutDashboard,
                  title: 'Irrigation Dashboard',
                  isSelected: activeRoute == 'dashboard',
                  selectedBg: itemSelectedBg,
                  accentColor: accentColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () {
                    Navigator.pop(context);
                    if (activeRoute != 'dashboard') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
                      );
                    }
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: LucideIcons.bug,
                  title: 'Pest & Disease Advisory',
                  badgeText: 'HOT',
                  isSelected: activeRoute == 'pest_advisory',
                  selectedBg: itemSelectedBg,
                  accentColor: const Color(0xFFEF4444),
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () {
                    Navigator.pop(context);
                    if (activeRoute != 'pest_advisory') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PestAdvisoryScreen()),
                      );
                    }
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: LucideIcons.barChart2,
                  title: 'Analytics & Water Logs',
                  isSelected: activeRoute == 'analytics',
                  selectedBg: itemSelectedBg,
                  accentColor: accentColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () {
                    Navigator.pop(context);
                    if (activeRoute != 'analytics') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                      );
                    }
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: LucideIcons.bot,
                  title: 'JalSathi AI Agronomist',
                  isSelected: activeRoute == 'chat',
                  selectedBg: itemSelectedBg,
                  accentColor: const Color(0xFF10B981),
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () {
                    Navigator.pop(context);
                    if (activeRoute != 'chat') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatScreen()),
                      );
                    }
                  },
                ),
                Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), height: 24),
                _buildDrawerItem(
                  context,
                  icon: LucideIcons.user,
                  title: 'Farmer Profile',
                  isSelected: activeRoute == 'profile',
                  selectedBg: itemSelectedBg,
                  accentColor: accentColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: LucideIcons.settings,
                  title: 'App Settings',
                  isSelected: activeRoute == 'settings',
                  selectedBg: itemSelectedBg,
                  accentColor: accentColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: LucideIcons.server,
                  title: 'Backend Server Config',
                  isSelected: false,
                  selectedBg: itemSelectedBg,
                  accentColor: const Color(0xFFF59E0B),
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () {
                    Navigator.pop(context);
                    ServerConfigDialog.show(context);
                  },
                ),
              ],
            ),
          ),

          // App Footer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.shieldCheck, size: 14, color: Color(0xFF10B981)),
                const SizedBox(width: 6),
                Text(
                  'FAO-56 Precision Engine v2.1',
                  style: GoogleFonts.inter(fontSize: 11, color: subtextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isSelected,
    required Color selectedBg,
    required Color accentColor,
    required Color textColor,
    required Color subtextColor,
    required VoidCallback onTap,
    String? badgeText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? selectedBg : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? accentColor : subtextColor, size: 20),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? accentColor : textColor,
          ),
        ),
        trailing: badgeText != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              )
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}
