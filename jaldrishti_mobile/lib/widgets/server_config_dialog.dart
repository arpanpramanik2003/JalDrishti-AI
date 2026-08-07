import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/constants/api_constants.dart';

class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const ServerConfigDialog(),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ApiConstants.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _save(String url) async {
    await ApiConstants.setBaseUrl(url);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Server URL set to: ${ApiConstants.baseUrl}'),
        backgroundColor: const Color(0xFF0284C7),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _reset() async {
    await ApiConstants.resetToDefault();
    if (!mounted) return;
    _urlController.text = ApiConstants.baseUrl;
    setState(() {});
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Server URL reset to default: ${ApiConstants.baseUrl}'),
        backgroundColor: const Color(0xFF0284C7),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF131B2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(LucideIcons.server, color: Color(0xFF38BDF8), size: 22),
          const SizedBox(width: 10),
          Text(
            'Server Connection',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
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
              'Select your connection mode or enter custom backend URL:',
              style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 14),
            
            // Preset Options
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(LucideIcons.usb, size: 15, color: Color(0xFF38BDF8)),
                  label: const Text('USB Cable (127.0.0.1)'),
                  backgroundColor: const Color(0xFF090D16),
                  side: const BorderSide(color: Color(0xFF0284C7)),
                  labelStyle: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  onPressed: () {
                    _urlController.text = 'http://127.0.0.1:8000/api/v1';
                  },
                ),
                ActionChip(
                  avatar: const Icon(LucideIcons.wifi, size: 15, color: Color(0xFF38BDF8)),
                  label: const Text('Wi-Fi (10.249.147.69)'),
                  backgroundColor: const Color(0xFF090D16),
                  side: const BorderSide(color: Color(0xFF22304A)),
                  labelStyle: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  onPressed: () {
                    _urlController.text = 'http://10.249.147.69:8000/api/v1';
                  },
                ),
                ActionChip(
                  avatar: const Icon(LucideIcons.smartphone, size: 15, color: Color(0xFF38BDF8)),
                  label: const Text('Emulator (10.0.2.2)'),
                  backgroundColor: const Color(0xFF090D16),
                  side: const BorderSide(color: Color(0xFF22304A)),
                  labelStyle: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  onPressed: () {
                    _urlController.text = 'http://10.0.2.2:8000/api/v1';
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // TextField
            TextField(
              controller: _urlController,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Backend Base URL',
                labelStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                hintText: 'e.g. http://127.0.0.1:8000/api/v1',
                hintStyle: GoogleFonts.inter(color: const Color(0xFF475569), fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF090D16),
                prefixIcon: const Icon(LucideIcons.link, color: Color(0xFF38BDF8), size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF22304A)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF22304A)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF090D16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.checkCircle2, size: 14, color: Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      Text(
                        'USB Reverse Tunnel Active! (Port 8000)',
                        style: GoogleFonts.inter(color: const Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '1. Select `USB Cable (127.0.0.1)` preset above.\n'
                    '2. Tap `Save & Apply` to instantly connect your USB phone to the local FastAPI backend!',
                    style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _reset,
          child: Text('Reset Default', style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
        ),
        ElevatedButton(
          onPressed: () => _save(_urlController.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0284C7),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text('Save & Apply', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
