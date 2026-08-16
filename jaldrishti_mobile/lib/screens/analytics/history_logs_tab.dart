import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/services/api_service.dart';
import '../../core/services/api_service.dart';
import '../../models/farm_plot_model.dart';
import '../../providers/auth_provider.dart';

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
  void _showAddLogDialog(BuildContext context) {
    if (widget.selectedPlot == null) return;

    final depthController = TextEditingController(text: "15.0");
    final notesController = TextEditingController(text: "Pump Irrigation Session");
    String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: widget.cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(LucideIcons.droplet, color: widget.primaryColor, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Log Water Run',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.textColor,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Applied Water Depth (mm)', style: GoogleFonts.inter(fontSize: 12, color: widget.subtextColor)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: depthController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.inter(color: widget.textColor),
                    decoration: InputDecoration(
                      hintText: 'e.g. 15.0',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Notes / Equipment', style: GoogleFonts.inter(fontSize: 12, color: widget.subtextColor)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: notesController,
                    style: GoogleFonts.inter(color: widget.textColor),
                    decoration: InputDecoration(
                      hintText: 'e.g. Drip 2.5 hours',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text('Cancel', style: GoogleFonts.inter(color: widget.subtextColor)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final depth = double.tryParse(depthController.text) ?? 10.0;
                          setDialogState(() => isSubmitting = true);
                          try {
                            final auth = Provider.of<AuthProvider>(context, listen: false);
                            if (auth.token != null) {
                              await ApiService.logIrrigationEvent(
                                payload: {
                                  'farm_plot_id': widget.selectedPlot!.id,
                                  'applied_mm': depth,
                                  'applied_date': selectedDate,
                                  'notes': notesController.text,
                                },
                                token: auth.token!,
                              );
                              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                              widget.onRefreshRequested();
                            }
                          } catch (_) {
                            if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Save Log', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
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
            Text(
              '📋 Irrigation Run History',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: widget.textColor,
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _showAddLogDialog(context),
              icon: const Icon(LucideIcons.plus, size: 14, color: Colors.white),
              label: Text(
                'Log Water Run',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.borderColor),
          ),
          child: widget.isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : widget.historyLogs.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Icon(LucideIcons.history, size: 36, color: widget.subtextColor),
                            const SizedBox(height: 8),
                            Text(
                              'No logged pump sessions found for this plot.',
                              style: GoogleFonts.inter(color: widget.subtextColor, fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => _showAddLogDialog(context),
                              icon: Icon(LucideIcons.plus, size: 14, color: widget.primaryColor),
                              label: Text('Log First Run', style: GoogleFonts.outfit(color: widget.primaryColor)),
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
                            border: Border.all(color: widget.borderColor),
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
