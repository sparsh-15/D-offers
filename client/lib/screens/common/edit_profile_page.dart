import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/utils/dialog_helper.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';

class _EP {
  static const canvas        = Color(0xFFF3F5F8);
  static const surface       = Color(0xFFFFFFFF);
  static const fieldBg       = Color(0xFFF4F7FB);
  static const border        = Color(0xFFDDE4ED);
  static const borderFocus   = Color(0xFFE88428);
  static const accent        = Color(0xFFE88428);
  static const textPrimary   = Color(0xFF102038);
  static const textMuted     = Color(0xFF5E6D82);
  static const textSecondary = Color(0xFF334155);
  static const iconColor     = Color(0xFF707889);
  static const disabledText  = Color(0xFF94A3B8);
  static const white         = Color(0xFFFFFFFF);
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, this.user, this.onSaved});
  final UserModel? user;
  final VoidCallback? onSaved;
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _pincodeController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _addressController;
  bool _saving = false;
  bool _isLoadingPincode = false;
  List<Map<String, dynamic>> _availableAreas = [];
  String? _selectedArea;

  @override
  void initState() {
    super.initState();
    final u = widget.user ?? AuthStore.currentUser;
    _nameController    = TextEditingController(text: u?.name ?? '');
    _pincodeController = TextEditingController(text: u?.pincode ?? '');
    _cityController    = TextEditingController(text: u?.city ?? '');
    _stateController   = TextEditingController(text: u?.state ?? '');
    _addressController = TextEditingController(text: u?.address ?? '');
    _pincodeController.addListener(_onPincodeChanged);
  }

  @override
  void dispose() {
    _pincodeController.removeListener(_onPincodeChanged);
    _nameController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _addressController.dispose();
    super.dispose();
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

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      DialogHelper.showErrorSnackBar(context, 'Name is required');
      return;
    }
    setState(() => _saving = true);
    try {
      await AuthService.instance.updateCurrentUser(
        name: name,
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        pincode: _pincodeController.text.trim().isEmpty ? null : _pincodeController.text.trim(),
        city:    _cityController.text.trim().isEmpty    ? null : _cityController.text.trim(),
        state:   _stateController.text.trim().isEmpty   ? null : _stateController.text.trim(),
      );
      if (!mounted) return;
      widget.onSaved?.call();
      DialogHelper.showSuccessSnackBar(context, 'Profile updated');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      DialogHelper.showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _EP.canvas,
      appBar: AppBar(
        backgroundColor: _EP.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: _EP.canvas,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _EP.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.dmSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _EP.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionCard(
                title: 'Personal Info',
                subtitle: 'Your display name shown across the app',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Full Name'),
                    _inputField(
                      controller: _nameController,
                      hint: 'Enter full name',
                      icon: Iconsax.user,
                      capitalization: TextCapitalization.words,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Location',
                subtitle: 'Used to show relevant offers near you',
                accentBorder: const Color(0xFFE6D8C8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Pincode'),
                    _inputField(
                      controller: _pincodeController,
                      hint: '6-digit pincode',
                      icon: Iconsax.location,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      counterText: '',
                    ),
                    const SizedBox(height: 4),
                    if (_isLoadingPincode)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: _EP.accent),
                            ),
                            const SizedBox(width: 8),
                            Text('Looking up pincode...',
                                style: GoogleFonts.dmSans(fontSize: 12, color: _EP.textMuted)),
                          ],
                        ),
                      )
                    else
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${_pincodeController.text.length}/6',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: _EP.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('City'),
                              _inputField(
                                controller: _cityController,
                                hint: 'City',
                                icon: Iconsax.building_3,
                                enabled: false,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('State'),
                              _inputField(
                                controller: _stateController,
                                hint: 'State',
                                icon: Iconsax.global,
                                enabled: false,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel('Area'),
                    DropdownButtonFormField<String>(
                      value: _selectedArea,
                      isExpanded: true,
                      dropdownColor: _EP.surface,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _EP.textPrimary,
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _EP.iconColor),
                      decoration: _decoration(hint: 'Select area', icon: Iconsax.location),
                      items: _availableAreas.map((area) {
                        final areaName = area['name']?.toString() ?? '';
                        return DropdownMenuItem<String>(
                          value: areaName,
                          child: Text(areaName, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: _isLoadingPincode || _availableAreas.isEmpty
                          ? null
                          : (v) { if (v != null) setState(() => _selectedArea = v); },
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel('Address'),
                    _inputField(
                      controller: _addressController,
                      hint: 'Enter full address',
                      icon: Iconsax.home_2,
                      maxLines: 3,
                      capitalization: TextCapitalization.sentences,
                      alignLabelWithHint: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _EP.accent,
                    foregroundColor: _EP.white,
                    disabledBackgroundColor: _EP.border,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _EP.white),
                        )
                      : const Icon(Icons.check_rounded, size: 20),
                  label: Text(_saving ? 'Saving...' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _EP.textMuted,
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool enabled = true,
    int maxLines = 1,
    int? maxLength,
    String? counterText,
    bool alignLabelWithHint = false,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      inputFormatters: inputFormatters,
      style: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: enabled ? _EP.textPrimary : _EP.disabledText,
      ),
      decoration: _decoration(
        hint: hint,
        icon: icon,
        counterText: counterText,
        alignLabelWithHint: alignLabelWithHint,
        enabled: enabled,
      ),
    );
  }

  InputDecoration _decoration({
    required String hint,
    required IconData icon,
    String? counterText,
    bool alignLabelWithHint = false,
    bool enabled = true,
  }) {
    return InputDecoration(
      hintText: hint,
      counterText: counterText,
      alignLabelWithHint: alignLabelWithHint,
      hintStyle: GoogleFonts.dmSans(fontSize: 15, color: _EP.textMuted),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 10, right: 8),
        child: Icon(icon, color: enabled ? _EP.iconColor : _EP.disabledText, size: 20),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 44),
      filled: true,
      fillColor: enabled ? _EP.fieldBg : _EP.fieldBg.withValues(alpha: 0.6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _EP.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _EP.borderFocus, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _EP.border.withValues(alpha: 0.6)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE24D69), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE24D69), width: 1.8),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.accentBorder,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Color? accentBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: _EP.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accentBorder ?? const Color(0xFFDDE4ED),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _EP.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.dmSans(fontSize: 13, color: _EP.textMuted),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
