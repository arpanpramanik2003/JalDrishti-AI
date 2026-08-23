import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/constants/api_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/farm_plot_provider.dart';
import '../providers/irrigation_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/gauge_widget.dart';
import '../widgets/skeleton_loading_widget.dart';
import '../widgets/smart_rain_hold_card.dart';
import '../widgets/farmer_roi_savings_card.dart';
import '../widgets/dashboard_weather_card.dart';
import '../widgets/dashboard_pump_card.dart';
import '../widgets/dashboard_crop_lifecycle_card.dart';
import '../widgets/dashboard_timeline_card.dart';
import '../widgets/app_drawer.dart';
import '../models/farm_plot_model.dart';
import 'add_edit_farm_plot_screen.dart';
import 'profile_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final irrigation = context.read<IrrigationProvider>();
      final farmPlotProvider = context.read<FarmPlotProvider>();

      farmPlotProvider.fetchPlots(auth: auth, irrigation: irrigation);
    });
  }

  void _showScientificTermsHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: [
            const Icon(LucideIcons.helpCircle, color: Color(0xFF38BDF8)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Farmer Guide: Terms',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpTerm(
                term: 'Soil Storage Capacity (TAW)',
                description: 'The maximum amount of water your farm soil can hold for plant roots.',
              ),
              _buildHelpTerm(
                term: 'Plant Water Usage (ETc)',
                description: 'The actual daily water depth your crop drinks and evaporates.',
              ),
              _buildHelpTerm(
                term: 'Sun & Wind Evaporation (ETo)',
                description: 'Reference water lost to hot weather, low humidity, and wind speed.',
              ),
              _buildHelpTerm(
                term: 'Crop Growth Factor (Kc)',
                description: 'Multiplier matching your crop stage (Initial = 0.45, Flowering = 1.15).',
              ),
              _buildHelpTerm(
                term: 'Pumping Hours (Runtime)',
                description: 'Calculated hours/minutes to run your water pump based on field size and pump HP.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Got It',
              style: GoogleFonts.outfit(color: const Color(0xFF38BDF8), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpTerm({required String term, required String description}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $term',
            style: GoogleFonts.outfit(color: const Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  void _showNotificationCenterModal(BuildContext context) {
    final notifProvider = context.read<NotificationProvider>();
    notifProvider.markAllAsRead();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer<NotificationProvider>(
          builder: (ctx, notif, _) {
            final feed = notif.feed;
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(LucideIcons.bellRing, color: primaryColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Notification Center',
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                            ),
                          ],
                        ),
                        if (feed.isNotEmpty)
                          TextButton(
                            onPressed: () => notif.clearFeed(),
                            child: Text(
                              'Clear All',
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (feed.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.bellOff, size: 36, color: subtextColor),
                              const SizedBox(height: 12),
                              Text(
                                'No notifications yet',
                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Daily irrigation and weather alerts will appear here.',
                                style: GoogleFonts.inter(fontSize: 12, color: subtextColor),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: feed.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (ctx, idx) {
                            final item = feed[idx];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      item.type == 'weather' ? LucideIcons.cloudRain : LucideIcons.droplet,
                                      color: primaryColor,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                                              ),
                                            ),
                                            Text(
                                              item.timestamp,
                                              style: GoogleFonts.inter(fontSize: 10, color: subtextColor),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.body,
                                          style: GoogleFonts.inter(fontSize: 12, color: subtextColor, height: 1.3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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

  Widget _buildEmptyStateView(BuildContext context, AuthProvider auth) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.sprout, size: 54, color: Color(0xFF38BDF8)),
            ),
            const SizedBox(height: 20),
            Text(
              'No Farm Plots Registered',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first agricultural land plot to start receiving real-time Penman-Monteith crop water recommendations.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: subtextColor, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEditFarmPlotScreen()),
                );
              },
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Add Your First Plot'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlotHeaderSwitcher(BuildContext context, FarmPlotProvider plotProvider, IrrigationProvider irrigation) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final primaryColor = const Color(0xFF38BDF8);

    final selected = plotProvider.selectedPlot;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        onTap: () => _showPlotSelectorModal(context, plotProvider, irrigation),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(LucideIcons.mapPin, color: primaryColor, size: 20),
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
                            selected?.name ?? 'Main Plot',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(LucideIcons.chevronDown, size: 16, color: subtextColor),
                      ],
                    ),
                    Text(
                      '${selected?.cropId.replaceAll('_', ' ').toUpperCase() ?? "PADDY"} • ${selected?.areaAcres ?? 2.5} Acres',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 11, color: subtextColor),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.plusCircle, color: Color(0xFF0284C7), size: 22),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddEditFarmPlotScreen()),
                  );
                },
                tooltip: 'Add New Plot',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlotSelectorModal(BuildContext context, FarmPlotProvider plotProvider, IrrigationProvider irrigation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
        final maxHeight = MediaQuery.of(ctx).size.height * 0.80;

        return Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modal Drag Handle
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: subtextColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.mapPin, color: Color(0xFF0284C7), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Farm Plot & Crop',
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Text(
                              '${plotProvider.plots.length} ${plotProvider.plots.length == 1 ? "Plot" : "Plots"} available',
                              style: GoogleFonts.inter(fontSize: 11, color: subtextColor),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(LucideIcons.x, color: textColor, size: 20),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Scrollable Plots List
                if (plotProvider.plots.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.sprout, size: 40, color: subtextColor.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'No farm plots found',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap the button below to add your first plot and crop.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 12, color: subtextColor),
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: plotProvider.plots.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final p = plotProvider.plots[index];
                        final isSelected = p.id == plotProvider.selectedPlot?.id;

                        return Material(
                          color: isSelected
                              ? const Color(0xFF0284C7).withValues(alpha: 0.1)
                              : isDark
                                  ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                                  : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF0284C7).withValues(alpha: 0.6)
                                  : borderColor.withValues(alpha: 0.6),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              plotProvider.selectPlot(p, irrigation);
                              Navigator.pop(ctx);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF0284C7).withValues(alpha: 0.2)
                                          : (isDark ? const Color(0xFF1E293B) : Colors.white),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      LucideIcons.sprout,
                                      color: isSelected ? const Color(0xFF0284C7) : subtextColor,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.outfit(
                                            fontSize: 15,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${p.cropId.replaceAll('_', ' ').toUpperCase()} • ${p.areaAcres} Acres • ${p.pumpHp} HP',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(fontSize: 11, color: subtextColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Icon(
                                        LucideIcons.checkCircle2,
                                        color: Color(0xFF10B981),
                                        size: 20,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // Bottom Action Button (Always visible & within Safe Area)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddEditFarmPlotScreen()),
                        );
                      },
                      icon: const Icon(LucideIcons.plus, size: 16),
                      label: Text(
                        'Create New Farm Plot',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0284C7),
                        side: const BorderSide(color: Color(0xFF0284C7), width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogIrrigationModal(BuildContext context, int plotId, FarmPlotModel plot) {
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Record Pump Session',
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                            ),
                            Text(
                              'Tell us how long you ran the pump',
                              style: GoogleFonts.inter(fontSize: 12, color: subtextColor),
                            ),
                          ],
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

                                Navigator.pop(ctx);
                                final success = await irrigation.logIrrigationEvent(
                                  plotId: plotId,
                                  appliedMm: calculatedMm,
                                  notes:
                                      'Ran ${hrs}h ${mins}m pump ($hp HP) → ${calculatedMm.toStringAsFixed(1)} mm depth. ${notesController.text.trim()}',
                                );
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Recorded: ${hrs}h ${mins}m pump run (${calculatedMm.toStringAsFixed(1)} mm) applied to soil!'
                                          : 'Failed to save irrigation record.',
                                    ),
                                    backgroundColor: success ? const Color(0xFF0284C7) : Colors.redAccent,
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final irrigation = context.watch<IrrigationProvider>();
    final farmPlotProvider = context.watch<FarmPlotProvider>();

    final data = irrigation.irrigationData;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final appBarBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final iconColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);

    return Scaffold(
      backgroundColor: scaffoldBg,
      drawer: const AppDrawer(activeRoute: 'dashboard'),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: appBarBg,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 6),
            ClipOval(
              child: Image.asset(
                'assets/icons/android-chrome-192x192.png',
                height: 26,
                width: 26,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Icon(LucideIcons.droplet, color: iconColor, size: 22),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'JalDrishti',
              style: GoogleFonts.outfit(
                color: titleColor,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          // 1. Notification Center Bell
          Consumer<NotificationProvider>(
            builder: (context, notif, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(LucideIcons.bell, color: iconColor, size: 20),
                    onPressed: () => _showNotificationCenterModal(context),
                    tooltip: 'Notification Center',
                  ),
                  if (notif.unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${notif.unreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          // 2. Profile Avatar Button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Tooltip(
                message: 'Profile & Settings',
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: iconColor, width: 1.5),
                  ),
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: iconColor.withValues(alpha: 0.15),
                    child: Text(
                      (auth.user?.profile?.firstName ?? auth.user?.username ?? 'F').substring(0, 1).toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. Overflow Options Menu (Refresh & Scientific Terms Guide)
          PopupMenuButton<String>(
            icon: Icon(LucideIcons.moreVertical, color: iconColor, size: 20),
            color: appBarBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (value) {
              if (value == 'refresh') {
                final notif = context.read<NotificationProvider>();
                farmPlotProvider.fetchPlots(auth: auth, irrigation: irrigation);
                irrigation.loadIrrigationData(notificationProvider: notif, authToken: auth.token);
              } else if (value == 'guide') {
                _showScientificTermsHelp(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(LucideIcons.refreshCw, color: iconColor, size: 16),
                    const SizedBox(width: 10),
                    Text('Refresh Weather & Data', style: GoogleFonts.inter(fontSize: 13, color: titleColor)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'guide',
                child: Row(
                  children: [
                    Icon(LucideIcons.helpCircle, color: iconColor, size: 16),
                    const SizedBox(width: 10),
                    Text('Scientific Terms Guide', style: GoogleFonts.inter(fontSize: 13, color: titleColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: farmPlotProvider.isLoading || irrigation.isLoading
          ? const DashboardSkeletonLoader()
          : farmPlotProvider.plots.isEmpty
              ? _buildEmptyStateView(context, auth)
              : RefreshIndicator(
                  color: const Color(0xFF38BDF8),
                  backgroundColor: const Color(0xFF1E293B),
                  onRefresh: () async {
                    final notif = context.read<NotificationProvider>();
                    await farmPlotProvider.fetchPlots(auth: auth, irrigation: irrigation);
                    await irrigation.loadIrrigationData(notificationProvider: notif, authToken: auth.token);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Offline Mode Banner
                        if (irrigation.isOfflineMode) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.wifiOff, size: 16, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Offline Mode: Displaying cached recommendations.',
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFF59E0B)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        // 1. Multi-Plot Switcher Header
                        _buildPlotHeaderSwitcher(context, farmPlotProvider, irrigation),
                        const SizedBox(height: 16),

                        // 2. Real-Time Live Weather Card
                        DashboardWeatherCard(
                          weatherSummary: data?['weather_summary'] ?? (data?['daily_breakdown'] != null && data!['daily_breakdown'].isNotEmpty ? data['daily_breakdown'][0] : null),
                        ),
                        const SizedBox(height: 16),

                        // 3. SMART RAIN HOLD ALERT BANNER
                        if (data != null)
                          SmartRainHoldCard(
                            rainHoldActive: data['rain_hold_active'] ?? false,
                            rainHoldMessage: data['rain_hold_message'],
                            upcomingRainMm: (data['upcoming_rain_mm'] as num?)?.toDouble() ?? 0.0,
                            estimatedCostSavedInr: (data['estimated_cost_saved_inr'] as num?)?.toDouble() ?? 0.0,
                          ),

                        // 4. FARMER ROI & SAVINGS TRACKER CARD
                        if (data != null && data['cumulative_savings'] != null)
                          FarmerRoiSavingsCard(
                            totalWaterSavedLiters: (data['cumulative_savings']['total_water_saved_liters'] as num?)?.toDouble() ?? 0.0,
                            totalPumpHoursSaved: (data['cumulative_savings']['total_pump_hours_saved'] as num?)?.toDouble() ?? 0.0,
                            totalMoneySavedInr: (data['cumulative_savings']['total_money_saved_inr'] as num?)?.toDouble() ?? 0.0,
                            totalCo2ReducedKg: (data['cumulative_savings']['total_co2_reduced_kg'] as num?)?.toDouble() ?? 0.0,
                            skippedRunsCount: (data['cumulative_savings']['skipped_runs_count'] as num?)?.toInt() ?? 0,
                            attributionNotice: data['cumulative_savings']['attribution_notice'] as String?,
                            stateCode: data['cumulative_savings']['state_code'] as String?,
                            stateName: data['cumulative_savings']['state_name'] as String?,
                            tariffRateInrHr: (data['cumulative_savings']['tariff_rate_inr_hr'] as num?)?.toDouble(),
                            co2FactorKgHr: (data['cumulative_savings']['co2_factor_kg_hr'] as num?)?.toDouble(),
                          ),

                        // 5. Hydrological Recommendation Gauge Widget
                        IrrigationStatusGauge(
                          needsIrrigation: data?['needs_irrigation_today'] ?? false,
                          recommendedWaterMm:
                              (data?['recommended_water_mm'] as num?)?.toDouble() ?? 0.0,
                          tawMm: (data?['total_available_water_mm'] as num?)?.toDouble() ?? 0.0,
                          statusSummary: data?['status_summary'] ?? 'OPTIMAL',
                        ),
                        const SizedBox(height: 16),

                        // 6. Practical Pump Runtime Card
                        DashboardPumpCard(
                          data: data,
                          selectedPlot: farmPlotProvider.selectedPlot,
                          todayLoggedMm: irrigation.todayLoggedMm,
                          onLogIrrigationPressed: () {
                            if (farmPlotProvider.selectedPlot != null) {
                              _showLogIrrigationModal(context, farmPlotProvider.selectedPlot!.id, farmPlotProvider.selectedPlot!);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // 7. Dynamic Crop Lifecycle Overview
                        DashboardCropLifecycleCard(
                          data: data,
                          selectedPlot: farmPlotProvider.selectedPlot,
                        ),
                        const SizedBox(height: 16),

                        // 8. 6-Day Hydrological Timeline Card
                        DashboardTimelineCard(
                          dailyBreakdown: data?['daily_breakdown'],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class WaterUsageOverviewAnalytics extends StatefulWidget {
  final Map<String, dynamic>? irrigationData;
  final FarmPlotModel? selectedPlot;

  const WaterUsageOverviewAnalytics({
    super.key,
    required this.irrigationData,
    required this.selectedPlot,
  });

  @override
  State<WaterUsageOverviewAnalytics> createState() => _WaterUsageOverviewAnalyticsState();
}

class _WaterUsageOverviewAnalyticsState extends State<WaterUsageOverviewAnalytics> {
  int _selectedTab = 0; // 0: Daily Chart, 1: Cumulative Overview, 2: Session Logs
  List<dynamic> _historyLogs = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _fetchHistoryLogs();
  }

  @override
  void didUpdateWidget(covariant WaterUsageOverviewAnalytics oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPlot?.id != widget.selectedPlot?.id) {
      _fetchHistoryLogs();
    }
  }

  Future<void> _fetchHistoryLogs() async {
    if (widget.selectedPlot == null) return;
    setState(() => _isLoadingHistory = true);
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/irrigation/history/${widget.selectedPlot!.id}'),
      );
      if (res.statusCode == 200) {
        final List<dynamic> logs = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _historyLogs = logs;
            _isLoadingHistory = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingHistory = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final dailyBreakdown = (widget.irrigationData?['daily_breakdown'] as List<dynamic>?) ?? [];
    final plot = widget.selectedPlot;
    final areaAcres = plot?.areaAcres ?? 2.5;

    // Continuous calculations
    double totalAppliedMm = 0.0;
    double totalRainMm = 0.0;
    double totalEtcMm = 0.0;

    for (var m in dailyBreakdown) {
      totalAppliedMm += (m['irrigation_applied_mm'] as num?)?.toDouble() ?? 0.0;
      totalRainMm += (m['rainfall_mm'] as num?)?.toDouble() ?? 0.0;
      totalEtcMm += (m['etc_mm'] as num?)?.toDouble() ?? 0.0;
    }

    final totalAppliedKL = (totalAppliedMm * areaAcres * 4046.86) / 1000.0;
    final totalRainKL = (totalRainMm * areaAcres * 4046.86) / 1000.0;
    final totalEtcKL = (totalEtcMm * areaAcres * 4046.86) / 1000.0;
    final totalSupplyMm = totalAppliedMm + totalRainMm;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(LucideIcons.barChart2, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Water Usage & Historical Analytics',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      plot != null
                          ? 'Continuous tracking for ${plot.name} since ${plot.sowingDate}'
                          : 'Continuous field water statistics',
                      style: GoogleFonts.inter(fontSize: 11, color: subtextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Interactive Segmented Tab Control (4 Tabs)
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _buildTabPill(0, '📊 Trend', isDark, primaryColor, textColor),
                _buildTabPill(1, '💡 Insights', isDark, primaryColor, textColor),
                _buildTabPill(2, '🌊 Balance', isDark, primaryColor, textColor),
                _buildTabPill(3, '📋 History', isDark, primaryColor, textColor),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Smart Calculations
          () {
            final satisfactionRatio = totalEtcMm > 0 ? (totalSupplyMm / totalEtcMm) * 100 : 100.0;
            final isOptimal = satisfactionRatio >= 85 && satisfactionRatio <= 115;
            final isDeficit = satisfactionRatio < 85;
            final savedKL = (totalAppliedKL * 0.30);
            final savedMoneyRupees = (savedKL * 8.5);

            // TAB CONTENT VIEWS
            if (_selectedTab == 0) {
              // Tab 0: Visual Custom Canvas Bar Chart
              if (dailyBreakdown.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text('No daily trend data available yet.', style: GoogleFonts.inter(color: subtextColor)),
                  ),
                );
              } else {
                return Column(
                  children: [
                    SizedBox(
                      height: 170,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: WaterUsageChartPainter(
                          dailyBreakdown: dailyBreakdown,
                          isDark: isDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: dailyBreakdown.map((m) {
                        final dateStr = (m['date'] as String? ?? '').split('-').skip(1).join('/');
                        return Text(
                          dateStr,
                          style: GoogleFonts.inter(fontSize: 10, color: subtextColor, fontWeight: FontWeight.w600),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildLegendItem(const Color(0xFF0284C7), 'Applied Water (Farmer)', subtextColor),
                        _buildLegendItem(const Color(0xFF38BDF8), 'Rainfall', subtextColor),
                        _buildLegendItem(const Color(0xFFF59E0B), 'Crop Demand (ETc)', subtextColor),
                      ],
                    ),
                  ],
                );
              }
            } else if (_selectedTab == 1) {
              // Tab 1: Smart Agronomic Advisory & Observations
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Water Health Status Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isOptimal
                                ? const Color(0xFF10B981)
                                : isDeficit
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF38BDF8))
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (isOptimal
                                  ? const Color(0xFF10B981)
                                  : isDeficit
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF38BDF8))
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isOptimal
                                ? LucideIcons.checkCircle2
                                : isDeficit
                                    ? LucideIcons.alertTriangle
                                    : LucideIcons.droplets,
                            color: isOptimal
                                ? const Color(0xFF10B981)
                                : isDeficit
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF38BDF8),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isOptimal
                                      ? 'Optimal Hydration (${satisfactionRatio.toStringAsFixed(0)}%)'
                                      : isDeficit
                                          ? 'Water Deficit Alert (${satisfactionRatio.toStringAsFixed(0)}%)'
                                          : 'High Storage Level (${satisfactionRatio.toStringAsFixed(0)}%)',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isOptimal
                                        ? const Color(0xFF10B981)
                                        : isDeficit
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFF38BDF8),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isOptimal
                                      ? 'Your field receives ideal moisture matching crop ETc loss. Root zone is healthy.'
                                      : isDeficit
                                          ? 'Field supply is below crop ETc requirement. Run your pump soon to prevent yield loss.'
                                          : 'Supply exceeds crop demand. Reduce pump runtime to prevent nutrient leaching.',
                                  style: GoogleFonts.inter(fontSize: 12, color: subtextColor, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. Resource Savings Counter
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.piggyBank, color: Color(0xFF10B981), size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Precision Savings Counter', style: GoogleFonts.inter(fontSize: 11, color: subtextColor)),
                                const SizedBox(height: 2),
                                Text(
                                  'Saved ~${savedKL.toStringAsFixed(1)} kL water (≈ ₹${savedMoneyRupees.toStringAsFixed(0)} fuel/energy)',
                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            } else if (_selectedTab == 2) {
              // Tab 2: Continuous Water Balance Breakdown
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildBalanceMetric('💧 Irrigation Applied', '${totalAppliedMm.toStringAsFixed(1)} mm', '${totalAppliedKL.toStringAsFixed(1)} kL', const Color(0xFF0284C7), subtextColor),
                        _buildBalanceMetric('🌧️ Rainfall Received', '${totalRainMm.toStringAsFixed(1)} mm', '${totalRainKL.toStringAsFixed(1)} kL', const Color(0xFF0284C7), subtextColor),
                        _buildBalanceMetric('🌾 Crop Demand (ETc)', '${totalEtcMm.toStringAsFixed(1)} mm', '${totalEtcKL.toStringAsFixed(1)} kL', const Color(0xFFF59E0B), subtextColor),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Water Satisfaction Index', style: GoogleFonts.inter(fontSize: 11, color: subtextColor)),
                            Text(
                              totalEtcMm > 0
                                  ? '${((totalSupplyMm / totalEtcMm) * 100).clamp(0, 150).toStringAsFixed(0)}%'
                                  : '100%',
                              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: primaryColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: totalEtcMm > 0 ? (totalSupplyMm / totalEtcMm).clamp(0.0, 1.0) : 1.0,
                            minHeight: 8,
                            backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            } else {
              // Tab 3: Historical Irrigation Log Feed
              if (_isLoadingHistory) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              if (_historyLogs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text('No logged pump sessions found.', style: GoogleFonts.inter(color: subtextColor)),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _historyLogs.length > 5 ? 5 : _historyLogs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final log = _historyLogs[idx];
                  final appliedMm = (log['applied_mm'] as num?)?.toDouble() ?? 0.0;
                  final appliedDate = log['applied_date'] ?? '';
                  final notes = log['notes'] ?? 'Pump irrigation';

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(LucideIcons.zap, color: Color(0xFF38BDF8), size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notes,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                appliedDate,
                                style: GoogleFonts.inter(fontSize: 11, color: subtextColor),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '+${appliedMm.toStringAsFixed(1)} mm',
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                        ),
                      ],
                    ),
                  );
                },
              );
            }
          }(),
        ],
      ),
    );
  }

  Widget _buildTabPill(int index, String label, bool isDark, Color primaryColor, Color textColor) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected && !isDark
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? primaryColor : textColor.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, Color subtextColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: subtextColor)),
      ],
    );
  }

  Widget _buildBalanceMetric(String label, String valMm, String valKL, Color valColor, Color subtextColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: subtextColor)),
          const SizedBox(height: 2),
          Text(valMm, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: valColor)),
          Text(valKL, style: GoogleFonts.inter(fontSize: 10, color: subtextColor)),
        ],
      ),
    );
  }
}

