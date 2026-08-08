import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SmartRainHoldCard extends StatefulWidget {
  final bool rainHoldActive;
  final String? rainHoldMessage;
  final double upcomingRainMm;
  final double estimatedCostSavedInr;

  const SmartRainHoldCard({
    super.key,
    required this.rainHoldActive,
    this.rainHoldMessage,
    this.upcomingRainMm = 0.0,
    this.estimatedCostSavedInr = 0.0,
  });

  @override
  State<SmartRainHoldCard> createState() => _SmartRainHoldCardState();
}

class _SmartRainHoldCardState extends State<SmartRainHoldCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.rainHoldActive && (widget.rainHoldMessage == null || widget.rainHoldMessage!.isEmpty)) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F9FF);
    final borderColor = isDark ? const Color(0xFF0284C7).withValues(alpha: 0.4) : const Color(0xFFBAE6FD);
    final titleColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1);
    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.cloudRain,
                    color: Color(0xFF0284C7),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0284C7),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'SMART RAIN HOLD ACTIVE',
                            style: GoogleFonts.outfit(
                              color: titleColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rain Forecast: ${widget.upcomingRainMm.toStringAsFixed(1)} mm upcoming',
                        style: GoogleFonts.inter(
                          color: subtextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.estimatedCostSavedInr > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.indianRupee, color: Color(0xFF10B981), size: 13),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 80),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${widget.estimatedCostSavedInr.toInt()} Saved',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF10B981),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedCrossFade(
              firstChild: Text(
                widget.rainHoldMessage ??
                    'Incoming rainfall will maintain soil field capacity naturally. Skip pumping today to avoid root waterlogging and save energy.',
                style: GoogleFonts.inter(
                  color: textColor,
                  fontSize: 13,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              secondChild: Text(
                widget.rainHoldMessage ??
                    'Incoming rainfall will maintain soil field capacity naturally. Skip pumping today to avoid root waterlogging and save energy.',
                style: GoogleFonts.inter(
                  color: textColor,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
            if ((widget.rainHoldMessage?.length ?? 0) > 90)
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _isExpanded ? 'Show less' : 'Read advisory details',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                      Icon(
                        _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                        size: 14,
                        color: titleColor,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
