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
    final farmPlotProvider = Provider.of<FarmPlotProvider>(context, listen: false);
    final selectedPlot = farmPlotProvider.selectedPlot;
    if (selectedPlot == null) return;

    setState(() => _isLoadingHistory = true);
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/irrigation/history/${selectedPlot.id}'),
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
    final weatherForecast = (data?['weather_forecast'] as List<dynamic>?) ?? [];
    final areaAcres = plot?.areaAcres ?? 2.5;

    // Calculations
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

    final satisfactionRatio = totalEtcMm > 0 ? (totalSupplyMm / totalEtcMm) * 100 : 100.0;
    final isOptimal = satisfactionRatio >= 85 && satisfactionRatio <= 115;
    final isDeficit = satisfactionRatio < 85;
    final savedKL = (totalAppliedKL * 0.30);
    final savedMoneyRupees = (savedKL * 8.5);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: appBarBg,
        title: Row(
          children: [
            Icon(LucideIcons.barChart2, color: iconColor, size: 22),
            const SizedBox(width: 8),
            Text(
              'Field Analytics',
              style: GoogleFonts.outfit(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
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

            // Tab Bar Controls (5 Tabs)
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

            // Tab Content Views
            if (_selectedTab == 0) ...[
              // Tab 0: Weather Stats & 7-Day Forecast
              _buildWeatherForecastTab(weatherForecast, isDark, cardBg, borderColor, textColor, subtextColor, primaryColor),
            ] else if (_selectedTab == 1) ...[
              // Tab 1: Daily Trend Visual Chart
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: dailyBreakdown.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text('No daily trend data available.', style: GoogleFonts.inter(color: subtextColor)),
                        ),
                      )
                    : Column(
                        children: [
                          SizedBox(
                            height: 170,
                            width: double.infinity,
                            child: CustomPaint(
                              painter: WaterUsageChartPainter(
                                dailyBreakdown: dailyBreakdown,
                                isDark: isDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: dailyBreakdown.map((m) {
                              final dateStr = (m['date'] as String? ?? '').split('-').skip(1).join('/');
                              return Text(
                                dateStr,
                                style: GoogleFonts.inter(fontSize: 10, color: subtextColor, fontWeight: FontWeight.w600),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildLegendItem(const Color(0xFF0284C7), 'Applied Water', subtextColor),
                              _buildLegendItem(const Color(0xFF38BDF8), 'Rainfall', subtextColor),
                              _buildLegendItem(const Color(0xFFF59E0B), 'Crop Demand (ETc)', subtextColor),
                            ],
                          ),
                        ],
                      ),
              ),
            ] else if (_selectedTab == 2) ...[
              // Tab 2: Smart Agronomic Insights
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isOptimal
                                ? const Color(0xFF10B981)
                                : isDeficit
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF38BDF8))
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (isOptimal
                                  ? const Color(0xFF10B981)
                                  : isDeficit
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF38BDF8))
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isOptimal
                                ? LucideIcons.checkCircle2
                                : isDeficit
                                    ? LucideIcons.alertTriangle
                                    : LucideIcons.droplets,
                            color: isOptimal
                                ? const Color(0xFF10B981)
                                : isDeficit
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF38BDF8),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isOptimal
                                      ? 'Optimal Hydration (${satisfactionRatio.toStringAsFixed(0)}%)'
                                      : isDeficit
                                          ? 'Water Deficit Alert (${satisfactionRatio.toStringAsFixed(0)}%)'
                                          : 'High Storage Level (${satisfactionRatio.toStringAsFixed(0)}%)',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isOptimal
                                        ? const Color(0xFF10B981)
                                        : isDeficit
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFF38BDF8),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isOptimal
                                      ? 'Your field receives ideal moisture matching crop ETc loss. Root zone is healthy.'
                                      : isDeficit
                                          ? 'Field supply is below crop ETc requirement. Run your pump soon to prevent yield loss.'
                                          : 'Supply exceeds crop demand. Reduce pump runtime to prevent nutrient leaching.',
                                  style: GoogleFonts.inter(fontSize: 12, color: subtextColor, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.piggyBank, color: Color(0xFF10B981), size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Precision Savings Counter', style: GoogleFonts.inter(fontSize: 11, color: subtextColor)),
                                const SizedBox(height: 2),
                                Text(
                                  'Saved ~${savedKL.toStringAsFixed(1)} kL water (≈ ₹${savedMoneyRupees.toStringAsFixed(0)} fuel/energy)',
                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_selectedTab == 3) ...[
              // Tab 3: Cumulative Water Balance Breakdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildBalanceMetric('💧 Irrigation Applied', '${totalAppliedMm.toStringAsFixed(1)} mm', '${totalAppliedKL.toStringAsFixed(1)} kL', const Color(0xFF0284C7), subtextColor),
                        _buildBalanceMetric('🌧️ Rainfall Received', '${totalRainMm.toStringAsFixed(1)} mm', '${totalRainKL.toStringAsFixed(1)} kL', const Color(0xFF0284C7), subtextColor),
                        _buildBalanceMetric('🌾 Crop Demand (ETc)', '${totalEtcMm.toStringAsFixed(1)} mm', '${totalEtcKL.toStringAsFixed(1)} kL', const Color(0xFFF59E0B), subtextColor),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Water Satisfaction Index', style: GoogleFonts.inter(fontSize: 11, color: subtextColor)),
                            Text(
                              totalEtcMm > 0
                                  ? '${((totalSupplyMm / totalEtcMm) * 100).clamp(0, 150).toStringAsFixed(0)}%'
                                  : '100%',
                              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: primaryColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: totalEtcMm > 0 ? (totalSupplyMm / totalEtcMm).clamp(0.0, 1.0) : 1.0,
                            minHeight: 8,
                            backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Tab 4: History Logs Feed
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: _isLoadingHistory
                    ? const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator(strokeWidth: 2)))
                    : _historyLogs.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text('No logged pump sessions found.', style: GoogleFonts.inter(color: subtextColor)),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _historyLogs.length > 8 ? 8 : _historyLogs.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (ctx, idx) {
                              final log = _historyLogs[idx];
                              final appliedMm = (log['applied_mm'] as num?)?.toDouble() ?? 0.0;
                              final appliedDate = log['applied_date'] ?? '';
                              final notes = log['notes'] ?? 'Pump irrigation';

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(LucideIcons.zap, color: Color(0xFF38BDF8), size: 16),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            notes,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            appliedDate,
                                            style: GoogleFonts.inter(fontSize: 11, color: subtextColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '+${appliedMm.toStringAsFixed(1)} mm',
                                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherForecastTab(
    List<dynamic> forecast,
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
    Color primaryColor,
  ) {
    if (forecast.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Text('7-Day Weather forecast data unavailable.', style: GoogleFonts.inter(color: subtextColor)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Text('🌦️ 6-Day Predictive Weather & Irrigation Window', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: forecast.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (ctx, idx) {
            final day = forecast[idx];
            final dateStr = (day['date'] as String? ?? '').split('-').skip(1).join('/');
            final tempMax = (day['temp_max'] as num?)?.toDouble() ?? 30.0;
            final tempMin = (day['temp_min'] as num?)?.toDouble() ?? 22.0;
            final precipMm = (day['precip_mm'] as num?)?.toDouble() ?? 0.0;
            final et0 = (day['et0_mm'] as num?)?.toDouble() ?? 4.0;
            final isRainy = precipMm > 2.0;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isRainy ? const Color(0xFF38BDF8).withValues(alpha: 0.5) : borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        dateStr,
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    isRainy ? LucideIcons.cloudRain : LucideIcons.sun,
                    color: isRainy ? const Color(0xFF38BDF8) : const Color(0xFFF59E0B),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${tempMax.toStringAsFixed(0)}° / ${tempMin.toStringAsFixed(0)}° C',
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        Text(
                          'Evapotranspiration (ET0): ${et0.toStringAsFixed(1)} mm/day',
                          style: GoogleFonts.inter(fontSize: 11, color: subtextColor),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${precipMm.toStringAsFixed(1)} mm Rain',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isRainy ? const Color(0xFF38BDF8) : subtextColor,
                        ),
                      ),
                      if (isRainy)
                        Text(
                          'Rain Expected',
                          style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF38BDF8), fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
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

  Widget _buildBalanceMetric(String label, String depth, String volume, Color color, Color subtextColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: subtextColor)),
          const SizedBox(height: 2),
          Text(depth, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          Text(volume, style: GoogleFonts.inter(fontSize: 10, color: subtextColor)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, Color subtextColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: subtextColor)),
      ],
    );
  }
}

class WaterUsageChartPainter extends CustomPainter {
  final List<dynamic> dailyBreakdown;
  final bool isDark;

  WaterUsageChartPainter({
    required this.dailyBreakdown,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dailyBreakdown.isEmpty) return;

    double maxVal = 10.0;
    for (var m in dailyBreakdown) {
      final applied = (m['irrigation_applied_mm'] as num?)?.toDouble() ?? 0.0;
      final rain = (m['rainfall_mm'] as num?)?.toDouble() ?? 0.0;
      final etc = (m['etc_mm'] as num?)?.toDouble() ?? 0.0;
      if (applied + rain > maxVal) maxVal = applied + rain;
      if (etc > maxVal) maxVal = etc;
    }
    maxVal *= 1.2;

    final gridPaint = Paint()
      ..color = (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)).withValues(alpha: 0.5)
      ..strokeWidth = 1;

    for (int i = 0; i <= 3; i++) {
      final y = size.height - (size.height / 3) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final barWidth = (size.width / dailyBreakdown.length) * 0.4;
    final groupWidth = size.width / dailyBreakdown.length;

    final appliedPaint = Paint()..color = const Color(0xFF0284C7);
    final rainPaint = Paint()..color = const Color(0xFF38BDF8);
    final etcLinePaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final etcPoints = <Offset>[];

    for (int i = 0; i < dailyBreakdown.length; i++) {
      final item = dailyBreakdown[i];
      final applied = (item['irrigation_applied_mm'] as num?)?.toDouble() ?? 0.0;
      final rain = (item['rainfall_mm'] as num?)?.toDouble() ?? 0.0;
      final etc = (item['etc_mm'] as num?)?.toDouble() ?? 0.0;

      final groupX = i * groupWidth + (groupWidth / 2);
      final appliedH = (applied / maxVal) * size.height;
      final rainH = (rain / maxVal) * size.height;

      final appliedRect = Rect.fromLTWH(
        groupX - barWidth,
        size.height - appliedH,
        barWidth * 0.9,
        appliedH,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(appliedRect, const Radius.circular(4)), appliedPaint);

      final rainRect = Rect.fromLTWH(
        groupX,
        size.height - rainH,
        barWidth * 0.9,
        rainH,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(rainRect, const Radius.circular(4)), rainPaint);

      final etcY = size.height - (etc / maxVal) * size.height;
      etcPoints.add(Offset(groupX, etcY));
    }

    if (etcPoints.length > 1) {
      final path = Path();
      path.moveTo(etcPoints[0].dx, etcPoints[0].dy);
      for (int i = 1; i < etcPoints.length; i++) {
        path.lineTo(etcPoints[i].dx, etcPoints[i].dy);
      }
      canvas.drawPath(path, etcLinePaint);

      final dotPaint = Paint()..color = const Color(0xFFF59E0B);
      for (var pt in etcPoints) {
        canvas.drawCircle(pt, 4, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant WaterUsageChartPainter oldDelegate) {
    return oldDelegate.dailyBreakdown != dailyBreakdown || oldDelegate.isDark != isDark;
  }
}
