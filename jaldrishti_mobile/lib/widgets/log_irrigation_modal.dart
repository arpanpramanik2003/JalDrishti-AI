import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/farm_plot_model.dart';
import '../providers/auth_provider.dart';
import '../providers/irrigation_provider.dart';

void showLogIrrigationModal({
  required BuildContext context,
  required FarmPlotModel plot,
  VoidCallback? onLogSuccess,
}) {
  final pumpHpController = TextEditingController(text: plot.pumpHp.toString());
  final hoursController = TextEditingController(text: '1');
  final minsController = TextEditingController(text: '30');
  final notesController = TextEditingController();

  // Standard agricultural centrifugal pump flow rate lookup (L/sec) by HP
  double flowRateFromHp(double hp) {
    if (hp <= 1.0) return 1.2;
    if (hp <= 2.0) return 2.5;
    if (hp <= 3.0) return 3.5;
    if (hp <= 5.0) return 5.0;
    if (hp <= 7.5) return 7.5;
    if (hp <= 10.0) return 10.0;
    return hp * 1.0;
  }

  double getFlowLps(double hp) {
    if (hp == plot.pumpHp && plot.pumpFlowLps > 0) {
      return plot.pumpFlowLps;
    }
    return flowRateFromHp(hp);
  }

  // Formula: Applied mm = (flowLps × runtimeSeconds) / (areaM2)
  double calcAppliedMm(double hp, int hours, int mins) {
    final flowLps = getFlowLps(hp);
    final runtimeSeconds = (hours * 3600) + (mins * 60);
    final areaM2 = plot.areaAcres * 4046.86;
    if (areaM2 <= 0) return 0;
    return (flowLps * runtimeSeconds) / areaM2;
  }

  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
  final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
  final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  final primaryColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
  final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
  final bannerBg = isDark ? const Color(0xFF0284C7).withValues(alpha: 0.12) : const Color(0xFFE0F2FE);
  final borderColor = isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.4) : const Color(0xFFBAE6FD);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: cardBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          double hpRaw = double.tryParse(pumpHpController.text) ?? plot.pumpHp;
          if (hpRaw < 0) hpRaw = 0;
          if (hpRaw > 100) hpRaw = 100;
          final hp = hpRaw;

          int hrsRaw = int.tryParse(hoursController.text) ?? 1;
          if (hrsRaw < 0) hrsRaw = 0;
          if (hrsRaw > 24) hrsRaw = 24;
          final hrs = hrsRaw;

          int minsRaw = int.tryParse(minsController.text) ?? 0;
          if (minsRaw < 0) minsRaw = 0;
          if (minsRaw > 59) minsRaw = 59;
          final mins = minsRaw;

          final activeFlowLps = getFlowLps(hp);
          final calculatedMm = calcAppliedMm(hp, hrs, mins);
          final totalLiters = activeFlowLps * ((hrs * 3600) + (mins * 60));

          void refresh() => setModalState(() {});

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag indicator
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: subtextColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(LucideIcons.zap, color: primaryColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Record Pump Session',
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                            ),
                            Text(
                              'Log water application for ${plot.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 12, color: subtextColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Pump HP row
                  Text(
                    'Pump Horsepower (HP)',
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: subtextColor),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: pumpHpController,
                    maxLength: 4,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                    onChanged: (_) => refresh(),
                    decoration: InputDecoration(
                      counterText: '',
                      prefixIcon: Icon(LucideIcons.zap, color: primaryColor, size: 18),
                      suffixText: 'HP',
                      suffixStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                      hintText: 'e.g. 5',
                      hintStyle: TextStyle(color: subtextColor),
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Runtime Hours + Minutes row
                  Text(
                    'Pump Run Duration',
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: subtextColor),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: hoursController,
                          maxLength: 2,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                          textAlign: TextAlign.center,
                          onChanged: (_) => refresh(),
                          decoration: InputDecoration(
                            counterText: '',
                            labelText: 'Hours',
                            labelStyle: TextStyle(color: subtextColor, fontSize: 13),
                            prefixIcon: Icon(LucideIcons.clock, color: primaryColor, size: 18),
                            suffixText: 'hr',
                            suffixStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryColor, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: minsController,
                          maxLength: 2,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                          textAlign: TextAlign.center,
                          onChanged: (_) => refresh(),
                          decoration: InputDecoration(
                            counterText: '',
                            labelText: 'Minutes',
                            labelStyle: TextStyle(color: subtextColor, fontSize: 13),
                            prefixIcon: Icon(LucideIcons.timer, color: primaryColor, size: 18),
                            suffixText: 'min',
                            suffixStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryColor, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Auto-calculated result banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: bannerBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Water Depth Applied', style: GoogleFonts.inter(fontSize: 11, color: subtextColor)),
                                  Text(
                                    '${calculatedMm.toStringAsFixed(1)} mm',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Total Volume', style: GoogleFonts.inter(fontSize: 11, color: subtextColor)),
                                  Text(
                                    '${(totalLiters / 1000).toStringAsFixed(1)} kL',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(LucideIcons.info, size: 12, color: subtextColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Calculated for ${plot.areaAcres} acres using ${activeFlowLps.toStringAsFixed(1)} L/sec flow rate ($hp HP)',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 10, color: subtextColor),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Optional Notes
                  TextFormField(
                    controller: notesController,
                    maxLength: 200,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Notes (Optional) – e.g. "Drip line section B"',
                      labelStyle: TextStyle(color: subtextColor, fontSize: 12),
                      prefixIcon: Icon(LucideIcons.pencil, color: primaryColor, size: 16),
                      counterText: '',
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: calculatedMm <= 0
                          ? null
                          : () async {
                              final irrigation = context.read<IrrigationProvider>();
                              final auth = context.read<AuthProvider>();

                              // If user modified the pump HP from registered rating, prompt warning dialog
                              if (hp != plot.pumpHp) {
                                final confirm = await showDialog<bool>(
                                  context: ctx,
                                  builder: (alertCtx) => AlertDialog(
                                    backgroundColor: cardBg,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    title: Row(
                                      children: [
                                        const Icon(LucideIcons.alertTriangle, color: Colors.orangeAccent, size: 22),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Pump Power Modified',
                                          style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ],
                                    ),
                                    content: Text(
                                      'You changed the pump power rating from ${plot.pumpHp} HP to $hp HP.\n\n'
                                      'This will alter the water discharge rate (${activeFlowLps.toStringAsFixed(1)} L/sec) and recalculate the daily soil moisture balance for ${plot.name}.\n\n'
                                      'Are you sure you want to proceed with this modified pump rating?',
                                      style: GoogleFonts.inter(color: subtextColor, fontSize: 13, height: 1.4),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(alertCtx, false),
                                        child: Text('Cancel', style: GoogleFonts.inter(color: subtextColor)),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(alertCtx, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0284C7),
                                          foregroundColor: Colors.white,
                                        ),
                                        child: Text('Yes, Confirm & Log', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ) ?? false;

                                if (!confirm) return;
                              }

                              if (ctx.mounted) Navigator.pop(ctx);
                              final success = await irrigation.logIrrigationEvent(
                                plotId: plot.id,
                                appliedMm: calculatedMm,
                                notes:
                                    'Ran ${hrs}h ${mins}m pump ($hp HP) → ${calculatedMm.toStringAsFixed(1)} mm depth. ${notesController.text.trim()}',
                                authToken: auth.token,
                              );

                              if (success) {
                                onLogSuccess?.call();
                              }

                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Recorded: ${hrs}h ${mins}m pump run (${calculatedMm.toStringAsFixed(1)} mm) applied to soil!'
                                        : 'Failed to save irrigation record.',
                                  ),
                                  backgroundColor: success ? const Color(0xFF0284C7) : Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        disabledBackgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.save, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Save Pump Record & Update Field',
                            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
