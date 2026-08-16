import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/constants/api_constants.dart';
import '../models/farm_plot_model.dart';
import '../providers/auth_provider.dart';
import '../providers/farm_plot_provider.dart';
import '../providers/irrigation_provider.dart';
import '../providers/notification_provider.dart';
import 'add_edit_farm_plot_screen.dart';
import 'profile_screen.dart';

// Modular Analytics Tab Components
import 'analytics/weather_stats_tab.dart';
import 'analytics/daily_trends_tab.dart';
import 'analytics/smart_insights_tab.dart';
import 'analytics/water_balance_tab.dart';
import 'analytics/history_logs_tab.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedTab = 0; // 0: Weather Stats, 1: Daily Trend, 2: Smart Insights, 3: Water Balance, 4: History Logs
  List<dynamic> _historyLogs = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchHistoryLogs();
    });
  }

  Future<void> _fetchHistoryLogs() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final farmPlotProvider = Provider.of<FarmPlotProvider>(context, listen: false);
    final selectedPlot = farmPlotProvider.selectedPlot;
    if (selectedPlot == null) return;

    setState(() => _isLoadingHistory = true);
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/irrigation/history/${selectedPlot.id}'),
        headers: {
          'Content-Type': 'application/json',
          if (auth.token != null) 'Authorization': 'Bearer ${auth.token}',
        },
      );
      if (res.statusCode == 200) {
        final List<dynamic> logs = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _historyLogs = logs;
            _isLoadingHistory = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingHistory = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  void _showNotificationCenterModal(BuildContext context) {
    final notifProvider = context.read<NotificationProvider>();
    notifProvider.markAllAsRead();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer<NotificationProvider>(
          builder: (ctx, notif, _) {
            final feed = notif.feed;
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(LucideIcons.bellRing, color: primaryColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Notification Center',
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                            ),
                          ],
                        ),
                        if (feed.isNotEmpty)
                          TextButton(
                            onPressed: () => notif.clearFeed(),
                            child: Text(
                              'Clear All',
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (feed.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.bellOff, size: 36, color: subtextColor),
                              const SizedBox(height: 12),
                              Text(
                                'No notifications yet',
                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Daily irrigation and weather alerts will appear here.',
                                style: GoogleFonts.inter(fontSize: 12, color: subtextColor),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: feed.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (ctx, idx) {
                            final item = feed[idx];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      item.type == 'weather' ? LucideIcons.cloudRain : LucideIcons.droplet,
                                      color: primaryColor,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                                              ),
                                            ),
                                            Text(
                                              item.timestamp,
                                              style: GoogleFonts.inter(fontSize: 10, color: subtextColor),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.body,
                                          style: GoogleFonts.inter(fontSize: 12, color: subtextColor, height: 1.3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final farmPlotProvider = Provider.of<FarmPlotProvider>(context);
    final irrigation = Provider.of<IrrigationProvider>(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final appBarBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
    final iconColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);

    final plot = farmPlotProvider.selectedPlot;
    final plots = farmPlotProvider.plots;
    final data = irrigation.irrigationData;

    final dailyBreakdown = (data?['daily_breakdown'] as List<dynamic>?) ?? [];
    final areaAcres = plot?.areaAcres ?? 2.5;

    // Volumetric Water Calculations
    double totalAppliedMm = 0.0;
    double totalRainMm = 0.0;
    double totalEtcMm = 0.0;

    for (var m in dailyBreakdown) {
      totalAppliedMm += (m['irrigation_applied_mm'] as num?)?.toDouble() ?? 0.0;
      totalRainMm += (m['rainfall_mm'] as num?)?.toDouble() ?? 0.0;
      totalEtcMm += (m['etc_mm'] as num?)?.toDouble() ?? 0.0;
    }

    final totalAppliedKL = (totalAppliedMm * areaAcres * 4046.86) / 1000.0;
    final totalRainKL = (totalRainMm * areaAcres * 4046.86) / 1000.0;
    final totalEtcKL = (totalEtcMm * areaAcres * 4046.86) / 1000.0;
    final totalSupplyMm = totalAppliedMm + totalRainMm;

    final satisfactionRatio = totalEtcMm > 0 ? (totalSupplyMm / totalEtcMm) * 100.0 : 100.0;
    final isOptimal = satisfactionRatio >= 85.0 && satisfactionRatio <= 115.0;
    final isDeficit = satisfactionRatio < 85.0;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: appBarBg,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.barChart2, color: iconColor, size: 20),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Field Analytics',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notif, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(LucideIcons.bell, color: iconColor, size: 20),
                    onPressed: () => _showNotificationCenterModal(context),
                    tooltip: 'Notification Center',
                  ),
                  if (notif.unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${notif.unreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: Icon(LucideIcons.refreshCw, color: iconColor, size: 20),
            onPressed: () async {
              final notif = context.read<NotificationProvider>();
              await farmPlotProvider.fetchPlots(auth: auth, irrigation: irrigation);
              await irrigation.loadIrrigationData(notificationProvider: notif);
              _fetchHistoryLogs();
            },
            tooltip: 'Refresh Analytics',
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0, left: 4.0),
              child: Tooltip(
                message: 'Profile & Settings',
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: iconColor, width: 1.5),
                  ),
                  child: CircleAvatar(
                    radius: 13,
                    backgroundColor: iconColor.withValues(alpha: 0.15),
                    child: Text(
                      (auth.user?.profile?.firstName ?? auth.user?.username ?? 'F').substring(0, 1).toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plot Selector Header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.mapPin, color: primaryColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<FarmPlotModel>(
                        value: plot,
                        isExpanded: true,
                        dropdownColor: cardBg,
                        icon: Icon(LucideIcons.chevronDown, color: primaryColor, size: 18),
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                        items: plots.map((p) {
                          return DropdownMenuItem<FarmPlotModel>(
                            value: p,
                            child: Text(p.name, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (newPlot) {
                          if (newPlot != null) {
                            farmPlotProvider.selectPlot(newPlot, irrigation);
                            _fetchHistoryLogs();
                          }
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.plusCircle, color: primaryColor, size: 20),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddEditFarmPlotScreen()),
                      );
                    },
                    tooltip: 'Add Plot',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab Bar Controls (5 Modular Tabs)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabChip(0, '🌦️ Weather Stats', isDark, primaryColor, textColor),
                  _buildTabChip(1, '📊 Daily Trend', isDark, primaryColor, textColor),
                  _buildTabChip(2, '💡 Smart Insights', isDark, primaryColor, textColor),
                  _buildTabChip(3, '🌊 Water Balance', isDark, primaryColor, textColor),
                  _buildTabChip(4, '📋 History Logs', isDark, primaryColor, textColor),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Modular Tab Views
            if (_selectedTab == 0) ...[
              WeatherStatsTab(
                dailyBreakdown: dailyBreakdown,
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subtextColor: subtextColor,
                primaryColor: primaryColor,
              ),
            ] else if (_selectedTab == 1) ...[
              DailyTrendsTab(
                dailyBreakdown: dailyBreakdown,
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subtextColor: subtextColor,
                primaryColor: primaryColor,
              ),
            ] else if (_selectedTab == 2) ...[
              SmartInsightsTab(
                irrigationData: data,
                satisfactionRatio: satisfactionRatio,
                isOptimal: isOptimal,
                isDeficit: isDeficit,
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subtextColor: subtextColor,
                primaryColor: primaryColor,
              ),
            ] else if (_selectedTab == 3) ...[
              WaterBalanceTab(
                totalAppliedMm: totalAppliedMm,
                totalRainMm: totalRainMm,
                totalEtcMm: totalEtcMm,
                totalAppliedKL: totalAppliedKL,
                totalRainKL: totalRainKL,
                totalEtcKL: totalEtcKL,
                satisfactionRatio: satisfactionRatio,
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subtextColor: subtextColor,
                primaryColor: primaryColor,
              ),
            ] else ...[
              HistoryLogsTab(
                selectedPlot: plot,
                historyLogs: _historyLogs,
                isLoading: _isLoadingHistory,
                onRefreshRequested: _fetchHistoryLogs,
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subtextColor: subtextColor,
                primaryColor: primaryColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip(int index, String label, bool isDark, Color primaryColor, Color textColor) {
    final isSelected = _selectedTab == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : (isDark ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? primaryColor : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : textColor,
            ),
          ),
        ),
      ),
    );
  }
}
