import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

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
    this.addressLabel = 'Address',
    this.pincodeValidator,
    this.cityValidator,
    this.areaValidator,
    this.stateValidator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: pincodeController,
          decoration: const InputDecoration(
            labelText: 'Pincode',
            hintText: '6-digit pincode',
            prefixIcon: Icon(Iconsax.location),
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: pincodeValidator,
        ),
        if (isLoadingPincode)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Looking up pincode...'),
              ],
            ),
          ),
        const SizedBox(height: 12),
        TextFormField(
          controller: cityController,
          decoration: const InputDecoration(
            labelText: 'City (Auto)',
            hintText: 'Auto-fetched from pincode',
            prefixIcon: Icon(Iconsax.building),
          ),
          enabled: false,
          validator: cityValidator,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: selectedArea,
          decoration: const InputDecoration(
            labelText: 'Area',
            hintText: 'Select area',
            prefixIcon: Icon(Iconsax.map_1),
          ),
          items: availableAreas.map((area) {
            final areaName = area['name']?.toString() ?? '';
            return DropdownMenuItem<String>(
              value: areaName,
              child: Text(areaName, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged:
              isLoadingPincode || availableAreas.isEmpty ? null : onAreaChanged,
          validator: areaValidator,
        ),
        if (availableAreas.isNotEmpty && !isLoadingPincode)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${availableAreas.length} areas found.'),
            ),
          ),
        const SizedBox(height: 12),
        TextFormField(
          controller: stateController,
          decoration: const InputDecoration(
            labelText: 'State (Auto)',
            hintText: 'Auto-fetched from pincode',
            prefixIcon: Icon(Iconsax.global),
          ),
          enabled: false,
          validator: stateValidator,
        ),
        if (showAddressField && addressController != null) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: addressController,
            decoration: InputDecoration(
              labelText: addressLabel,
              prefixIcon: const Icon(Iconsax.house),
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
