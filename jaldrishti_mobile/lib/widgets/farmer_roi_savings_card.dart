import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FarmerRoiSavingsCard extends StatelessWidget {
  final double totalWaterSavedLiters;
  final double totalPumpHoursSaved;
  final double totalMoneySavedInr;
  final double totalCo2ReducedKg;
  final int skippedRunsCount;

  const FarmerRoiSavingsCard({
    super.key,
    this.totalWaterSavedLiters = 0.0,
    this.totalPumpHoursSaved = 0.0,
    this.totalMoneySavedInr = 0.0,
    this.totalCo2ReducedKg = 0.0,
    this.skippedRunsCount = 0,
  });

  String _formatLiters(double liters) {
    if (liters >= 1000000) {
      return '${(liters / 1000000).toStringAsFixed(1)} M Liters';
    } else if (liters >= 1000) {
      return '${(liters / 1000).toStringAsFixed(1)} k Liters';
    }
    return '${liters.toInt()} Liters';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
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
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10B981),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cumulative Resource & Financial Savings',
                      style: GoogleFonts.inter(fontSize: 11, color: subtextColor),
                    ),
                    if (skippedRunsCount > 0) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$skippedRunsCount Rain-Hold Runs Saved',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF38BDF8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2x2 Savings Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: LucideIcons.indianRupee,
                  iconColor: const Color(0xFF10B981),
                  title: 'Money Saved',
                  value: '₹ ${totalMoneySavedInr.toInt()}',
                  textColor: textColor,
                  subtextColor: subtextColor,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  icon: LucideIcons.droplet,
                  iconColor: const Color(0xFF38BDF8),
                  title: 'Water Saved',
                  value: _formatLiters(totalWaterSavedLiters),
                  textColor: textColor,
                  subtextColor: subtextColor,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: LucideIcons.clock,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Pump Hours Saved',
                  value: '${totalPumpHoursSaved.toStringAsFixed(1)} hrs',
                  textColor: textColor,
                  subtextColor: subtextColor,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  icon: LucideIcons.leaf,
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'CO₂ Reduced',
                  value: '${totalCo2ReducedKg.toStringAsFixed(1)} kg',
                  textColor: textColor,
                  subtextColor: subtextColor,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color textColor,
    required Color subtextColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 11, color: subtextColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
