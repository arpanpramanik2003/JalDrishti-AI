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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '🌦️ 6-Day Predictive Weather & Irrigation Window',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Open-Meteo Satellite',
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: dailyBreakdown.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (ctx, idx) {
            final day = dailyBreakdown[idx];
            final dateStr = (day['date'] as String? ?? '').split('-').skip(1).join('/');
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
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isRainy ? const Color(0xFF38BDF8).withValues(alpha: 0.5) : borderColor,
                  width: isRainy ? 1.5 : 1.0,
                ),
                boxShadow: isRainy
                    ? [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            dateStr,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        isRainy ? LucideIcons.cloudRain : LucideIcons.sun,
                        color: isRainy ? const Color(0xFF38BDF8) : const Color(0xFFF59E0B),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${tempMax.toStringAsFixed(0)}° / ${tempMin.toStringAsFixed(0)}° C',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '💧 ${humidity.toStringAsFixed(0)}% Humidity  |  💨 ${windKmh.toStringAsFixed(0)} km/h Wind',
                              style: GoogleFonts.inter(fontSize: 11, color: subtextColor),
                            ),
                          ],
                        ),
                      ),
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
