import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DashboardTimelineCard extends StatelessWidget {
  final List<dynamic>? dailyBreakdown;

  const DashboardTimelineCard({
    super.key,
    this.dailyBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    if (dailyBreakdown == null || dailyBreakdown!.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '6-DAY HYDROLOGICAL BALANCE TIMELINE',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: const Color(0xFF38BDF8),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Past 3D Historical + 3D Weather Forecast',
              style: GoogleFonts.inter(fontSize: 11, color: subtextColor),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: dailyBreakdown!.length,
          itemBuilder: (context, index) {
            final day = dailyBreakdown![index];
            final dateStr = day['date'] ?? '';
            final eto = (day['eto_mm'] as num?)?.toDouble() ?? 0.0;
            final etc = (day['etc_mm'] as num?)?.toDouble() ?? 0.0;
            final rain = (day['rainfall_mm'] as num?)?.toDouble() ?? 0.0;
            final status = day['status'] ?? 'OPTIMAL';
            final todayStr = DateTime.now().toIso8601String().substring(0, 10);
            final isToday = dateStr == todayStr;

            final statusColor = status == 'WATER_DEFICIT'
                ? const Color(0xFFEF4444)
                : status == 'RAIN_HOLD'
                    ? const Color(0xFF38BDF8)
                    : const Color(0xFF10B981);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isToday ? const Color(0xFF38BDF8) : borderColor,
                  width: isToday ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        dateStr.length >= 5 ? dateStr.substring(5) : dateStr,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                isToday ? 'Today ($dateStr)' : dateStr,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                            if (isToday)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF38BDF8),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'TODAY',
                                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ET₀: ${eto.toStringAsFixed(1)} mm • ETc: ${etc.toStringAsFixed(1)} mm',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 11, color: subtextColor),
                        ),
                      ],
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.cloudRain, size: 12, color: rain > 0 ? const Color(0xFF0284C7) : subtextColor),
                          const SizedBox(width: 4),
                          Text(
                            '${rain.toStringAsFixed(1)} mm Rain',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: rain > 0 ? const Color(0xFF0284C7) : subtextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
