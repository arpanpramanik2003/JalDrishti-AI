import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/irrigation_provider.dart';
import '../gauge_widget.dart';

class WaterBucketGaugeCard extends StatelessWidget {
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final Color subtextColor;
  final Color primaryColor;
  final VoidCallback onHelpTap;

  const WaterBucketGaugeCard({
    super.key,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.subtextColor,
    required this.primaryColor,
    required this.onHelpTap,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<IrrigationProvider, Map<String, dynamic>?>(
      selector: (_, provider) => provider.irrigationData,
      builder: (context, data, _) {
        final currentWaterMm = (data?['current_water_mm'] as num?)?.toDouble() ?? 45.0;
        final maxCapacityMm = (data?['max_capacity_mm'] as num?)?.toDouble() ?? 100.0;
        final daysUntilStress = data?['days_until_stress'] ?? 2;
        final statusMessage = data?['status_message'] ?? 'Optimal soil moisture levels detected.';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.droplets, size: 20, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 8),
                      Text(
                        'Root-Zone Soil Moisture',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.helpCircle, size: 18, color: subtextColor),
                    onPressed: onHelpTap,
                    tooltip: 'Scientific Terms Explanation',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: IrrigationStatusGauge(
                      needsIrrigation: daysUntilStress <= 1,
                      recommendedWaterMm: currentWaterMm,
                      tawMm: maxCapacityMm,
                      statusSummary: statusMessage,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: borderColor, height: 1),
              const SizedBox(height: 10),
              Text(
                statusMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: subtextColor, height: 1.3),
              ),
            ],
          ),
        );
      },
    );
  }
}
