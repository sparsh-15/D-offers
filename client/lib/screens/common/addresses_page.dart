import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/utils/dialog_helper.dart';
import '../../services/auth_service.dart';
import '../../widgets/pincode_location_section.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
class _AP {
  static const canvas       = Color(0xFFF3F5F8);
  static const surface      = Color(0xFFFFFFFF);
  static const border       = Color(0xFFDDE4ED);
  static const accent       = Color(0xFFE88428);
  static const accentSoft   = Color(0xFFFBE7D6);
  static const textPrimary  = Color(0xFF102038);
  static const textSecondary= Color(0xFF334155);
  static const textMuted    = Color(0xFF5E6D82);
  static const white        = Color(0xFFFFFFFF);
}

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key, this.onSaved});
  final VoidCallback? onSaved;

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  bool _loading = true;
  bool _saving = false;
  bool _isLoadingPincode = false;
  late final TextEditingController _addressController;
  late final TextEditingController _pincodeController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  List<Map<String, dynamic>> _availableAreas = [];
  String? _selectedArea;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController();
    _pincodeController = TextEditingController();
    _cityController    = TextEditingController();
    _stateController   = TextEditingController();
    _pincodeController.addListener(_onPincodeChanged);
    _load();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _pincodeController.removeListener(_onPincodeChanged);
    _pincodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final user = await AuthService.instance.fetchCurrentUser();
      if (!mounted) return;
      setState(() {
        _addressController.text = user.address;
        _pincodeController.text = user.pincode;
        _cityController.text    = user.city;
        _stateController.text   = user.state;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await AuthService.instance.updateCurrentUser(
        address: _addressController.text.trim().isEmpty
            ? null : _addressController.text.trim(),
        pincode: _pincodeController.text.trim().isEmpty
            ? null : _pincodeController.text.trim(),
        city:    _cityController.text.trim().isEmpty
            ? null : _cityController.text.trim(),
        state:   _stateController.text.trim().isEmpty
            ? null : _stateController.text.trim(),
      );
      if (!mounted) return;
      widget.onSaved?.call();
      await _load();
      DialogHelper.showSuccessSnackBar(context, 'Address updated');
    } catch (e) {
      if (!mounted) return;
      DialogHelper.showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _onPincodeChanged() {
    final pincode = _pincodeController.text.trim();
    if (pincode.length == 6) {
      _lookupPincode(pincode);
    } else {
      setState(() { _availableAreas = []; _selectedArea = null; });
      _cityController.clear();
      _stateController.clear();
    }
  }

  Future<void> _lookupPincode(String pincode) async {
    setState(() => _isLoadingPincode = true);
    try {
      final result   = await AuthService.instance.lookupPincode(pincode);
      if (!mounted) return;
      final areas    = result['areas'] as List<Map<String, dynamic>>? ?? [];
      final state    = result['state']?.toString() ?? '';
      final district = result['district']?.toString() ?? '';
      setState(() {
        _stateController.text = state;
        _availableAreas = areas;
        _cityController.text = district;
        _selectedArea = areas.isNotEmpty ? areas[0]['name']?.toString() : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _availableAreas = []; _selectedArea = null; });
      _cityController.clear();
      _stateController.clear();
    } finally {
      if (mounted) setState(() => _isLoadingPincode = false);
    }
  }

  void _onAreaSelected(String? areaName) {
    if (areaName == null) return;
    setState(() => _selectedArea = areaName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AP.canvas,
      appBar: AppBar(
        backgroundColor: _AP.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: _AP.canvas,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: Color(0xFF334155)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'My Addresses',
          style: GoogleFonts.dmSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _AP.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _AP.accent),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Address card ────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                      decoration: BoxDecoration(
                        color: _AP.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: _AP.border, width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card header
                          Row(
                            children: [
                              Icon(Iconsax.home_2,
                                  color: _AP.accent, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Primary Address',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: _AP.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Form fields
                          PincodeLocationSection(
                            pincodeController: _pincodeController,
                            cityController: _cityController,
                            stateController: _stateController,
                            addressController: _addressController,
                            isLoadingPincode: _isLoadingPincode,
                            availableAreas: _availableAreas,
                            selectedArea: _selectedArea,
                            onAreaChanged: _onAreaSelected,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    // ── Save button ─────────────────────────────────────
                    SizedBox(
                      height: 58,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _AP.accent,
                          foregroundColor: _AP.white,
                          disabledBackgroundColor: _AP.border,
                          elevation: 0,
                          shape: const StadiumBorder(),
                          textStyle: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        icon: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: _AP.white),
                              )
                            : const Icon(Iconsax.save_2, size: 20),
                        label: Text(
                            _saving ? 'Saving...' : 'Save address'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
