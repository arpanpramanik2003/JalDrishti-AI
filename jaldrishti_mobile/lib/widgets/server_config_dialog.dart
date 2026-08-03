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
        content: Text('Backend Server URL updated to: ${ApiConstants.baseUrl}'),
        backgroundColor: const Color(0xFF0284C7),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(LucideIcons.server, color: Color(0xFF38BDF8)),
          const SizedBox(width: 10),
          Text(
            'Server Configuration',
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
              'Select server environment or enter custom IP address for local backend testing:',
              style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 16),
            
            // Preset Options
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(LucideIcons.smartphone, size: 16, color: Color(0xFF38BDF8)),
                  label: const Text('Virtual Device (10.0.2.2)'),
                  backgroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Color(0xFF334155)),
                  labelStyle: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                  onPressed: () {
                    _urlController.text = 'http://10.0.2.2:8000/api/v1';
                  },
                ),
                ActionChip(
                  avatar: const Icon(LucideIcons.laptop, size: 16, color: Color(0xFF38BDF8)),
                  label: const Text('Localhost / USB (127.0.0.1)'),
                  backgroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Color(0xFF334155)),
                  labelStyle: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                  onPressed: () {
                    _urlController.text = 'http://127.0.0.1:8000/api/v1';
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // TextField
            TextField(
              controller: _urlController,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Backend Base URL or IP',
                labelStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                hintText: 'e.g. 192.168.1.100 or http://10.0.2.2:8000/api/v1',
                hintStyle: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                prefixIcon: const Icon(LucideIcons.link, color: Color(0xFF38BDF8), size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Text(
                '💡 Tip: For physical phone via USB, run:\nadb reverse tcp:8000 tcp:8000\nFor Wi-Fi, enter your PC\'s LAN IP (e.g. 192.168.x.x).',
                style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 11),
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
          child: Text('Save', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
