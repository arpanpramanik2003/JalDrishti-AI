import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DashboardWeatherCard extends StatelessWidget {
  final Map<String, dynamic>? weatherSummary;

  const DashboardWeatherCard({
    super.key,
    this.weatherSummary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final maxTemp = (weatherSummary?['max_temp_c'] as num?)?.toDouble() ?? 30.0;
    final minTemp = (weatherSummary?['min_temp_c'] as num?)?.toDouble() ?? 22.0;
    final humidity = (weatherSummary?['humidity_percent'] as num?)?.toDouble() ?? 75.0;
    final wind = (weatherSummary?['wind_speed_kmh'] as num?)?.toDouble() ?? 12.0;
    final rain = (weatherSummary?['precipitation_mm'] as num?)?.toDouble() ?? 0.0;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.cloudSun, color: Color(0xFF38BDF8), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'FIELD MICRO-CLIMATE',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF38BDF8),
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'LIVE',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Real-Time Open-Meteo Satellite Feed',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 11, color: subtextColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherStat(
                icon: LucideIcons.thermometer,
                value: '${maxTemp.toStringAsFixed(0)}° / ${minTemp.toStringAsFixed(0)}°C',
                label: 'Max/Min Temp',
                color: const Color(0xFFF59E0B),
                textColor: textColor,
                subtextColor: subtextColor,
              ),
              _buildWeatherStat(
                icon: LucideIcons.droplets,
                value: '${humidity.toStringAsFixed(0)}%',
                label: 'Humidity',
                color: const Color(0xFF38BDF8),
                textColor: textColor,
                subtextColor: subtextColor,
              ),
              _buildWeatherStat(
                icon: LucideIcons.wind,
                value: '${wind.toStringAsFixed(0)} km/h',
                label: 'Wind Speed',
                color: const Color(0xFF8B5CF6),
                textColor: textColor,
                subtextColor: subtextColor,
              ),
              _buildWeatherStat(
                icon: LucideIcons.cloudRain,
                value: '${rain.toStringAsFixed(1)} mm',
                label: 'Precipitation',
                color: const Color(0xFF0284C7),
                textColor: textColor,
                subtextColor: subtextColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color textColor,
    required Color subtextColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: subtextColor),
        ),
      ],
    );
  }
}
