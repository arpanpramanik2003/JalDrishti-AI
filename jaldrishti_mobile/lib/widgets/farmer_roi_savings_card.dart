import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FarmerRoiSavingsCard extends StatelessWidget {
  final double totalWaterSavedLiters;
  final double totalPumpHoursSaved;
  final double totalMoneySavedInr;
  final double totalCo2ReducedKg;
  final int skippedRunsCount;
  final String? attributionNotice;
  final String? stateCode;
  final String? stateName;
  final double? tariffRateInrHr;
  final double? co2FactorKgHr;

  const FarmerRoiSavingsCard({
    super.key,
    this.totalWaterSavedLiters = 0.0,
    this.totalPumpHoursSaved = 0.0,
    this.totalMoneySavedInr = 0.0,
    this.totalCo2ReducedKg = 0.0,
    this.skippedRunsCount = 0,
    this.attributionNotice,
    this.stateCode,
    this.stateName,
    this.tariffRateInrHr,
    this.co2FactorKgHr,
  });

  // Compact number formatters to prevent overflow for large values
  static String formatCurrency(double val) {
    if (val >= 100000) {
      return '₹ ${(val / 100000).toStringAsFixed(1)} L';
    } else if (val >= 1000) {
      return '₹ ${(val / 1000).toStringAsFixed(1)} k';
    }
    return '₹ ${val.toInt()}';
  }

  static String formatWater(double liters) {
    if (liters >= 1000000) {
      return '${(liters / 1000000).toStringAsFixed(1)} M L';
    } else if (liters >= 1000) {
      return '${(liters / 1000).toStringAsFixed(1)} k L';
    }
    return '${liters.toInt()} L';
  }

  static String formatHours(double hrs) {
    if (hrs >= 1000) {
      return '${(hrs / 1000).toStringAsFixed(1)}k h';
    }
    return '${hrs.toStringAsFixed(1)} h';
  }

  static String formatCo2(double kg) {
    if (kg >= 1000) {
      return '${(kg / 1000).toStringAsFixed(1)} t';
    }
    return '${kg.toStringAsFixed(1)} kg';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.trendingUp, color: Color(0xFF10B981), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FARMER IMPACT & ROI TRACKER',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10B981),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap any tile below for detailed insights',
                      style: GoogleFonts.inter(fontSize: 11, color: subtextColor),
                    ),
                  ],
                ),
              ),
              if (stateCode != null || stateName != null)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${stateCode ?? "IND"} Rates',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ),
              if (skippedRunsCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '$skippedRunsCount Runs Saved',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF38BDF8),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 2x2 Metric Grid
          Row(
            children: [
              Expanded(
                child: _buildInteractiveTile(
                  context: context,
                  icon: LucideIcons.indianRupee,
                  accentColor: const Color(0xFF10B981),
                  title: 'Money Saved',
                  formattedValue: formatCurrency(totalMoneySavedInr),
                  rawValueString: '₹ ${totalMoneySavedInr.toInt()}',
                  subtitle: '${stateName ?? "State"} Pumping Tariff',
                  description:
                      'Calculated using ${stateName ?? "state"} agricultural energy benchmark (~₹${tariffRateInrHr?.toInt() ?? 80}/hr) saved by preventing over-irrigation.\n\nSource: ${attributionNotice ?? "Calculated using state agricultural tariff benchmarks & CEA India Grid emission factor."}',
                  tip: 'Preventing unnecessary pumping reduces motor wear and saves substantial energy bills over the crop season.',
                  isDark: isDark,
                  textColor: textColor,
                  subtextColor: subtextColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInteractiveTile(
                  context: context,
                  icon: LucideIcons.droplet,
                  accentColor: const Color(0xFF0284C7),
                  title: 'Water Saved',
                  formattedValue: formatWater(totalWaterSavedLiters),
                  rawValueString: '${totalWaterSavedLiters.toInt()} Liters',
                  subtitle: 'Field Moisture Balance',
                  description:
                      'Measures volumetric water conserved compared to un-optimized traditional flood irrigation methods.',
                  tip: 'Conserving groundwater preserves regional water table depth and prevents soil nutrient leaching.',
                  isDark: isDark,
                  textColor: textColor,
                  subtextColor: subtextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildInteractiveTile(
                  context: context,
                  icon: LucideIcons.clock,
                  accentColor: const Color(0xFFF59E0B),
                  title: 'Pump Time Saved',
                  formattedValue: formatHours(totalPumpHoursSaved),
                  rawValueString: '${totalPumpHoursSaved.toStringAsFixed(1)} Hours',
                  subtitle: 'Motor Runtime',
                  description:
                      'Calculated using your pump flow rate and required net water depth for current crop evapotranspiration.',
                  tip: 'Shorter pump runtime extends motor lifecycle and frees up farmer time for other agricultural tasks.',
                  isDark: isDark,
                  textColor: textColor,
                  subtextColor: subtextColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInteractiveTile(
                  context: context,
                  icon: LucideIcons.leaf,
                  accentColor: const Color(0xFF8B5CF6),
                  title: 'CO₂ Reduced',
                  formattedValue: formatCo2(totalCo2ReducedKg),
                  rawValueString: '${totalCo2ReducedKg.toStringAsFixed(1)} kg CO₂',
                  subtitle: '${stateCode ?? "Regional"} Grid Factor',
                  description:
                      'Estimated carbon emissions prevented using ${stateName ?? "state"} grid/fuel factor (${co2FactorKgHr?.toStringAsFixed(2) ?? "2.68"} kg CO₂/hr).\n\nSource: ${attributionNotice ?? "CEA India Grid emission factor & diesel emission benchmarks."}',
                  tip: 'Reducing agricultural carbon footprint supports sustainable green farming certification.',
                  isDark: isDark,
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

  Widget _buildInteractiveTile({
    required BuildContext context,
    required IconData icon,
    required Color accentColor,
    required String title,
    required String formattedValue,
    required String rawValueString,
    required String subtitle,
    required String description,
    required String tip,
    required bool isDark,
    required Color textColor,
    required Color subtextColor,
  }) {
    final tileBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final tileBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return InkWell(
      onTap: () => _showMetricDetailsModal(
        context: context,
        icon: icon,
        accentColor: accentColor,
        title: title,
        formattedValue: formattedValue,
        rawValueString: rawValueString,
        subtitle: subtitle,
        description: description,
        tip: tip,
        isDark: isDark,
      ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: tileBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tileBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: accentColor, size: 16),
                ),
                Icon(LucideIcons.info, size: 13, color: subtextColor.withValues(alpha: 0.6)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: subtextColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 22,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formattedValue,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMetricDetailsModal({
    required BuildContext context,
    required IconData icon,
    required Color accentColor,
    required String title,
    required String formattedValue,
    required String rawValueString,
    required String subtitle,
    required String description,
    required String tip,
    required bool isDark,
  }) {
    final sheetBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: sheetBg,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: accentColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(LucideIcons.x, color: subtextColor),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL SAVINGS CUMULATIVE',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rawValueString,
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'How it is calculated:',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: subtextColor,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.lightbulb, color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tip,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: textColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Got It',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  },
);
  }
}
