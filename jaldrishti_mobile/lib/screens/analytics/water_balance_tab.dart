import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WaterBalanceTab extends StatelessWidget {
  final double totalAppliedMm;
  final double totalRainMm;
  final double totalEtcMm;
  final double totalAppliedKL;
  final double totalRainKL;
  final double totalEtcKL;
  final double satisfactionRatio;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final Color subtextColor;
  final Color primaryColor;

  const WaterBalanceTab({
    super.key,
    required this.totalAppliedMm,
    required this.totalRainMm,
    required this.totalEtcMm,
    required this.totalAppliedKL,
    required this.totalRainKL,
    required this.totalEtcKL,
    required this.satisfactionRatio,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.subtextColor,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final progressValue = totalEtcMm > 0 ? (totalAppliedMm + totalRainMm) / totalEtcMm : 1.0;
    final displayRatio = satisfactionRatio.clamp(0.0, 300.0);

    final statusColor = displayRatio >= 85 && displayRatio <= 115
        ? const Color(0xFF10B981)
        : displayRatio < 85
            ? const Color(0xFFF59E0B)
            : const Color(0xFF0284C7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🌊 Volumetric Water Balance & Satisfaction Index',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 10),

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
              // 3 Metric Columns: Applied, Rain, Crop Demand
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBalanceMetric(
                    '💧 Irrigation Applied',
                    '${totalAppliedMm.toStringAsFixed(1)} mm',
                    '${totalAppliedKL.toStringAsFixed(1)} kL',
                    const Color(0xFF0284C7),
                    subtextColor,
                    textColor,
                  ),
                  _buildBalanceMetric(
                    '🌧️ Rainfall Received',
                    '${totalRainMm.toStringAsFixed(1)} mm',
                    '${totalRainKL.toStringAsFixed(1)} kL',
                    const Color(0xFF38BDF8),
                    subtextColor,
                    textColor,
                  ),
                  _buildBalanceMetric(
                    '🌾 Crop Demand (ETc)',
                    '${totalEtcMm.toStringAsFixed(1)} mm',
                    '${totalEtcKL.toStringAsFixed(1)} kL',
                    const Color(0xFFF59E0B),
                    subtextColor,
                    textColor,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Progress Bar Section
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Water Satisfaction Index (WSI)',
                              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                            ),
                            const SizedBox(width: 6),
                            Tooltip(
                              message: 'Ratio of total water supplied (applied + rain) versus crop ETc demand',
                              child: Icon(Icons.info_outline, size: 14, color: subtextColor),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${displayRatio.toStringAsFixed(0)}%',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progressValue.clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('0% (Deficit)', style: GoogleFonts.inter(fontSize: 10, color: subtextColor)),
                        Text('100% (Optimal)', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF10B981), fontWeight: FontWeight.bold)),
                        Text('>115% (Surplus)', style: GoogleFonts.inter(fontSize: 10, color: subtextColor)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceMetric(
    String label,
    String depth,
    String volume,
    Color color,
    Color subtextColor,
    Color textColor,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: subtextColor)),
          const SizedBox(height: 4),
          Text(depth, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          Text(volume, style: GoogleFonts.inter(fontSize: 11, color: subtextColor)),
        ],
      ),
    );
  }
}
