import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/dialog_helper.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F4F6),
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color(0xFF1F2A3D),
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF334155)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionCard(
                title: 'PERSONAL INFO',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Full Name'),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(
                        fontSize: 17,
                        color: Color(0xFF1F2A3D),
                      ),
                      decoration: _inputDecoration(
                        hintText: 'Enter full name',
                        prefixIcon: Iconsax.user,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildSectionCard(
                title: 'LOCATION',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Pincode'),
                    TextField(
                      controller: _pincodeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(
                        fontSize: 17,
                        color: Color(0xFF1F2A3D),
                      ),
                      decoration: _inputDecoration(
                        hintText: '6-digit pincode',
                        prefixIcon: Iconsax.location,
                        counterText: '',
                      ),
                    ),
                    if (_isLoadingPincode)
                      const Padding(
                        padding: EdgeInsets.only(top: 2, bottom: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Looking up pincode...',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${_pincodeController.text.length}/6',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('City'),
                              TextField(
                                controller: _cityController,
                                enabled: false,
                                style: const TextStyle(
                                  fontSize: 17,
                                  color: Color(0xFF475569),
                                ),
                                decoration: _inputDecoration(
                                  hintText: 'City',
                                  prefixIcon: Iconsax.building_3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('State'),
                              TextField(
                                controller: _stateController,
                                enabled: false,
                                style: const TextStyle(
                                  fontSize: 17,
                                  color: Color(0xFF475569),
                                ),
                                decoration: _inputDecoration(
                                  hintText: 'State',
                                  prefixIcon: Iconsax.global,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildFieldLabel('Area'),
                    DropdownButtonFormField<String>(
                      value: _selectedArea,
                      isExpanded: true,
                      style: const TextStyle(
                        color: Color(0xFF1F2A3D),
                        fontSize: 16,
                      ),
                      decoration: _inputDecoration(
                        hintText: 'Select area',
                        prefixIcon: Iconsax.location,
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF6B7280)),
                      items: _availableAreas.map((area) {
                        final areaName = area['name']?.toString() ?? '';
                        return DropdownMenuItem<String>(
                          value: areaName,
                          child: Text(
                            areaName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _isLoadingPincode || _availableAreas.isEmpty
                          ? null
                          : _onAreaSelected,
                    ),
                    const SizedBox(height: 12),
                    _buildFieldLabel('Address'),
                    TextField(
                      controller: _addressController,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(
                        fontSize: 17,
                        color: Color(0xFF1F2A3D),
                      ),
                      decoration: _inputDecoration(
                        hintText: 'Enter full address',
                        prefixIcon: Iconsax.home_2,
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 70,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 20),
                  label: Text(
                    _saving ? 'Saving...' : 'Save changes',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A623),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(34),
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

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD6DAE2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF5D6F8A),
              fontSize: 23,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF5D6F8A),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    String? counterText,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      counterText: counterText,
      alignLabelWithHint: alignLabelWithHint,
      hintStyle: const TextStyle(
        color: Color(0xFF6B7280),
        fontSize: 17,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 8, right: 6),
        child: Icon(prefixIcon, color: const Color(0xFF697386), size: 20),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 44),
      filled: true,
      fillColor: const Color(0xFFF0F1F3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD2D8E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF94A3B8), width: 1.3),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD2D8E1)),
      ),
    );
  }
}
