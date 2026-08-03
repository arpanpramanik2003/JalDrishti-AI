import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/farm_plot_model.dart';

class DashboardPumpCard extends StatelessWidget {
  final Map<String, dynamic>? data;
  final FarmPlotModel? selectedPlot;
  final double todayLoggedMm;
  final VoidCallback onLogIrrigationPressed;

  const DashboardPumpCard({
    super.key,
    this.data,
    this.selectedPlot,
    this.todayLoggedMm = 0.0,
    required this.onLogIrrigationPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final primaryColor = const Color(0xFF38BDF8);

    final needsIrrigation = data?['needs_irrigation_today'] ?? false;
    final hours = (data?['recommended_pump_hours'] as num?)?.toInt() ?? 0;
    final minutes = (data?['recommended_pump_minutes'] as num?)?.toInt() ?? 0;
    final grossMm = (data?['recommended_gross_water_mm'] as num?)?.toDouble() ?? 0.0;
    final methodDisplay = data?['irrigation_method_display'] ?? 'Surface / Flood';
    final effPct = (data?['irrigation_efficiency_pct'] as num?)?.toInt() ?? 50;

    final pumpHp = selectedPlot?.pumpHp ?? 5.0;
    final flowLps = selectedPlot?.pumpFlowLps ?? 5.0;

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
          // 1. Full-Width Unconstrained Section Title Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(LucideIcons.power, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PUMP OPERATION RUNTIME',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${pumpHp.toStringAsFixed(1)} HP Pump Rating • ${flowLps.toStringAsFixed(1)} L/sec Flow Rate',
                      style: GoogleFonts.inter(fontSize: 11, color: subtextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Main Pumping Duration Display Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: needsIrrigation ? primaryColor.withValues(alpha: 0.4) : borderColor,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      needsIrrigation ? LucideIcons.timer : LucideIcons.checkCircle2,
                      color: needsIrrigation ? primaryColor : const Color(0xFF10B981),
                      size: 30,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            needsIrrigation ? 'Recommended Pumping Duration' : 'Field Soil Moisture Optimal',
                            style: GoogleFonts.inter(fontSize: 11, color: subtextColor),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            needsIrrigation
                                ? (hours > 0 ? '$hours Hours $minutes Mins' : '$minutes Minutes')
                                : '0 Hours (No Pumping Needed)',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: borderColor),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Gross Water Needed',
                      style: GoogleFonts.inter(fontSize: 11, color: subtextColor),
                    ),
                    Text(
                      '${grossMm.toStringAsFixed(1)} mm depth',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Irrigation System',
                      style: GoogleFonts.inter(fontSize: 11, color: subtextColor),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '$methodDisplay ($effPct%)',
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. Logged Today Status Banner
          if (todayLoggedMm > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.checkCheck, size: 16, color: Color(0xFF10B981)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Logged Today: ${todayLoggedMm.toStringAsFixed(1)} mm applied to soil.',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF10B981)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // 4. Prominent Full-Width Log Pump Run Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onLogIrrigationPressed,
              icon: const Icon(LucideIcons.plusCircle, size: 18),
              label: Text(
                'LOG PUMP RUN & RECORD WATER',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
