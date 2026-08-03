import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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

  static const List<Map<String, String>> _fallbackCrops = [
    {'id': 'banana', 'name': '🍌 Banana (কলা)'},
    {'id': 'cabbage', 'name': '🥬 Cabbage (বাঁধাকপি)'},
    {'id': 'chilli', 'name': '🌶️ Chilli (লঙ্কা)'},
    {'id': 'cotton', 'name': '🧵 Cotton (তুলা)'},
    {'id': 'eggplant', 'name': '🍆 Eggplant / Brinjal (বেগুন)'},
    {'id': 'garlic', 'name': '🧄 Garlic (রসুন)'},
    {'id': 'groundnut', 'name': '🥜 Groundnut / Peanut (চীনাবাদাম)'},
    {'id': 'jute', 'name': '🧶 Jute (পাট)'},
    {'id': 'maize', 'name': '🌽 Maize / Corn (ভুট্টা)'},
    {'id': 'mango', 'name': '🥭 Mango Orchard (আম)'},
    {'id': 'mustard', 'name': '🟡 Mustard (সরিষা)'},
    {'id': 'onion', 'name': '🧅 Onion (পেঁয়াজ)'},
    {'id': 'paddy_rice', 'name': '🌾 Paddy Rice (ধান)'},
    {'id': 'potato', 'name': '🥔 Potato (আলু)'},
    {'id': 'pulses', 'name': '🫘 Pulses / Lentils (ডাল)'},
    {'id': 'soybean', 'name': '🫛 Soybean (সয়াবিন)'},
    {'id': 'sugarcane', 'name': '🎋 Sugarcane (আখ)'},
    {'id': 'sunflower', 'name': '🌻 Sunflower (সূর্যমুখী)'},
    {'id': 'tea', 'name': '🍃 Tea Plantation (চা)'},
    {'id': 'tomato', 'name': '🍅 Tomato (টমেটো)'},
    {'id': 'wheat', 'name': '🌾 Wheat (গম)'},
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.plotToEdit;
    _nameController = TextEditingController(text: p?.name ?? '');
    _locationNameController = TextEditingController(text: p?.locationName ?? 'Burdwan, WB');
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
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '📍 GPS Coordinates Updated: ${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)}',
          ),
          backgroundColor: const Color(0xFF0284C7),
        ),
      );
    }
  }

  void _savePlot() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final irrigation = context.read<IrrigationProvider>();
    final farmPlotProvider = context.read<FarmPlotProvider>();

    final area = double.tryParse(_areaController.text) ?? 2.5;
    final pumpHp = double.tryParse(_pumpHpController.text) ?? 5.0;

    final plotData = FarmPlotModel(
      id: widget.plotToEdit?.id ?? 0,
      userId: 0,
      name: _nameController.text.trim(),
      locationName: _locationNameController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      cropId: _selectedCrop,
      sowingDate: _sowingDateController.text.trim(),
      areaAcres: area,
      isPrimary: _isPrimary,
      pumpHp: pumpHp,
      pumpFlowLps: 5.0,
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
    final isEditing = widget.plotToEdit != null;
    final farmPlotProvider = context.watch<FarmPlotProvider>();
    final irrigationProvider = context.watch<IrrigationProvider>();

    final cropsList = irrigationProvider.availableCrops.isNotEmpty
        ? irrigationProvider.availableCrops
        : _fallbackCrops;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          isEditing ? 'Edit Farm Plot' : 'Add New Farm Plot',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
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
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),

              // Plot Name
              TextFormField(
                controller: _nameController,
                maxLength: 50,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Farm Plot Name',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(LucideIcons.sprout, color: Color(0xFF38BDF8)),
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter plot name' : null,
              ),
              const SizedBox(height: 16),

              // Location Name
              TextFormField(
                controller: _locationNameController,
                maxLength: 100,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Village / District / Location Name',
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
                    (val == null || val.trim().isEmpty) ? 'Please enter village or district name' : null,
              ),
              const SizedBox(height: 20),

              // Map GPS Selector Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GPS Pinpoint Coordinates',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF38BDF8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _openLocationPicker,
                          icon: const Icon(LucideIcons.mapPin, size: 16, color: Colors.white),
                          label: Text(
                            'Pick Map Pin',
                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedCrop,
                dropdownColor: const Color(0xFF1E293B),
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
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
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Sowing Date',
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(LucideIcons.calendar, color: Color(0xFF38BDF8)),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
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
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Area (Acres)',
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
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF38BDF8)),
              ),
              const SizedBox(height: 12),

              // Irrigation Method Dropdown
              Text('Irrigation System Method', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: _selectedIrrigationMethod,
                dropdownColor: const Color(0xFF1E293B),
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(LucideIcons.droplets, color: Color(0xFF38BDF8)),
                ),
                items: const [
                  DropdownMenuItem(value: 'drip', child: Text('💧 Drip Irrigation (90% Efficient)')),
                  DropdownMenuItem(value: 'sprinkler', child: Text('🌧️ Overhead Sprinkler (75% Efficient)')),
                  DropdownMenuItem(value: 'flood', child: Text('🌊 Surface / Flood (50% Efficient)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedIrrigationMethod = val);
                },
              ),
              const SizedBox(height: 16),

              // Soil Texture Dropdown
              Text('Soil Texture Preset', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: _selectedSoilType,
                dropdownColor: const Color(0xFF1E293B),
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(LucideIcons.layers, color: Color(0xFF38BDF8)),
                ),
                items: const [
                  DropdownMenuItem(value: 'sandy_loam', child: Text('🏜️ Sandy Loam (Fast Drainage)')),
                  DropdownMenuItem(value: 'loam', child: Text('🌱 Loam (Balanced Storage)')),
                  DropdownMenuItem(value: 'clay_loam', child: Text('🧱 Clay Loam (High Storage)')),
                  DropdownMenuItem(value: 'silty_clay', child: Text('🌾 Silty Clay (Very High Storage)')),
                  DropdownMenuItem(value: 'heavy_clay', child: Text('💧 Heavy Clay (Maximum Moisture)')),
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
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  counterText: '',
                  labelText: 'Water Pump Horsepower (HP)',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(LucideIcons.zap, color: Color(0xFF38BDF8)),
                  suffixText: 'HP',
                  suffixStyle: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),

              // Primary Plot Switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeTrackColor: const Color(0xFF0284C7),
                title: Text(
                  'Set as Primary Farm Plot',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Primary plot is loaded automatically when you open JalDrishti',
                  style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12),
                ),
                value: _isPrimary,
                onChanged: (val) => setState(() => _isPrimary = val),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: farmPlotProvider.isLoading ? null : _savePlot,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: farmPlotProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          isEditing ? 'Update Farm Plot Details' : 'Save & Register Farm Plot',
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
