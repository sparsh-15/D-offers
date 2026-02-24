import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/theme_helper.dart';
import '../../services/auth_service.dart';
import '../../widgets/pincode_location_section.dart';

/// My Addresses page – view and edit primary address (shared for Customer).
class AddressesPage extends StatefulWidget {
  const AddressesPage({
    super.key,
    this.onSaved,
  });

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
    _cityController = TextEditingController();
    _stateController = TextEditingController();
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
        _cityController.text = user.city;
        _stateController.text = user.state;
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
            ? null
            : _addressController.text.trim(),
        pincode: _pincodeController.text.trim().isEmpty
            ? null
            : _pincodeController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        state: _stateController.text.trim().isEmpty
            ? null
            : _stateController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: ThemeHelper.getBackgroundGradient(context),
      ),
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.transparent,
          elevation: 0,
          title: const Text('My Addresses'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.home_rounded,
                                      color: AppColors.primary),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Primary address',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
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
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(_saving ? 'Saving...' : 'Save address'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  void _onPincodeChanged() {
    final pincode = _pincodeController.text.trim();
    if (pincode.length == 6) {
      _lookupPincode(pincode);
    } else {
      setState(() {
        _availableAreas = [];
        _selectedArea = null;
      });
      _cityController.clear();
      _stateController.clear();
    }
  }

  Future<void> _lookupPincode(String pincode) async {
    setState(() => _isLoadingPincode = true);
    try {
      final result = await AuthService.instance.lookupPincode(pincode);
      if (!mounted) return;
      final areas = result['areas'] as List<Map<String, dynamic>>? ?? [];
      final state = result['state']?.toString() ?? '';
      final district = result['district']?.toString() ?? '';

      setState(() {
        _stateController.text = state;
        _availableAreas = areas;
        _cityController.text = district;
        _selectedArea = areas.isNotEmpty ? areas[0]['name']?.toString() : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _availableAreas = [];
        _selectedArea = null;
      });
      _cityController.clear();
      _stateController.clear();
    } finally {
      if (mounted) setState(() => _isLoadingPincode = false);
    }
  }

  void _onAreaSelected(String? areaName) {
    if (areaName == null) return;
    setState(() {
      _selectedArea = areaName;
    });
  }
}