class WaterUsageChartPainter extends CustomPainter {
  final List<dynamic> dailyBreakdown;
  final bool isDark;

  WaterUsageChartPainter({required this.dailyBreakdown, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (dailyBreakdown.isEmpty) return;

    final double width = size.width;
    final double height = size.height;
    final double gap = width / dailyBreakdown.length;
    final double barWidth = gap * 0.25;

    double maxVal = 10.0;
    for (var m in dailyBreakdown) {
      double applied = (m['irrigation_applied_mm'] as num?)?.toDouble() ?? 0.0;
      double rain = (m['rainfall_mm'] as num?)?.toDouble() ?? 0.0;
      double etc = (m['etc_mm'] as num?)?.toDouble() ?? 0.0;
      if (applied > maxVal) maxVal = applied;
      if (rain > maxVal) maxVal = rain;
      if (etc > maxVal) maxVal = etc;
    }
    maxVal += 2.0;

    final gridPaint = Paint()
      ..color = isDark ? Colors.white10 : Colors.black12
      ..strokeWidth = 1.0;

    // Draw horizontal grid lines
    for (int i = 0; i <= 3; i++) {
      double y = height - (height * (i / 3));
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    final etcPoints = <Offset>[];

    for (int i = 0; i < dailyBreakdown.length; i++) {
      final m = dailyBreakdown[i];
      final double xCenter = (i * gap) + (gap / 2);

      double applied = (m['irrigation_applied_mm'] as num?)?.toDouble() ?? 0.0;
      double rain = (m['rainfall_mm'] as num?)?.toDouble() ?? 0.0;
      double etc = (m['etc_mm'] as num?)?.toDouble() ?? 0.0;

      // 1. Applied Water Bar (Blue)
      if (applied > 0) {
        final double barH = (applied / maxVal) * height;
        final rect = Rect.fromLTWH(xCenter - barWidth - 1, height - barH, barWidth, barH);
        final paint = Paint()
          ..color = const Color(0xFF0284C7)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), paint);
      }

      // 2. Rainfall Bar (Cyan)
      if (rain > 0) {
        final double barH = (rain / maxVal) * height;
        final rect = Rect.fromLTWH(xCenter + 1, height - barH, barWidth, barH);
        final paint = Paint()
          ..color = const Color(0xFF38BDF8)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), paint);
      }

      // 3. Track ETc Benchmark Line point
      double etcY = height - ((etc / maxVal) * height);
      etcPoints.add(Offset(xCenter, etcY));
    }

    // Draw ETc Trend Line (Orange/Amber)
    if (etcPoints.length > 1) {
      final linePaint = Paint()
        ..color = const Color(0xFFF59E0B)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(etcPoints[0].dx, etcPoints[0].dy);
      for (int i = 1; i < etcPoints.length; i++) {
        path.lineTo(etcPoints[i].dx, etcPoints[i].dy);
      }
      canvas.drawPath(path, linePaint);

      // Draw dots on ETc line
      final dotPaint = Paint()
        ..color = const Color(0xFFF59E0B)
        ..style = PaintingStyle.fill;
      for (var pt in etcPoints) {
        canvas.drawCircle(pt, 3.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}