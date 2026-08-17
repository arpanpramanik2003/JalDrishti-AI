import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SmartInsightsTab extends StatelessWidget {
  final Map<String, dynamic>? irrigationData;
  final double satisfactionRatio;
  final bool isOptimal;
  final bool isDeficit;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final Color subtextColor;
  final Color primaryColor;

  const SmartInsightsTab({
    super.key,
    required this.irrigationData,
    required this.satisfactionRatio,
    required this.isOptimal,
    required this.isDeficit,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.subtextColor,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final growthStage = irrigationData?['current_growth_stage'] ?? 'Mid-Season (Vegetative)';
    final cropName = irrigationData?['crop_name'] ?? 'Paddy';
    final rainHoldActive = (irrigationData?['rain_hold_active'] as bool?) ?? false;
    final rainHoldMsg = irrigationData?['rain_hold_message'] as String?;

    final cumSavingsRaw = irrigationData?['cumulative_savings'];
    final cumSavings = cumSavingsRaw is Map ? Map<String, dynamic>.from(cumSavingsRaw) : null;
    final cumWaterLiters = (cumSavings?['total_water_saved_liters'] as num?)?.toDouble() ?? 45000.0;
    final cumWaterKL = cumWaterLiters / 1000.0;
    final cumMoneyINR = (cumSavings?['total_money_saved_inr'] as num?)?.toDouble() ?? 850.0;
    final cumCo2Kg = (cumSavings?['total_co2_reduced_kg'] as num?)?.toDouble() ?? 29.8;

    final cardStatusColor = isOptimal
        ? const Color(0xFF10B981)
        : isDeficit
            ? const Color(0xFFF59E0B)
            : const Color(0xFF38BDF8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '💡 Agronomic Insights & Precision Telemetry',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 10),

        // Rain Hold Alert Card if Active
        if (rainHoldActive && rainHoldMsg != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0284C7), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.6), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.cloudRain, color: Color(0xFF38BDF8), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🌧️ SMART RAIN HOLD ACTIVE',
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rainHoldMsg,
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFE2E8F0), height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Hydration Status Card
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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardStatusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardStatusColor.withValues(alpha: 0.4)),
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
                      color: cardStatusColor,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isOptimal
                                ? 'Optimal Hydration Status (${satisfactionRatio.toStringAsFixed(0)}%)'
                                : isDeficit
                                    ? 'Water Deficit Alert (${satisfactionRatio.toStringAsFixed(0)}%)'
                                    : 'High Water Storage Level (${satisfactionRatio.toStringAsFixed(0)}%)',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: cardStatusColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isOptimal
                                ? 'Your field receives ideal moisture matching crop ETc loss. Root zone moisture is within safe RAW bounds.'
                                : isDeficit
                                    ? 'Field moisture is below crop requirement. Run your pump soon to prevent yield loss.'
                                    : 'Supply exceeds crop demand. Reduce pump runtime to prevent nutrient leaching and waterlogging.',
                            style: GoogleFonts.inter(fontSize: 12, color: subtextColor, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Cumulative Seasonal Savings Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.piggyBank, color: Color(0xFF10B981), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cumulative Seasonal Precision ROI',
                            style: GoogleFonts.inter(fontSize: 11, color: subtextColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Saved ~${cumWaterKL.toStringAsFixed(1)} kL water (≈ ₹${cumMoneyINR.toStringAsFixed(0)} saved)',
                            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                          ),
                          Text(
                            '🌱 Reduced ${cumCo2Kg.toStringAsFixed(1)} kg CO₂ carbon footprint',
                            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF10B981), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Crop Growth Stage Advice Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.sprout, color: primaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Crop Growth Stage Advisory: $cropName',
                            style: GoogleFonts.inter(fontSize: 11, color: subtextColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            growthStage,
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                          ),
                          Text(
                            'Keep soil moisture near field capacity to maximize kernel/tillering yield.',
                            style: GoogleFonts.inter(fontSize: 11, color: subtextColor, height: 1.2),
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
      ],
    );
  }
}
