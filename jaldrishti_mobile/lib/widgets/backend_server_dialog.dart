import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/constants/api_constants.dart';

void showBackendServerDialog(BuildContext context, {VoidCallback? onUpdated}) {
  String selectedMode = ApiConstants.activeMode;
  final customUrlController = TextEditingController(text: ApiConstants.customUrl);

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final dialogBg = isDark ? const Color(0xFF131B2E) : Colors.white;
          final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
          final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

          return AlertDialog(
            backgroundColor: dialogBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(LucideIcons.server, color: Color(0xFF38BDF8)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Server Configuration',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select the backend server endpoint to connect to:',
                    style: GoogleFonts.inter(fontSize: 12, color: subtextColor),
                  ),
                  const SizedBox(height: 12),
                  
                  // Option 1: Live Cloud
                  RadioListTile<String>(
                    value: 'cloud',
                    groupValue: selectedMode,
                    title: Text('🌐 Render Cloud (Live)', style: GoogleFonts.inter(fontSize: 14, color: textColor, fontWeight: FontWeight.w600)),
                    subtitle: Text('https://jaldrishti-ai.onrender.com/api/v1', style: GoogleFonts.inter(fontSize: 11, color: subtextColor)),
                    activeColor: const Color(0xFF38BDF8),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedMode = val);
                    },
                  ),
                  
                  // Option 2: Local Emulator
                  RadioListTile<String>(
                    value: 'local',
                    groupValue: selectedMode,
                    title: Text('💻 Local PC (10.0.2.2 - Emulator)', style: GoogleFonts.inter(fontSize: 14, color: textColor, fontWeight: FontWeight.w600)),
                    subtitle: Text('http://10.0.2.2:8000/api/v1', style: GoogleFonts.inter(fontSize: 11, color: subtextColor)),
                    activeColor: const Color(0xFF38BDF8),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedMode = val);
                    },
                  ),
                  
                  // Option 3: Local USB Reverse (Physical Device)
                  RadioListTile<String>(
                    value: 'usb',
                    groupValue: selectedMode,
                    title: Text('📱 Physical Phone (127.0.0.1 - adb reverse)', style: GoogleFonts.inter(fontSize: 14, color: textColor, fontWeight: FontWeight.w600)),
                    subtitle: Text('http://127.0.0.1:8000/api/v1 (requires adb reverse)', style: GoogleFonts.inter(fontSize: 11, color: subtextColor)),
                    activeColor: const Color(0xFF38BDF8),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedMode = val);
                    },
                  ),

                  // Option 4: Custom URL / Wi-Fi IP
                  RadioListTile<String>(
                    value: 'custom',
                    groupValue: selectedMode,
                    title: Text('⚙️ Custom Wi-Fi IP / Server URL', style: GoogleFonts.inter(fontSize: 14, color: textColor, fontWeight: FontWeight.w600)),
                    subtitle: Text('e.g. http://192.168.1.15:8000/api/v1', style: GoogleFonts.inter(fontSize: 11, color: subtextColor)),
                    activeColor: const Color(0xFF38BDF8),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedMode = val);
                    },
                  ),

                  if (selectedMode == 'custom') ...[
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: customUrlController,
                      style: GoogleFonts.inter(fontSize: 13, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'http://192.168.1.15:8000/api/v1',
                        labelText: 'Custom API URL',
                        labelStyle: GoogleFonts.inter(color: subtextColor, fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.inter(color: subtextColor)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final customUrl = selectedMode == 'custom' ? customUrlController.text.trim() : null;
                  await ApiConstants.setBackendMode(selectedMode, customUrl: customUrl);
                  if (ctx.mounted) Navigator.pop(ctx);
                  onUpdated?.call();
                },
                child: Text('Save & Apply', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    },
  );
}
