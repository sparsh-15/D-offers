import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

// ── Light palette ─────────────────────────────────────────────────────────────
class _PLS {
  static const fieldBg      = Color(0xFFF4F7FB);
  static const border       = Color(0xFFDDE4ED);
  static const borderFocus  = Color(0xFFE88428);
  static const accent       = Color(0xFFE88428);
  static const textPrimary  = Color(0xFF102038);
  static const textMuted    = Color(0xFF5E6D82);
  static const iconColor    = Color(0xFF707889);
  static const disabledText = Color(0xFF94A3B8);
}

class PincodeLocationSection extends StatelessWidget {
  final TextEditingController pincodeController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController? addressController;
  final bool isLoadingPincode;
  final List<Map<String, dynamic>> availableAreas;
  final String? selectedArea;
  final ValueChanged<String?>? onAreaChanged;
  final bool showAddressField;
  final String addressLabel;

  final String? Function(String?)? pincodeValidator;
  final String? Function(String?)? cityValidator;
  final String? Function(String?)? areaValidator;
  final String? Function(String?)? stateValidator;

  const PincodeLocationSection({
    super.key,
    required this.pincodeController,
    required this.cityController,
    required this.stateController,
    this.addressController,
    required this.isLoadingPincode,
    required this.availableAreas,
    required this.selectedArea,
    required this.onAreaChanged,
    this.showAddressField = true,
    this.addressLabel = 'Full Address',
    this.pincodeValidator,
    this.cityValidator,
    this.areaValidator,
    this.stateValidator,
  });

  InputDecoration _dec({
    required String label,
    required IconData icon,
    String? hint,
    String? counterText,
    bool alignLabelWithHint = false,
    bool enabled = true,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      counterText: counterText,
      alignLabelWithHint: alignLabelWithHint,
      labelStyle: GoogleFonts.dmSans(fontSize: 13, color: _PLS.textMuted),
      hintStyle: GoogleFonts.dmSans(fontSize: 15, color: _PLS.textMuted),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 10, right: 8),
        child: Icon(icon,
            color: enabled ? _PLS.iconColor : _PLS.disabledText, size: 20),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 44),
      filled: true,
      fillColor:
          enabled ? _PLS.fieldBg : _PLS.fieldBg.withValues(alpha: 0.6),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _PLS.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _PLS.borderFocus, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            BorderSide(color: _PLS.border.withValues(alpha: 0.6)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: Color(0xFFE24D69), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: Color(0xFFE24D69), width: 1.8),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _PLS.border),
      ),
    );
  }

  TextStyle get _inputStyle => GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: _PLS.textPrimary,
      );

  TextStyle get _disabledStyle => GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: _PLS.disabledText,
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _PLS.textMuted,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Pincode ──────────────────────────────────────────────────────────
        _label('Pincode'),
        TextFormField(
          controller: pincodeController,
          style: _inputStyle,
          decoration: _dec(
            label: 'Pincode',
            icon: Iconsax.location,
            hint: '6-digit pincode',
            counterText: '',
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: pincodeValidator,
        ),
        // Pincode counter + loading
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Row(
            children: [
              if (isLoadingPincode) ...[
                const SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _PLS.accent),
                ),
                const SizedBox(width: 6),
                Text('Looking up pincode...',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: _PLS.textMuted)),
              ],
              const Spacer(),
              Text(
                '${pincodeController.text.length}/6',
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: _PLS.textMuted,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── City + State row ─────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('City'),
                  TextFormField(
                    controller: cityController,
                    enabled: false,
                    style: _disabledStyle,
                    decoration: _dec(
                      label: 'City',
                      icon: Iconsax.building_3,
                      hint: 'Auto-filled',
                      enabled: false,
                    ),
                    validator: cityValidator,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('State'),
                  TextFormField(
                    controller: stateController,
                    enabled: false,
                    style: _disabledStyle,
                    decoration: _dec(
                      label: 'State',
                      icon: Iconsax.global,
                      hint: 'Auto-filled',
                      enabled: false,
                    ),
                    validator: stateValidator,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Area dropdown ────────────────────────────────────────────────────
        _label('Area'),
        DropdownButtonFormField<String>(
          value: selectedArea,
          isExpanded: true,
          dropdownColor: const Color(0xFFFFFFFF),
          style: _inputStyle,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: _PLS.iconColor),
          decoration: _dec(
            label: 'Area',
            icon: Iconsax.map_1,
            hint: 'Select area',
          ),
          items: availableAreas.map((area) {
            final areaName = area['name']?.toString() ?? '';
            return DropdownMenuItem<String>(
              value: areaName,
              child:
                  Text(areaName, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: isLoadingPincode || availableAreas.isEmpty
              ? null
              : onAreaChanged,
          validator: areaValidator,
        ),
        if (availableAreas.isNotEmpty && !isLoadingPincode)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${availableAreas.length} areas found.',
              style: GoogleFonts.dmSans(
                  fontSize: 12, color: _PLS.textMuted),
            ),
          ),

        // ── Full Address ─────────────────────────────────────────────────────
        if (showAddressField && addressController != null) ...[
          const SizedBox(height: 14),
          _label(addressLabel),
          TextFormField(
            controller: addressController,
            style: _inputStyle,
            decoration: _dec(
              label: addressLabel,
              icon: Iconsax.home_2,
              hint: 'Enter complete address',
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ],
    );
  }
}
