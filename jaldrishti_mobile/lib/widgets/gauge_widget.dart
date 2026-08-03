import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class IrrigationStatusGauge extends StatelessWidget {
  final bool needsIrrigation;
  final double recommendedWaterMm;
  final double tawMm;
  final String statusSummary;

  const IrrigationStatusGauge({
    super.key,
    required this.needsIrrigation,
    required this.recommendedWaterMm,
    required this.tawMm,
    required this.statusSummary,
  });

  void _showExplainDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(LucideIcons.droplets, color: primaryColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Understanding Water Metrics',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🌱 Soil Storage Capacity (TAW):',
              style: GoogleFonts.outfit(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'The maximum depth of available water your soil layer holds for crop roots.',
              style: GoogleFonts.inter(color: subtextColor, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Text(
              '💧 Recommended Water Depth:',
              style: GoogleFonts.outfit(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'The exact depth of irrigation required to replenish root zone moisture.',
              style: GoogleFonts.inter(color: subtextColor, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Got It', style: GoogleFonts.outfit(color: primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final themeColor = needsIrrigation
        ? (isDark ? Colors.orangeAccent : const Color(0xFFD97706))
        : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7));

    final cardBg = needsIrrigation
        ? (isDark ? const Color(0xFF451A03) : const Color(0xFFFFF7ED))
        : (isDark ? const Color(0xFF1E293B) : Colors.white);

    final borderColor = needsIrrigation
        ? (isDark ? Colors.orangeAccent.withValues(alpha: 0.5) : const Color(0xFFFDE68A))
        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Line 1: Title & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    needsIrrigation ? LucideIcons.alertTriangle : LucideIcons.droplets,
                    color: themeColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Soil Moisture Status',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: themeColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  needsIrrigation ? 'WATER DEFICIT' : 'OPTIMAL',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Header Line 2: Soil Capacity Tag (Separate row to prevent overlap)
          InkWell(
            onTap: () => _showExplainDialog(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: themeColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.layers, size: 13, color: themeColor),
                  const SizedBox(width: 6),
                  Text(
                    'Soil Capacity (TAW): ${tawMm.toStringAsFixed(1)} mm',
                    style: GoogleFonts.inter(
                      color: themeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(LucideIcons.info, size: 12, color: themeColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Gauge Icon & Main Action Display
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: themeColor.withValues(alpha: 0.12),
                  child: Icon(
                    needsIrrigation ? LucideIcons.cloudRain : LucideIcons.sprout,
                    size: 44,
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  needsIrrigation
                      ? 'Apply ${recommendedWaterMm.toStringAsFixed(1)} mm Water'
                      : 'No Irrigation Needed Today',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  statusSummary,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: subtextColor,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}