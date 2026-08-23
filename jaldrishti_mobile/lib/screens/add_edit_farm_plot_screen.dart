import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/farm_plot_model.dart';
import '../providers/auth_provider.dart';
import '../providers/farm_plot_provider.dart';
import '../providers/irrigation_provider.dart';
import 'location_picker_screen.dart';

class AddEditFarmPlotScreen extends StatefulWidget {
  final FarmPlotModel? plotToEdit;

  const AddEditFarmPlotScreen({super.key, this.plotToEdit});

  @override
  State<AddEditFarmPlotScreen> createState() => _AddEditFarmPlotScreenState();
}

class _AddEditFarmPlotScreenState extends State<AddEditFarmPlotScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _locationNameController;
  late TextEditingController _areaController;
  late TextEditingController _sowingDateController;
  late TextEditingController _pumpHpController;

  double _latitude = 22.5726;
  double _longitude = 88.3639;
  String _selectedCrop = 'paddy_rice';
  bool _isPrimary = false;

  String _selectedIrrigationMethod = 'flood';
  String _selectedSoilType = 'clay_loam';
  bool _isLocating = false;
  
  // Mandatory GPS tracking
  bool _gpsVerified = false;
  bool _gpsError = false;

  static const List<Map<String, String>> _fallbackCrops = [
    {'id': 'banana', 'name': '🍌 Banana (কলা)'},
    {'id': 'black_gram', 'name': '🫘 Black Gram / Urad (মাষকলাই)'},
    {'id': 'cabbage', 'name': '🥬 Cabbage (বাঁধাকপি)'},
    {'id': 'cauliflower', 'name': '🥦 Cauliflower (ফুলকপি)'},
    {'id': 'chickpea', 'name': '🧆 Chickpea / Gram (ছোলা)'},
    {'id': 'chilli', 'name': '🌶️ Chilli / Pepper (লঙ্কা)'},
    {'id': 'cotton', 'name': '🧵 Cotton (তুলা)'},
    {'id': 'cucumber', 'name': '🥒 Cucumber / Gourd (শশা / লাউ)'},
    {'id': 'eggplant', 'name': '🍆 Eggplant / Brinjal (বেগুন)'},
    {'id': 'finger_millet', 'name': '🌾 Finger Millet / Ragi (রাগী)'},
    {'id': 'garlic', 'name': '🧄 Garlic (রসুন)'},
    {'id': 'ginger', 'name': '🫚 Ginger (আদা)'},
    {'id': 'green_gram', 'name': '🫛 Green Gram / Moong (মুগ ডাল)'},
    {'id': 'groundnut', 'name': '🥜 Groundnut / Peanut (চীনাবাদাম)'},
    {'id': 'jute', 'name': '🧶 Jute (পাট)'},
    {'id': 'maize', 'name': '🌽 Maize / Corn (ভুট্টা)'},
    {'id': 'mango', 'name': '🥭 Mango Orchard (আম)'},
    {'id': 'mustard', 'name': '🟡 Mustard / Sarson (সরষে)'},
    {'id': 'okra', 'name': '🫛 Okra / Lady Finger (ঢ্যাঁড়শ)'},
    {'id': 'onion', 'name': '🧅 Onion (পেঁয়াজ)'},
    {'id': 'paddy_rice', 'name': '🌾 Paddy Rice (ধান)'},
    {'id': 'papaya', 'name': '🍈 Papaya (পেঁপে)'},
    {'id': 'pearl_millet', 'name': '🌾 Pearl Millet / Bajra (বাজরা)'},
    {'id': 'potato', 'name': '🥔 Potato (আলু)'},
    {'id': 'pulses', 'name': '🫘 Pulses / Lentils (ডাল)'},
    {'id': 'sesame', 'name': '🌱 Sesame / Til (তিল)'},
    {'id': 'sorghum', 'name': '🌾 Sorghum / Jowar (জোয়ার)'},
    {'id': 'soybean', 'name': '🫛 Soybean (সয়াবিন)'},
    {'id': 'sugarcane', 'name': '🎋 Sugarcane (আখ)'},
    {'id': 'sunflower', 'name': '🌻 Sunflower (সূর্যমুখী)'},
    {'id': 'tea', 'name': '🍃 Tea Plantation (চা)'},
    {'id': 'tobacco', 'name': '🍂 Tobacco (তামাক)'},
    {'id': 'tomato', 'name': '🍅 Tomato (টমেটো)'},
    {'id': 'turmeric', 'name': '🟡 Turmeric (হলুদ)'},
    {'id': 'watermelon', 'name': '🍉 Watermelon (তরমুজ)'},
    {'id': 'wheat', 'name': '🌾 Wheat (গম)'},
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.plotToEdit;
    _nameController = TextEditingController(text: p?.name ?? '');
    _locationNameController = TextEditingController(text: p?.locationName ?? '');
    _areaController = TextEditingController(text: p?.areaAcres.toString() ?? '2.5');
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    _sowingDateController = TextEditingController(text: p?.sowingDate ?? todayStr);
    _pumpHpController = TextEditingController(text: p?.pumpHp.toString() ?? '5.0');

    if (p != null) {
      _latitude = p.latitude;
      _longitude = p.longitude;
      _selectedCrop = p.cropId;
      _isPrimary = p.isPrimary;
      _selectedIrrigationMethod = p.irrigationMethod;
      _selectedSoilType = p.soilType;
      _gpsVerified = true; // Existing plot already has saved coordinates
    } else {
      // Auto-detect live GPS location on new plot creation
      _fetchCurrentGps();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IrrigationProvider>().fetchAvailableCrops();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationNameController.dispose();
    _areaController.dispose();
    _sowingDateController.dispose();
    _pumpHpController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentGps() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 6),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }

      if (pos != null && mounted) {
        setState(() {
          _latitude = pos!.latitude;
          _longitude = pos.longitude;
          _gpsVerified = true;
          _gpsError = false;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _openLocationPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitude = result['latitude'] ?? _latitude;
        _longitude = result['longitude'] ?? _longitude;
        _gpsVerified = true;
        _gpsError = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '📍 Live GPS Coordinates Confirmed: ${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)}',
          ),
          backgroundColor: const Color(0xFF0284C7),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _savePlot() async {
    if (!_formKey.currentState!.validate()) return;

    // MANDATORY GPS PINPOINT CHECK
    if (!_gpsVerified) {
      setState(() => _gpsError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.alertTriangle, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Action Required: Please tap "Map Pin" to confirm exact plot location coordinates for AI weather calculations.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final farmPlotProvider = context.read<FarmPlotProvider>();
    final auth = context.read<AuthProvider>();
    final irrigation = context.read<IrrigationProvider>();

    final plotData = FarmPlotModel(
      id: widget.plotToEdit?.id ?? 0,
      userId: widget.plotToEdit?.userId ?? auth.user?.id ?? 0,
      name: _nameController.text.trim(),
      cropId: _selectedCrop,
      locationName: _locationNameController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      areaAcres: double.tryParse(_areaController.text) ?? 2.5,
      sowingDate: _sowingDateController.text,
      isPrimary: _isPrimary,
      pumpHp: double.tryParse(_pumpHpController.text) ?? 5.0,
      irrigationMethod: _selectedIrrigationMethod,
      soilType: _selectedSoilType,
    );

    bool success;
    if (widget.plotToEdit == null) {
      success = await farmPlotProvider.createPlot(
        auth: auth,
        irrigation: irrigation,
        plotData: plotData,
      );
    } else {
      success = await farmPlotProvider.updatePlot(
        auth: auth,
        irrigation: irrigation,
        plotId: widget.plotToEdit!.id,
        plotData: plotData,
      );
    }

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    } else if (farmPlotProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(farmPlotProvider.errorMessage!), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final inputBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final hintColor = isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8);
    final primaryColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);

    final isEditing = widget.plotToEdit != null;
    final farmPlotProvider = context.watch<FarmPlotProvider>();
    final irrigationProvider = context.watch<IrrigationProvider>();

    final cropsList = irrigationProvider.availableCrops.isNotEmpty
        ? irrigationProvider.availableCrops
        : _fallbackCrops;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        title: Text(
          isEditing ? 'Edit Farm Plot' : 'Add New Farm Plot',
          style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plot Information',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 16),

              // Plot Name
              TextFormField(
                controller: _nameController,
                maxLength: 50,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Farm Plot Name',
                  labelStyle: TextStyle(color: subtextColor),
                  hintText: 'e.g. North Paddy Field',
                  hintStyle: TextStyle(color: hintColor, fontSize: 13),
                  prefixIcon: Icon(LucideIcons.sprout, color: primaryColor),
                  counterText: '',
                  filled: true,
                  fillColor: inputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 1.5),
                  ),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter plot name' : null,
              ),
              const SizedBox(height: 16),

              // Location Name
              TextFormField(
                controller: _locationNameController,
                maxLength: 100,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Village / District / Location Name',
                  labelStyle: TextStyle(color: subtextColor),
                  hintText: 'e.g. Burdwan, West Bengal or Village Name',
                  hintStyle: TextStyle(color: hintColor, fontSize: 13),
                  prefixIcon: Icon(LucideIcons.mapPin, color: primaryColor),
                  counterText: '',
                  filled: true,
                  fillColor: inputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 1.5),
                  ),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Please enter village or district name' : null,
              ),
              const SizedBox(height: 20),

              // Map GPS Selector Card (FIXED OVERFLOW & MANDATORY VALIDATION)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _gpsError ? const Color(0xFFEF4444) : borderColor,
                    width: _gpsError ? 1.8 : 1.0,
                  ),
                  boxShadow: _gpsError
                      ? [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                            blurRadius: 10,
                          )
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'GPS Coordinates',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: _gpsError ? const Color(0xFFEF4444) : subtextColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Text(
                                    ' *',
                                    style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _gpsVerified
                                          ? const Color(0xFF10B981).withValues(alpha: 0.18)
                                          : const Color(0xFFF59E0B).withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _gpsVerified ? 'SET' : 'REQUIRED',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: _gpsVerified ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              _isLocating
                                  ? Row(
                                      children: [
                                        SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Acquiring live GPS...',
                                          style: GoogleFonts.inter(fontSize: 12, color: primaryColor),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      '${_latitude.toStringAsFixed(4)}° N, ${_longitude.toStringAsFixed(4)}° E',
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _openLocationPicker,
                          icon: const Icon(LucideIcons.mapPin, size: 14, color: Colors.white),
                          label: Text(
                            'Map Pin',
                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _gpsError ? const Color(0xFFEF4444) : const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Crop Dropdown
              Text(
                'Select Crop',
                style: GoogleFonts.outfit(color: subtextColor, fontSize: 13),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedCrop,
                isExpanded: true,
                dropdownColor: cardBg,
                style: GoogleFonts.outfit(color: textColor, fontSize: 15),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: inputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                items: cropsList.map((c) {
                  return DropdownMenuItem<String>(
                    value: c['id'].toString(),
                    child: Text(
                      c['name'].toString(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCrop = val);
                },
              ),
              const SizedBox(height: 16),

              // Sowing Date & Land Area
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sowingDateController,
                      readOnly: true,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Sowing Date',
                        labelStyle: TextStyle(color: subtextColor),
                        prefixIcon: Icon(LucideIcons.calendar, color: primaryColor),
                        filled: true,
                        fillColor: inputBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 1.5),
                        ),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.tryParse(_sowingDateController.text) ?? DateTime.now(),
                          firstDate: DateTime(2025),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _sowingDateController.text =
                                "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _areaController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      maxLength: 8,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]')),
                      ],
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Area (Acres)',
                        labelStyle: TextStyle(color: subtextColor),
                        prefixIcon: Icon(LucideIcons.ruler, color: primaryColor),
                        counterText: '',
                        filled: true,
                        fillColor: inputBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 1.5),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || double.tryParse(val) == null) {
                          return 'Enter valid acres';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Practical Production Controls: Irrigation Method & Soil Type & Pump HP
              Text(
                'Irrigation & Soil Engineering Settings',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              const SizedBox(height: 12),

              // Irrigation Method Dropdown
              Text('Irrigation System Method', style: GoogleFonts.inter(color: subtextColor, fontSize: 12)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                initialValue: _selectedIrrigationMethod,
                isExpanded: true,
                dropdownColor: cardBg,
                style: GoogleFonts.outfit(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: inputBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 1.5)),
                  prefixIcon: Icon(LucideIcons.droplets, color: primaryColor),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'drip',
                    child: Text('💧 Drip System (90% Eff)', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'sprinkler',
                    child: Text('🌧️ Overhead Sprinkler (75% Eff)', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'flood',
                    child: Text('🌊 Surface / Flood (50% Eff)', overflow: TextOverflow.ellipsis),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedIrrigationMethod = val);
                },
              ),
              const SizedBox(height: 16),

              // Soil Texture Dropdown
              Text('Soil Texture Preset', style: GoogleFonts.inter(color: subtextColor, fontSize: 12)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                initialValue: _selectedSoilType,
                isExpanded: true,
                dropdownColor: cardBg,
                style: GoogleFonts.outfit(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: inputBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 1.5)),
                  prefixIcon: Icon(LucideIcons.layers, color: primaryColor),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'sandy_loam',
                    child: Text('🏜️ Sandy Loam (Fast Drainage)', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'loam',
                    child: Text('🌱 Loam (Balanced Storage)', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'clay_loam',
                    child: Text('🧱 Clay Loam (High Storage)', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'silty_clay',
                    child: Text('🌾 Silty Clay (Very High Storage)', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'heavy_clay',
                    child: Text('💧 Heavy Clay (Max Moisture)', overflow: TextOverflow.ellipsis),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSoilType = val);
                },
              ),
              const SizedBox(height: 16),

              // Pump Specs (HP)
              TextFormField(
                controller: _pumpHpController,
                maxLength: 4,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]')),
                ],
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  counterText: '',
                  labelText: 'Water Pump Horsepower (HP)',
                  labelStyle: TextStyle(color: subtextColor),
                  prefixIcon: Icon(LucideIcons.zap, color: primaryColor),
                  suffixText: 'HP',
                  suffixStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: inputBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 1.5)),
                ),
              ),
              const SizedBox(height: 20),

              // Set as Primary Switch Card (FIXED 18px OVERFLOW)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Set as Primary Farm Plot',
                            style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Default plot loaded on app dashboard launch',
                            style: GoogleFonts.inter(color: subtextColor, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _isPrimary,
                      activeThumbColor: primaryColor,
                      onChanged: (val) => setState(() => _isPrimary = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: farmPlotProvider.isLoading ? null : _savePlot,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: farmPlotProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEditing ? 'Save Changes' : 'Create Farm Plot',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
