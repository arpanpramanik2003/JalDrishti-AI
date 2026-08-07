import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class WeatherStatsTab extends StatelessWidget {
  final List<dynamic> dailyBreakdown;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final Color subtextColor;
  final Color primaryColor;

  const WeatherStatsTab({
    super.key,
    required this.dailyBreakdown,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.subtextColor,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (dailyBreakdown.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(LucideIcons.cloudOff, size: 36, color: subtextColor),
              const SizedBox(height: 8),
              Text(
                '6-Day Weather forecast data loading...',
                style: GoogleFonts.inter(color: subtextColor, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Row wrapped with Expanded to prevent horizontal overflow
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🌦️ 6-Day Predictive Weather',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Satellite Evapotranspiration & Rain Forecast',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: subtextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.satellite, size: 12, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 4),
                  Text(
                    'Open-Meteo',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Forecast List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: dailyBreakdown.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (ctx, idx) {
            final day = dailyBreakdown[idx];
            final rawDateStr = day['date'] as String? ?? '';
            final dateStr = rawDateStr.split('-').skip(1).join('/');
            
            // Check if this card represents TODAY
            final isToday = rawDateStr == todayStr || (idx == 0 && (rawDateStr.isEmpty || !rawDateStr.contains('-')));

            final tempMax = (day['max_temp_c'] as num?)?.toDouble() ?? 30.0;
            final tempMin = (day['min_temp_c'] as num?)?.toDouble() ?? 22.0;
            final humidity = (day['humidity_percent'] as num?)?.toDouble() ?? 75.0;
            final windKmh = (day['wind_speed_kmh'] as num?)?.toDouble() ?? 10.0;
            final precipMm = (day['rainfall_mm'] as num?)?.toDouble() ?? 0.0;
            final et0 = (day['eto_mm'] as num?)?.toDouble() ?? 4.0;
            final isRainy = precipMm > 2.0;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isToday
                    ? (isDark ? const Color(0xFF16253B) : const Color(0xFFEFF6FF))
                    : cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isToday
                      ? const Color(0xFF0284C7)
                      : (isRainy ? const Color(0xFF38BDF8).withValues(alpha: 0.5) : borderColor),
                  width: isToday ? 2.0 : (isRainy ? 1.5 : 1.0),
                ),
                boxShadow: isToday
                    ? [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : (isRainy
                        ? [
                            BoxShadow(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Date Badge Box (Highlighted if TODAY)
                      Column(
                        children: [
                          if (isToday)
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'TODAY',
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          Container(
                            width: 54,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: isToday
                                  ? const Color(0xFF0284C7)
                                  : primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                dateStr.isNotEmpty ? dateStr : 'Tdy',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isToday ? Colors.white : primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // Weather Icon
                      Icon(
                        isRainy ? LucideIcons.cloudRain : LucideIcons.sun,
                        color: isRainy ? const Color(0xFF38BDF8) : const Color(0xFFF59E0B),
                        size: 22,
                      ),
                      const SizedBox(width: 12),

                      // Temperature & Weather Metrics
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${tempMax.toStringAsFixed(0)}° / ${tempMin.toStringAsFixed(0)}° C',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                if (isToday) ...[
                                  const SizedBox(width: 6),
                                  const Icon(LucideIcons.sparkles, size: 12, color: Color(0xFF38BDF8)),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '💧 ${humidity.toStringAsFixed(0)}%  |  💨 ${windKmh.toStringAsFixed(0)} km/h',
                              style: GoogleFonts.inter(fontSize: 11, color: subtextColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Rainfall & ET0 Metrics
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${precipMm.toStringAsFixed(1)} mm Rain',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isRainy ? const Color(0xFF38BDF8) : subtextColor,
                            ),
                          ),
                          Text(
                            'ET0: ${et0.toStringAsFixed(1)} mm/d',
                            style: GoogleFonts.inter(fontSize: 10, color: subtextColor),
                          ),
                        ],
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
