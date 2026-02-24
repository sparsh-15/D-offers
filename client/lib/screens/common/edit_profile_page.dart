import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/theme_helper.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';
import '../../widgets/pincode_location_section.dart';

/// Shared Edit Profile page for Customer and Admin (user name, pincode, address).
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    this.user,
    this.onSaved,
  });

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
    _nameController = TextEditingController(text: u?.name ?? '');
    _pincodeController = TextEditingController(text: u?.pincode ?? '');
    _cityController = TextEditingController(text: u?.city ?? '');
    _stateController = TextEditingController(text: u?.state ?? '');
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
      if (mounted) {
        setState(() => _isLoadingPincode = false);
      }
    }
  }

  void _onAreaSelected(String? areaName) {
    if (areaName == null) return;
    setState(() {
      _selectedArea = areaName;
    });
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
    return Container(
      decoration: BoxDecoration(
        gradient: ThemeHelper.getBackgroundGradient(context),
      ),
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.transparent,
          elevation: 0,
          title: const Text('Edit Profile'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                  textCapitalization: TextCapitalization.words,
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
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_saving ? 'Saving...' : 'Save changes'),
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
}
