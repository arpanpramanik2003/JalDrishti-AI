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
    final metricBg = isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    const accentColor = Color(0xFF10B981);

    final cropName = data?['crop_name'] ?? selectedPlot?.cropId.replaceAll('_', ' ').toUpperCase() ?? 'Paddy Rice';
    final stageName = data?['current_growth_stage'] ?? 'Mid-Season';
    final elapsedDays = (data?['elapsed_days'] as num?)?.toInt() ?? 45;
    final kc = (data?['dynamic_kc'] as num?)?.toDouble() ?? 1.15;
    final rootDepth = (data?['effective_root_depth_m'] as num?)?.toDouble() ?? 0.5;
    final soilType = data?['soil_type_display']?.toString() ?? 'Clay Loam (High Retention)';
    final soilIsFallback = data?['soil_is_fallback'] as bool? ?? false;

    // Clean up soil display text for metric badge
    final cleanSoilType = soilType.contains('(')
        ? soilType.split('(')[0].trim()
        : soilType.split(' ').take(2).join(' ').trim();

    return Container(
      padding: const EdgeInsets.all(16),
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
          // Header Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.sprout, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CROP LIFECYCLE & AGRONOMY',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$cropName • Day $elapsedDays Since Sowing',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: subtextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Fully flexible wrap container to prevent right overflows on any screen width
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Growth Stage Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.leaf, size: 10, color: accentColor),
                              const SizedBox(width: 4),
                              Text(
                                stageName.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Soil Telemetry Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: (soilIsFallback ? const Color(0xFFF59E0B) : const Color(0xFF10B981)).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: (soilIsFallback ? const Color(0xFFF59E0B) : const Color(0xFF10B981)).withValues(alpha: 0.35),
                            ),
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
          const SizedBox(height: 14),

          // Growth Stage Metrics Responsive Row
          Row(
            children: [
              Expanded(
                child: _buildLifecycleMetric(
                  icon: LucideIcons.lineChart,
                  label: 'Kc Factor',
                  value: kc.toStringAsFixed(2),
                  color: const Color(0xFF38BDF8),
                  bgColor: metricBg,
                  borderColor: borderColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildLifecycleMetric(
                  icon: LucideIcons.arrowDownCircle,
                  label: 'Root Depth',
                  value: '${rootDepth.toStringAsFixed(2)} m',
                  color: const Color(0xFFF59E0B),
                  bgColor: metricBg,
                  borderColor: borderColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildLifecycleMetric(
                  icon: LucideIcons.layers,
                  label: 'Soil Texture',
                  value: cleanSoilType,
                  color: const Color(0xFF8B5CF6),
                  bgColor: metricBg,
                  borderColor: borderColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                ),
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
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: subtextColor,
            ),
          ),
        ],
      ),
    );
  }
}
