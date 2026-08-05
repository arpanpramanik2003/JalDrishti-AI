import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DailyTrendsTab extends StatelessWidget {
  final List<dynamic> dailyBreakdown;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final Color subtextColor;
  final Color primaryColor;

  const DailyTrendsTab({
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
          child: Text(
            'No daily trend data available.',
            style: GoogleFonts.inter(color: subtextColor),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 6-Day Hydrological & Water Usage Trends',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 10),

        // Visual Chart Container
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
              SizedBox(
                height: 180,
                width: double.infinity,
                child: CustomPaint(
                  painter: WaterUsageChartPainter(
                    dailyBreakdown: dailyBreakdown,
                    isDark: isDark,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: dailyBreakdown.map((m) {
                  final dateStr = (m['date'] as String? ?? '').split('-').skip(1).join('/');
                  return Text(
                    dateStr,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: subtextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  _buildLegendItem(const Color(0xFF0284C7), 'Applied Water', subtextColor),
                  _buildLegendItem(const Color(0xFF38BDF8), 'Rainfall', subtextColor),
                  _buildLegendItem(const Color(0xFFF59E0B), 'Crop Demand (ETc)', subtextColor),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Daily Numeric Breakdown Cards
        Text(
          '📋 Daily Metric Breakdown',
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: dailyBreakdown.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (ctx, idx) {
            final m = dailyBreakdown[idx];
            final dateStr = m['date'] ?? '';
            final applied = (m['irrigation_applied_mm'] as num?)?.toDouble() ?? 0.0;
            final rain = (m['rainfall_mm'] as num?)?.toDouble() ?? 0.0;
            final etc = (m['etc_mm'] as num?)?.toDouble() ?? 0.0;
            final status = m['status'] ?? 'OPTIMAL';
            final isIrrigate = status.contains('IRRIGATE');

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.calendar,
                      size: 16,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateStr,
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Applied: ${applied.toStringAsFixed(1)} mm  |  Rain: ${rain.toStringAsFixed(1)} mm',
                          style: GoogleFonts.inter(fontSize: 11, color: subtextColor),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'ETc: ${etc.toStringAsFixed(1)} mm',
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFF59E0B)),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isIrrigate ? Colors.amber : const Color(0xFF10B981)).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isIrrigate ? 'IRRIGATE' : 'OPTIMAL',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isIrrigate ? Colors.amber[800] : const Color(0xFF10B981),
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

  Widget _buildLegendItem(Color color, String label, Color subtextColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: subtextColor)),
      ],
    );
  }
}

class WaterUsageChartPainter extends CustomPainter {
  final List<dynamic> dailyBreakdown;
  final bool isDark;

  WaterUsageChartPainter({
    required this.dailyBreakdown,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dailyBreakdown.isEmpty) return;

    double maxVal = 10.0;
    for (var m in dailyBreakdown) {
      final applied = (m['irrigation_applied_mm'] as num?)?.toDouble() ?? 0.0;
      final rain = (m['rainfall_mm'] as num?)?.toDouble() ?? 0.0;
      final etc = (m['etc_mm'] as num?)?.toDouble() ?? 0.0;
      if (applied + rain > maxVal) maxVal = applied + rain;
      if (etc > maxVal) maxVal = etc;
    }
    maxVal *= 1.25;

    final gridPaint = Paint()
      ..color = (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)).withValues(alpha: 0.6)
      ..strokeWidth = 1;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw Y-Axis Horizontal Gridlines and Scale Labels
    for (int i = 0; i <= 3; i++) {
      final val = (maxVal / 3) * i;
      final y = size.height - (size.height / 3) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);

      textPainter.text = TextSpan(
        text: '${val.toStringAsFixed(0)} mm',
        style: TextStyle(
          fontSize: 9,
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(2, y - 12));
    }

    final barWidth = (size.width / dailyBreakdown.length) * 0.35;
    final groupWidth = size.width / dailyBreakdown.length;

    final appliedPaint = Paint()..color = const Color(0xFF0284C7);
    final rainPaint = Paint()..color = const Color(0xFF38BDF8);
    final etcLinePaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final etcPoints = <Offset>[];

    for (int i = 0; i < dailyBreakdown.length; i++) {
      final item = dailyBreakdown[i];
      final applied = (item['irrigation_applied_mm'] as num?)?.toDouble() ?? 0.0;
      final rain = (item['rainfall_mm'] as num?)?.toDouble() ?? 0.0;
      final etc = (item['etc_mm'] as num?)?.toDouble() ?? 0.0;

      final groupX = i * groupWidth + (groupWidth / 2);
      final appliedH = (applied / maxVal) * size.height;
      final rainH = (rain / maxVal) * size.height;

      // Applied Water Bar
      final appliedRect = Rect.fromLTWH(
        groupX - barWidth,
        size.height - appliedH,
        barWidth * 0.9,
        appliedH,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(appliedRect, const Radius.circular(4)), appliedPaint);

      // Rainfall Bar
      final rainRect = Rect.fromLTWH(
        groupX,
        size.height - rainH,
        barWidth * 0.9,
        rainH,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(rainRect, const Radius.circular(4)), rainPaint);

      final etcY = size.height - (etc / maxVal) * size.height;
      etcPoints.add(Offset(groupX, etcY));
    }

    // Draw Crop Demand ETc Spline Line
    if (etcPoints.length > 1) {
      final path = Path();
      path.moveTo(etcPoints[0].dx, etcPoints[0].dy);
      for (int i = 1; i < etcPoints.length; i++) {
        path.lineTo(etcPoints[i].dx, etcPoints[i].dy);
      }
      canvas.drawPath(path, etcLinePaint);

      final dotPaint = Paint()..color = const Color(0xFFF59E0B);
      final innerDotPaint = Paint()..color = Colors.white;
      for (var pt in etcPoints) {
        canvas.drawCircle(pt, 5, dotPaint);
        canvas.drawCircle(pt, 2, innerDotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant WaterUsageChartPainter oldDelegate) {
    return oldDelegate.dailyBreakdown != dailyBreakdown || oldDelegate.isDark != isDark;
  }
}
