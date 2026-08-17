import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/farm_plot_model.dart';

class DashboardCropLifecycleCard extends StatelessWidget {
  final Map<String, dynamic>? data;
  final FarmPlotModel? selectedPlot;

  const DashboardCropLifecycleCard({
    super.key,
    this.data,
    this.selectedPlot,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final accentColor = const Color(0xFF10B981);

    final cropName = data?['crop_name'] ?? selectedPlot?.cropId.replaceAll('_', ' ').toUpperCase() ?? 'Paddy Rice';
    final stageName = data?['current_growth_stage'] ?? 'Mid-Season';
    final elapsedDays = (data?['elapsed_days'] as num?)?.toInt() ?? 45;
    final kc = (data?['dynamic_kc'] as num?)?.toDouble() ?? 1.15;
    final rootDepth = (data?['effective_root_depth_m'] as num?)?.toDouble() ?? 0.5;
    final soilType = data?['soil_type_display'] ?? 'Clay Loam (High Retention)';
    final soilIsFallback = data?['soil_is_fallback'] as bool? ?? false;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(LucideIcons.sprout, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CROP LIFECYCLE & AGRONOMY',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$cropName • Day $elapsedDays Since Sowing',
                      style: GoogleFonts.inter(fontSize: 11, color: subtextColor),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            stageName.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (soilIsFallback ? const Color(0xFFF59E0B) : const Color(0xFF10B981)).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: (soilIsFallback ? const Color(0xFFF59E0B) : const Color(0xFF10B981)).withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                soilIsFallback ? LucideIcons.alertCircle : LucideIcons.checkCircle2,
                                size: 10,
                                color: soilIsFallback ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                soilIsFallback ? 'Regional Soil Estimate' : 'Precise Soil Telemetry',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: soilIsFallback ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Growth Stage Metrics Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLifecycleMetric(
                icon: LucideIcons.lineChart,
                label: 'Crop Coefficient (Kc)',
                value: kc.toStringAsFixed(2),
                color: const Color(0xFF38BDF8),
                textColor: textColor,
                subtextColor: subtextColor,
              ),
              _buildLifecycleMetric(
                icon: LucideIcons.arrowDownCircle,
                label: 'Root Depth (Zr)',
                value: '${rootDepth.toStringAsFixed(2)} m',
                color: const Color(0xFFF59E0B),
                textColor: textColor,
                subtextColor: subtextColor,
              ),
              _buildLifecycleMetric(
                icon: LucideIcons.layers,
                label: 'Soil Texture',
                value: soilType.split(' ')[0],
                color: const Color(0xFF8B5CF6),
                textColor: textColor,
                subtextColor: subtextColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLifecycleMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color textColor,
    required Color subtextColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: subtextColor),
        ),
      ],
    );
  }
}
