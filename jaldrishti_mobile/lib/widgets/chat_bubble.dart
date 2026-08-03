import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/chat_message.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final botBubbleBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final botBorderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final botTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final botStrongColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF0284C7) : botBubbleBg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: Border.all(
            color: isUser ? const Color(0xFF38BDF8) : botBorderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.bot, size: 16, color: botStrongColor),
                  const SizedBox(width: 6),
                  Text(
                    'JalSathi AI 🌾',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: botStrongColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Markdown rendering for bold text (**bold**), lists (•), etc.
            MarkdownBody(
              data: message.text,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.inter(
                  fontSize: 14,
                  color: isUser ? Colors.white : botTextColor,
                  height: 1.45,
                ),
                strong: GoogleFonts.inter(
                  fontSize: 14,
                  color: isUser ? Colors.white : botStrongColor,
                  fontWeight: FontWeight.bold,
                ),
                listBullet: GoogleFonts.inter(
                  fontSize: 14,
                  color: isUser ? Colors.white : botTextColor,
                ),
                code: GoogleFonts.inter(
                  backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  color: botStrongColor,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 6),

            Text(
              DateFormat('hh:mm a').format(message.timestamp),
              style: GoogleFonts.inter(
                fontSize: 10,
                color: isUser ? Colors.white70 : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}