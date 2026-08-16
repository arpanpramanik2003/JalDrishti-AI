import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/farm_plot_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<String> _getSuggestions(String lang) {
    if (lang == 'Bengali') {
      return const [
        "🧪 ধানে কান্ড পচা ও মাজরা পোকা দমন করার উপায় কী?",
        "🌧️ আজ আমার ক্ষেতে কখন সেচ দেওয়া উচিত?",
        "🧪 আলুর জন্য সঠিক N-P-K সারের প্রয়োগ মাত্রা কত?",
        "🌾 প্রাকৃতিক উপায়ে ফসলের ফলন বাড়াব কীভাবে?",
      ];
    } else if (lang == 'Hindi') {
      return const [
        "🧪 धान में तना छेदक (Stem Borer) कीट नियंत्रण कैसे करें?",
        "🌧️ आज मुझे खेत में सिंचाई कब करनी चाहिए?",
        "🧪 आलू के लिए सही N-P-K उर्वरक की मात्रा क्या है?",
        "🌾 प्राकृतिक तरीके से फसल की पैदावार कैसे बढ़ाएं?",
      ];
    }
    return const [
      "🧪 How to control Stem Borer in Paddy?",
      "🌧️ When should I irrigate my field today?",
      "🧪 Best N-P-K fertilizer dosage for Potato?",
      "🌾 How to increase crop yield naturally?",
    ];
  }

  String _getGreeting(String lang, String farmerName) {
    if (lang == 'Bengali') return 'নমস্কার $farmerName! 👋';
    if (lang == 'Hindi') return 'नमस्ते $farmerName! 👋';
    return 'Hello $farmerName! 👋';
  }

  String _getIntroSubtitle(String lang, String locationName) {
    if (lang == 'Bengali') {
      return 'আমি আপনার জলসাথী AI সহকারী। $locationName অঞ্চলে ধানের পোকা দমন, সারের মাত্রা বা সেচ সংক্রান্ত প্রশ্ন করুন!';
    } else if (lang == 'Hindi') {
      return 'मैं आपका जलसाथी AI सहायक हूँ। $locationName क्षेत्र में फ़सल कीट नियंत्रण, खाद की मात्रा या सिंचाई की जानकारी पूछें!';
    }
    return 'I am your JalSathi AI companion. Ask me anything about crop diseases, chemical dosages, or irrigation schedules for $locationName!';
  }

  String _getSuggestionHeader(String lang) {
    if (lang == 'Bengali') return '💡 দ্রুত পরামর্শমূলক প্রশ্নসমূহ:';
    if (lang == 'Hindi') return '💡 त्वरित सुझाव प्रश्न:';
    return '💡 Quick Suggestion Questions:';
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendQuery(String text) {
    final queryText = text.trim();
    if (queryText.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final farmPlotProvider = context.read<FarmPlotProvider>();
    final chatProvider = context.read<ChatProvider>();

    // Stop speech mic listening if active
    if (chatProvider.isListening) {
      chatProvider.stopListening();
    }

    final user = auth.user;
    final profile = user?.profile;
    final activePlot = farmPlotProvider.selectedPlot;

    final farmerName = profile?.firstName ?? user?.username;
    final locationName = activePlot?.locationName ?? profile?.locationName;
    final currentCrop = activePlot?.cropId ?? profile?.interestedCrop;
    final areaAcres = activePlot?.areaAcres ?? profile?.farmAreaAcres;

    // Clear input field immediately
    _controller.clear();

    chatProvider.sendMessage(
      text: queryText,
      authToken: auth.token,
      farmerName: farmerName,
      locationName: locationName,
      currentCrop: currentCrop,
      farmAreaAcres: areaAcres,
      latitude: activePlot?.latitude,
      longitude: activePlot?.longitude,
    );

    // Smooth scroll to latest message (reverse ListView)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final farmPlotProvider = context.watch<FarmPlotProvider>();
    final chatProvider = context.watch<ChatProvider>();

    final user = auth.user;
    final profile = user?.profile;
    final activePlot = farmPlotProvider.selectedPlot;

    final farmerName = profile?.firstName ?? user?.username ?? "Farmer";
    final locationName = activePlot?.locationName ?? profile?.locationName ?? "Local Region";
    final cropName = (activePlot?.cropId ?? profile?.interestedCrop ?? "Paddy Rice").replaceAll('_', ' ').toUpperCase();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final appBarBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
    final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: appBarBg,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'JalSathi AI Assistant 🌾',
              style: GoogleFonts.outfit(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Personalized Agronomy Advisory',
              style: GoogleFonts.inter(color: subtextColor, fontSize: 11),
            ),
          ],
        ),
        actions: [
          // Language Dropdown Selector
          DropdownButton<String>(
            value: chatProvider.selectedLanguage,
            underline: const SizedBox(),
            dropdownColor: appBarBg,
            style: GoogleFonts.inter(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
            icon: Icon(LucideIcons.languages, color: primaryColor, size: 18),
            items: const [
              DropdownMenuItem(value: 'English', child: Text(' English')),
              DropdownMenuItem(value: 'Bengali', child: Text(' বাংলা')),
              DropdownMenuItem(value: 'Hindi', child: Text(' हिंदी')),
            ],
            onChanged: (lang) {
              if (lang != null) chatProvider.setLanguage(lang);
            },
          ),
          IconButton(
            icon: Icon(LucideIcons.trash2, color: subtextColor, size: 18),
            onPressed: () => chatProvider.clearChat(),
            tooltip: 'Clear Chat History',
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // 1. Logged-In Farmer Active Context Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: appBarBg,
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.userCheck, size: 14, color: primaryColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Farmer: $farmerName • 📍 $locationName • 🌾 $cropName',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 11, color: subtextColor, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Chat Messages Area
            Expanded(
              child: chatProvider.messages.isEmpty
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 30),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: primaryColor, width: 2),
                            ),
                            child: Icon(LucideIcons.bot, size: 48, color: primaryColor),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _getGreeting(chatProvider.selectedLanguage, farmerName),
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _getIntroSubtitle(chatProvider.selectedLanguage, locationName),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 13, color: subtextColor),
                          ),
                          const SizedBox(height: 28),

                          Text(
                            _getSuggestionHeader(chatProvider.selectedLanguage),
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: primaryColor),
                          ),
                          const SizedBox(height: 12),
                          ..._getSuggestions(chatProvider.selectedLanguage).map((suggestion) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: InkWell(
                                  onTap: () => _sendQuery(suggestion),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            suggestion,
                                            style: GoogleFonts.inter(fontSize: 13, color: textColor),
                                          ),
                                        ),
                                        Icon(LucideIcons.arrowRight, size: 14, color: primaryColor),
                                      ],
                                    ),
                                  ),
                                ),
                              )),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: chatProvider.messages.length,
                      itemBuilder: (context, index) {
                        final reversedMessages = chatProvider.messages.reversed.toList();
                        return ChatBubble(message: reversedMessages[index]);
                      },
                    ),
            ),

            // 3. Typing Indicator
            if (chatProvider.isSending)
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'JalSathi AI is analyzing agronomic data...',
                      style: GoogleFonts.inter(fontSize: 12, color: subtextColor),
                    ),
                  ],
                ),
              ),

            // 4. Active Listening Voice Indicator Banner (Overflow Fixed with Flexible & Ellipsis)
            if (chatProvider.isListening)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '🎙️ Listening in ${chatProvider.selectedLanguage}... Speak now!',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 5. Input Text Box & Voice Mic Button
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: appBarBg,
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Microphone STT Button with Motion Decibel Animation
                    _AudioPulsingMicButton(
                      isListening: chatProvider.isListening,
                      soundLevel: chatProvider.soundLevel,
                      primaryColor: primaryColor,
                      onPressed: () {
                        if (chatProvider.isListening) {
                          chatProvider.stopListening();
                        } else {
                          chatProvider.startListening((speechText) {
                            setState(() {
                              _controller.text = speechText;
                              _controller.selection = TextSelection.fromPosition(
                                TextPosition(offset: _controller.text.length),
                              );
                            });
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 8),

                    Expanded(
                      child: TextField(
                        controller: _controller,
                        maxLength: 500,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: chatProvider.selectedLanguage == 'Bengali'
                              ? 'ফসল, রোগ বা সার সম্পর্কিত প্রশ্ন বলুন বা লিখুন...'
                              : chatProvider.selectedLanguage == 'Hindi'
                                  ? 'फ़सल, बीमारी या खाद के बारे में बोलें या लिखें...'
                                  : 'Speak or type crop care & disease questions...',
                          hintStyle: GoogleFonts.inter(color: subtextColor, fontSize: 13),
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          fillColor: inputBg,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (text) => _sendQuery(text),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: const Color(0xFF0284C7),
                      child: IconButton(
                        icon: const Icon(LucideIcons.send, color: Colors.white, size: 18),
                        onPressed: () => _sendQuery(_controller.text),
                      ),
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

/// Animated Microphone Button that scales & pulses dynamically based on speech audio decibels
class _AudioPulsingMicButton extends StatefulWidget {
  final bool isListening;
  final double soundLevel;
  final Color primaryColor;
  final VoidCallback onPressed;

  const _AudioPulsingMicButton({
    required this.isListening,
    required this.soundLevel,
    required this.primaryColor,
    required this.onPressed,
  });

  @override
  State<_AudioPulsingMicButton> createState() => _AudioPulsingMicButtonState();
}

class _AudioPulsingMicButtonState extends State<_AudioPulsingMicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isListening) {
      return CircleAvatar(
        backgroundColor: widget.primaryColor.withValues(alpha: 0.15),
        child: IconButton(
          icon: Icon(LucideIcons.mic, color: widget.primaryColor, size: 20),
          onPressed: widget.onPressed,
          tooltip: 'Voice Input (Speech-to-Text)',
        ),
      );
    }

    // Normalize audio decibel sound level (range ~ -2.0 to +10.0) into a scale factor
    final normLevel = ((widget.soundLevel.abs()) % 10.0) / 10.0;
    final decibelScale = 1.0 + (normLevel * 0.3);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulseScale = 1.0 + (_controller.value * 0.12) + (normLevel * 0.18);
        return Transform.scale(
          scale: decibelScale,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.35 * _controller.value + 0.15),
                  blurRadius: 10 * pulseScale,
                  spreadRadius: 3 * pulseScale,
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: const Color(0xFFEF4444),
              child: IconButton(
                icon: const Icon(LucideIcons.micOff, color: Colors.white, size: 20),
                onPressed: widget.onPressed,
                tooltip: 'Stop Voice Input',
              ),
            ),
          ),
        );
      },
    );
  }
}