import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/farm_plot_model.dart';
import '../../widgets/log_irrigation_modal.dart';

class HistoryLogsTab extends StatefulWidget {
  final FarmPlotModel? selectedPlot;
  final List<dynamic> historyLogs;
  final bool isLoading;
  final VoidCallback onRefreshRequested;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final Color subtextColor;
  final Color primaryColor;

  const HistoryLogsTab({
    super.key,
    required this.selectedPlot,
    required this.historyLogs,
    required this.isLoading,
    required this.onRefreshRequested,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.subtextColor,
    required this.primaryColor,
  });

  @override
  State<HistoryLogsTab> createState() => _HistoryLogsTabState();
}

class _HistoryLogsTabState extends State<HistoryLogsTab> {
  void _openLogModal(BuildContext context) {
    if (widget.selectedPlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a farm plot first to log irrigation.'),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showLogIrrigationModal(
      context: context,
      plot: widget.selectedPlot!,
      onLogSuccess: widget.onRefreshRequested,
    );
  }

  @override
  Widget build(BuildContext context) {
    final areaAcres = widget.selectedPlot?.areaAcres ?? 2.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 Irrigation Run History',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.textColor,
                    ),
                  ),
                  Text(
                    'Recorded pump runs for ${widget.selectedPlot?.name ?? "selected plot"}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 11, color: widget.subtextColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              onPressed: () => _openLogModal(context),
              icon: const Icon(LucideIcons.plusCircle, size: 16, color: Colors.white),
              label: Text(
                'Log Water Run',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: widget.isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : widget.historyLogs.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28.0),
                        child: Column(
                          children: [
                            Icon(LucideIcons.history, size: 40, color: widget.subtextColor.withValues(alpha: 0.5)),
                            const SizedBox(height: 10),
                            Text(
                              'No logged pump sessions yet',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: widget.textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Track irrigation duration to compute accurate water balance and soil hydration.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(color: widget.subtextColor, fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _openLogModal(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(LucideIcons.plusCircle, size: 16, color: Colors.white),
                              label: Text(
                                'Log First Water Run',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.historyLogs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (ctx, idx) {
                        final log = widget.historyLogs[idx];
                        final appliedMm = (log['applied_mm'] as num?)?.toDouble() ?? 0.0;
                        final appliedDate = log['applied_date'] ?? '';
                        final notes = log['notes'] ?? 'Pump Irrigation Session';
                        final appliedKL = (appliedMm * areaAcres * 4046.86) / 1000.0;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: widget.borderColor.withValues(alpha: 0.7)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(LucideIcons.zap, color: Color(0xFF38BDF8), size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notes,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: widget.textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Date: $appliedDate  |  Vol: ${appliedKL.toStringAsFixed(1)} kL',
                                      style: GoogleFonts.inter(fontSize: 11, color: widget.subtextColor),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '+${appliedMm.toStringAsFixed(1)} mm',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
