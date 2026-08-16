import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/constants/api_constants.dart';
import '../core/services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/farm_plot_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/app_drawer.dart';
import 'add_edit_farm_plot_screen.dart';

class PestAdvisoryScreen extends StatefulWidget {
  const PestAdvisoryScreen({super.key});

  @override
  State<PestAdvisoryScreen> createState() => _PestAdvisoryScreenState();
}

class _PestAdvisoryScreenState extends State<PestAdvisoryScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _advisoryData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPestAdvisory();
    });
  }

  Future<void> _fetchPestAdvisory() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final farmPlotProvider = Provider.of<FarmPlotProvider>(context, listen: false);
    final plot = farmPlotProvider.selectedPlot;

    if (plot == null) {
      setState(() {
        _isLoading = false;
        _advisoryData = null;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final cropId = plot.cropId;
    final lat = plot.latitude;
    final lon = plot.longitude;

    try {
      final data = await ApiService.fetchPestAdvisory(
        payload: {
          'crop_id': cropId,
          'latitude': lat,
          'longitude': lon,
        },
        token: auth.token,
      );

      setState(() {
        _advisoryData = data;
        _isLoading = false;
      });

      // Trigger native device push notification for Critical or High weather disease alerts
      if (mounted) {
        final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
        final list = data['advisories'] as List? ?? [];
        for (var item in list) {
          final risk = item['risk_level']?.toString().toUpperCase();
          if (risk == 'CRITICAL' || risk == 'HIGH') {
            notifProvider.addNotification(
              title: '⚠️ ${item['disease_name'] ?? 'Pest Warning'} (${item['risk_level']})',
              body: '${item['category']} alert for ${plot.name}. ${item['chemical_treatment'] ?? ''}',
              type: 'weather',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e is ApiException ? e.message : 'Cannot connect to JalDrishti server.';
          _isLoading = false;
        });
      }
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return const Color(0xFFEF4444);
      case 'HIGH':
        return const Color(0xFFF59E0B);
      case 'MEDIUM':
        return const Color(0xFF38BDF8);
      default:
        return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final farmPlotProvider = Provider.of<FarmPlotProvider>(context);
    final activePlot = farmPlotProvider.selectedPlot;

    return Scaffold(
      backgroundColor: scaffoldBg,
      drawer: const AppDrawer(activeRoute: 'pest_advisory'),
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        title: Text(
          'Weather Pest & Disease Warning',
          style: GoogleFonts.outfit(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bellRing, size: 20, color: Color(0xFFEF4444)),
            onPressed: () {
              final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
              notifProvider.addNotification(
                title: '⚠️ CRITICAL: Weather Disease Warning (Rice Blast)',
                body: 'High humidity (89%) & temp (31°C) in Paddy Plot. Apply Tricyclazole 75 WP @ 0.6g/L immediately.',
                type: 'weather',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔔 Test push notification sent to status bar & lock screen!'),
                  backgroundColor: Color(0xFF0284C7),
                ),
              );
            },
            tooltip: 'Send Test Warning Push Notification',
          ),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20, color: Color(0xFF38BDF8)),
            onPressed: _fetchPestAdvisory,
            tooltip: 'Refresh Weather Risks',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
          : activePlot == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.sprout, color: Color(0xFF38BDF8), size: 48),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Farm Plot Added Yet',
                          style: GoogleFonts.outfit(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your farm plot and crop in JalDrishti to get personalized micro-climate disease and pest warning alerts for your field.',
                          style: GoogleFonts.inter(color: subtextColor, fontSize: 13, height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddEditFarmPlotScreen()),
                            );
                          },
                          icon: const Icon(LucideIcons.plusCircle, size: 18),
                          label: Text('Add Farm Plot', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.alertTriangle, color: Colors.orangeAccent, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              style: GoogleFonts.inter(color: subtextColor, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _fetchPestAdvisory,
                              icon: const Icon(LucideIcons.refreshCw, size: 16),
                              label: const Text('Try Again'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                  onRefresh: _fetchPestAdvisory,
                  color: const Color(0xFF38BDF8),
                  backgroundColor: const Color(0xFF1E293B),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Micro-Climate Weather Header Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0284C7), Color(0xFF0F172A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(LucideIcons.bug, color: Color(0xFF38BDF8), size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Active Crop: ${activePlot.cropId.replaceAll('_', ' ').toUpperCase()}',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.redAccent),
                                    ),
                                    child: Text(
                                      '${_advisoryData?['total_active_warnings'] ?? 0} Warnings',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Divider(color: Colors.white24, height: 1),
                              const SizedBox(height: 12),

                              // Microclimate metrics
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildWeatherPill(
                                    LucideIcons.droplets,
                                    '${_advisoryData?['weather_snapshot']?['humidity_percent'] ?? 85}%',
                                    'Humidity',
                                  ),
                                  _buildWeatherPill(
                                    LucideIcons.thermometer,
                                    '${_advisoryData?['weather_snapshot']?['max_temp_c'] ?? 30}°C',
                                    'Max Temp',
                                  ),
                                  _buildWeatherPill(
                                    LucideIcons.cloudRain,
                                    '${_advisoryData?['weather_snapshot']?['precipitation_mm'] ?? 0} mm',
                                    'Rain',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          'PREVENTIVE DISEASE & PEST WARNINGS',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // List of Advisories
                        if ((_advisoryData?['advisories'] as List?).isNullOrEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.checkCircle2, color: Color(0xFF10B981), size: 28),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'No High Disease Warnings Today',
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      Text(
                                        'Current humidity and temperature parameters are safe from major fungal and pest outbreaks.',
                                        style: GoogleFonts.inter(fontSize: 12, color: subtextColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: (_advisoryData?['advisories'] as List).length,
                            itemBuilder: (context, index) {
                              final item = _advisoryData!['advisories'][index];
                              final severityColor = _getSeverityColor(item['risk_level'] ?? 'HIGH');

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: severityColor.withValues(alpha: 0.5), width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: severityColor.withValues(alpha: 0.1),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: severityColor.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(LucideIcons.alertOctagon, color: severityColor, size: 20),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item['disease_name'] ?? 'Disease Alert',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: textColor,
                                                  ),
                                                ),
                                                Text(
                                                  '${item['category']} • Trigger: ${item['trigger_weather']}',
                                                  style: GoogleFonts.inter(fontSize: 11, color: subtextColor),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: severityColor,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              item['risk_level'],
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),

                                      // Symptoms
                                      Text(
                                        '👀 FIELD SYMPTOMS TO INSPECT:',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: subtextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['symptoms'] ?? 'Check leaves for brown spots or wilting.',
                                        style: GoogleFonts.inter(fontSize: 12.5, color: textColor, height: 1.35),
                                      ),
                                      const SizedBox(height: 12),

                                      // Chemical Spray Treatment
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(LucideIcons.flaskConical, color: Color(0xFF38BDF8), size: 16),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Chemical Spray Recommendation:',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF38BDF8),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item['chemical_treatment'] ?? 'Apply recommended fungicide.',
                                              style: GoogleFonts.inter(fontSize: 12, color: textColor),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),

                                      // Organic Treatment
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(LucideIcons.leaf, color: Color(0xFF10B981), size: 16),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Organic / Bio-Pesticide Solution:',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF10B981),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item['organic_treatment'] ?? 'Apply Neem oil spray.',
                                              style: GoogleFonts.inter(fontSize: 12, color: textColor),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildWeatherPill(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF38BDF8), size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}

extension NullOrEmptyExtension on List? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
}
