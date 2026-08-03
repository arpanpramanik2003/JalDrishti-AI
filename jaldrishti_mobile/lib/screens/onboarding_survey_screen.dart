import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/irrigation_provider.dart';
import '../models/user_model.dart';
import 'home_dashboard_screen.dart';

class OnboardingSurveyScreen extends StatefulWidget {
  const OnboardingSurveyScreen({super.key});

  @override
  State<OnboardingSurveyScreen> createState() => _OnboardingSurveyScreenState();
}

class _OnboardingSurveyScreenState extends State<OnboardingSurveyScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _areaController = TextEditingController(text: '2.5');

  String _selectedCrop = 'paddy_rice';
  String _selectedExperience = 'Intermediate';
  String _selectedLanguage = 'English';

  static const List<Map<String, String>> _allCropsAlphabetical = [
    {'id': 'banana', 'name': '🍌 Banana (কলা)'},
    {'id': 'cabbage', 'name': '🥬 Cabbage (বাঁধাকপি)'},
    {'id': 'chilli', 'name': '🌶️ Chilli / Pepper (লঙ্কা)'},
    {'id': 'cotton', 'name': '🧵 Cotton (তুলা)'},
    {'id': 'eggplant', 'name': '🍆 Eggplant / Brinjal (বেগুন)'},
    {'id': 'garlic', 'name': '🧄 Garlic (রসুন)'},
    {'id': 'groundnut', 'name': '🥜 Groundnut / Peanut (চীনাবাদাম)'},
    {'id': 'jute', 'name': '🌾 Jute (পাট)'},
    {'id': 'maize', 'name': '🌽 Maize / Corn (ভুট্টা)'},
    {'id': 'mango', 'name': '🥭 Mango Tree (আম)'},
    {'id': 'mustard', 'name': '🌼 Mustard (সরষে)'},
    {'id': 'onion', 'name': '🧅 Onion (পেঁয়াজ)'},
    {'id': 'paddy_rice', 'name': '🌾 Paddy Rice (ধান)'},
    {'id': 'potato', 'name': '🥔 Potato (আলু)'},
    {'id': 'pulses', 'name': '🫘 Pulses / Lentils (ডাল / মসুর)'},
    {'id': 'soybean', 'name': '🫛 Soybean (সয়াবিন)'},
    {'id': 'sugarcane', 'name': '🎋 Sugarcane (আখ)'},
    {'id': 'sunflower', 'name': '🌻 Sunflower (সূর্যমুখী)'},
    {'id': 'tea', 'name': '🍃 Tea Plantation (চা)'},
    {'id': 'tomato', 'name': '🍅 Tomato (টমেটো)'},
    {'id': 'wheat', 'name': '🌾 Wheat (গম)'},
  ];

  final List<String> _experiences = ['Beginner', 'Intermediate', 'Experienced'];
  final List<String> _languages = ['English', 'Bengali', 'Hindi'];

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user?.profile != null) {
      final p = auth.user!.profile!;
      _firstNameController.text = p.firstName;
      _lastNameController.text = p.lastName;
      _locationController.text = p.locationName;
      _areaController.text = p.farmAreaAcres.toString();
      _selectedCrop = p.interestedCrop;
      _selectedExperience = p.farmingExperience;
      _selectedLanguage = p.preferredLanguage;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IrrigationProvider>().fetchAvailableCrops();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _locationController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _submitSurvey() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final area = double.tryParse(_areaController.text) ?? 2.5;

    final profile = UserProfileModel(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      locationName: _locationController.text.trim(),
      latitude: 22.5726,
      longitude: 88.3639,
      farmAreaAcres: area,
      interestedCrop: _selectedCrop,
      farmingExperience: _selectedExperience,
      preferredLanguage: _selectedLanguage,
    );

    final success = await auth.updateProfile(profile);

    if (!mounted) return;

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
        (route) => false,
      );
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final irrigation = context.watch<IrrigationProvider>();

    final dynamicCrops = irrigation.availableCrops;
    final cropsList = dynamicCrops.isNotEmpty
        ? dynamicCrops.map((c) => {'id': c['id'] as String, 'name': c['name'] as String}).toList()
        : _allCropsAlphabetical;

    final validSelectedCrop = cropsList.any((c) => c['id'] == _selectedCrop)
        ? _selectedCrop
        : cropsList.first['id']!;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Text(
          'Farmer Profile & Survey',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to JalDrishti! 👋',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tell us about your farm so we can personalize AI recommendations.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 24),

              // Name Inputs
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      maxLength: 50,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s]")),
                      ],
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'First Name',
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        counterText: '',
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? 'Enter first name' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      maxLength: 50,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s]")),
                      ],
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Last Name',
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        counterText: '',
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Location Input
              TextFormField(
                controller: _locationController,
                maxLength: 100,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r"[<>'\\;]")),
                ],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Primary Farm Location / Village',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(LucideIcons.mapPin, color: Color(0xFF38BDF8)),
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Enter farm location' : null,
              ),
              const SizedBox(height: 16),

              // Area Size & Crop Selection
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _areaController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      maxLength: 8,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]')),
                      ],
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Farm Size (Acres)',
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(LucideIcons.ruler, color: Color(0xFF38BDF8)),
                        counterText: '',
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (val) =>
                          (val == null || double.tryParse(val) == null) ? 'Valid size' : null,
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: validSelectedCrop,
                      dropdownColor: const Color(0xFF1E293B),
                      isExpanded: true,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Primary Crop',
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      ),
                      items: cropsList.map((c) {
                        return DropdownMenuItem(
                          value: c['id'],
                          child: Text(c['name']!, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCrop = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Experience Dropdown
              DropdownButtonFormField<String>(
                value: _selectedExperience,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Farming Experience Level',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(LucideIcons.award, color: Color(0xFF38BDF8)),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _experiences.map((exp) {
                  return DropdownMenuItem(
                    value: exp,
                    child: Text(exp),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedExperience = val);
                },
              ),
              const SizedBox(height: 16),

              // Language Dropdown
              DropdownButtonFormField<String>(
                value: _selectedLanguage,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Preferred Language for AI Advisory',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(LucideIcons.languages, color: Color(0xFF38BDF8)),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _languages.map((lang) {
                  return DropdownMenuItem(
                    value: lang,
                    child: Text(lang),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedLanguage = val);
                },
              ),
              const SizedBox(height: 32),

              // Complete Profile Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _submitSurvey,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Complete Profile & Open Dashboard',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
