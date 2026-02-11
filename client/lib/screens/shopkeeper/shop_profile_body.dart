import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/dialog_helper.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';
import '../../models/shopkeeper_profile_model.dart';
import '../../widgets/theme_toggle.dart';
import '../role_selection/role_selection_screen.dart';

class ShopProfileBody extends StatefulWidget {
  const ShopProfileBody({super.key});

  @override
  State<ShopProfileBody> createState() => _ShopProfileBodyState();
}

class _ShopProfileBodyState extends State<ShopProfileBody> {
  ShopkeeperProfileModel? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await AuthService.instance.getShopkeeperProfile();
      if (!mounted) return;
      setState(() {
        _profile = p;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?.shopName.isNotEmpty == true
        ? _profile!.shopName
        : (AuthStore.currentUser?.name.isNotEmpty == true
            ? AuthStore.currentUser!.name
            : 'My Shop');

    return Column(
      children: [
        AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Shop Profile'),
          actions: const [
            ThemeToggleButton(),
          ],
        ),
        const SizedBox(height: 20),
        const CircleAvatar(
          radius: 50,
          backgroundColor: AppColors.primary,
          child: Icon(Icons.store_rounded, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (_profile?.category.isNotEmpty == true)
          Text(
            _profile!.category,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        const SizedBox(height: 32),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  children: [
                    const ThemeToggle(),
                    _buildProfileOption(
                        context, Icons.edit_rounded, 'Edit Shop Profile'),
                    _buildProfileOption(
                        context, Icons.business_rounded, 'Business Details'),
                    _buildProfileOption(
                        context, Icons.settings_rounded, 'Settings'),
                    _buildProfileOption(
                        context, Icons.help_rounded, 'Help & Support'),
                    _buildProfileOption(context, Icons.logout_rounded, 'Logout',
                        isDestructive: true),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildProfileOption(BuildContext context, IconData icon, String title,
      {bool isDestructive = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon,
            color: isDestructive ? AppColors.error : AppColors.primary),
        title: Text(
          title,
          style: TextStyle(color: isDestructive ? AppColors.error : null),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () async {
          if (title == 'Edit Shop Profile') {
            await _openEditProfileDialog(context);
          } else if (title == 'Logout') {
            final shouldLogout = await DialogHelper.showLogoutDialog(context);
            if (shouldLogout && context.mounted) {
              AuthStore.clear();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                (route) => false,
              );
              DialogHelper.showSuccessSnackBar(
                  context, 'Logged out successfully');
            }
          }
        },
      ),
    );
  }

  Future<void> _openEditProfileDialog(BuildContext context) async {
    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (context) => _EditProfileDialog(profile: _profile),
    );

    if (result == null) return;
    if (result['shopName']?.trim().isEmpty ?? true) {
      if (!mounted) return;
      DialogHelper.showErrorSnackBar(context, 'Shop name is required');
      return;
    }

    try {
      final updated = await AuthService.instance.upsertShopkeeperProfile(
        shopName: result['shopName']!.trim(),
        address: result['address']?.trim().isEmpty ?? true
            ? null
            : result['address']!.trim(),
        pincode: result['pincode']?.trim().isEmpty ?? true
            ? null
            : result['pincode']!.trim(),
        city: result['city']?.trim().isEmpty ?? true
            ? null
            : result['city']!.trim(),
        category: result['category']?.trim().isEmpty ?? true
            ? null
            : result['category']!.trim(),
        description: result['description']?.trim().isEmpty ?? true
            ? null
            : result['description']!.trim(),
      );
      if (!mounted) return;
      setState(() => _profile = updated);
      DialogHelper.showSuccessSnackBar(context, 'Shop profile updated');
    } catch (e) {
      if (!mounted) return;
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }
}

class _EditProfileDialog extends StatefulWidget {
  final ShopkeeperProfileModel? profile;

  const _EditProfileDialog({this.profile});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController shopNameController;
  late final TextEditingController addressController;
  late final TextEditingController pincodeController;
  late final TextEditingController cityController;
  late final TextEditingController stateController;
  late final TextEditingController categoryController;
  late final TextEditingController descriptionController;

  bool _isLoadingPincode = false;
  List<Map<String, dynamic>> _availableAreas = [];
  String? _selectedArea;

  @override
  void initState() {
    super.initState();
    shopNameController =
        TextEditingController(text: widget.profile?.shopName ?? '');
    addressController =
        TextEditingController(text: widget.profile?.address ?? '');
    pincodeController =
        TextEditingController(text: widget.profile?.pincode ?? '');
    cityController = TextEditingController(text: widget.profile?.city ?? '');
    stateController = TextEditingController();
    categoryController =
        TextEditingController(text: widget.profile?.category ?? '');
    descriptionController =
        TextEditingController(text: widget.profile?.description ?? '');

    pincodeController.addListener(_onPincodeChanged);
  }

  @override
  void dispose() {
    pincodeController.removeListener(_onPincodeChanged);
    shopNameController.dispose();
    addressController.dispose();
    pincodeController.dispose();
    cityController.dispose();
    stateController.dispose();
    categoryController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _onPincodeChanged() {
    final pincode = pincodeController.text;
    if (pincode.length == 6) {
      _lookupPincode(pincode);
    }
  }

  Future<void> _lookupPincode(String pincode) async {
    setState(() => _isLoadingPincode = true);
    try {
      final result = await AuthService.instance.lookupPincode(pincode);
      if (!mounted) return;

      final areas = result['areas'] as List<Map<String, dynamic>>? ?? [];

      setState(() {
        stateController.text = result['state']?.toString() ?? '';
        _availableAreas = areas;

        // Auto-select first area if only one available
        if (areas.length == 1) {
          _selectedArea = areas[0]['name'];
          cityController.text = areas[0]['name'] ?? '';
        } else if (areas.isEmpty) {
          // Fallback to district if no areas
          cityController.text = result['district']?.toString() ?? '';
        } else {
          // Multiple areas - user needs to select
          cityController.clear();
          _selectedArea = null;
        }
      });
    } catch (e) {
      // Silently fail - user can enter manually
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
      cityController.text = areaName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Shop Profile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: shopNameController,
              decoration: const InputDecoration(labelText: 'Shop Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: pincodeController,
              decoration: const InputDecoration(labelText: 'Pincode'),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 8),
            _availableAreas.length > 1
                ? DropdownButtonFormField<String>(
                    value: _selectedArea,
                    decoration: const InputDecoration(labelText: 'City / Area'),
                    hint: const Text('Select your area'),
                    items: _availableAreas.map((area) {
                      return DropdownMenuItem<String>(
                        value: area['name'],
                        child: Text(area['name'] ?? ''),
                      );
                    }).toList(),
                    onChanged: _isLoadingPincode ? null : _onAreaSelected,
                  )
                : TextField(
                    controller: cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                    enabled: !_isLoadingPincode,
                  ),
            if (_isLoadingPincode)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Looking up pincode...',
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            if (_availableAreas.length > 1 && !_isLoadingPincode)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${_availableAreas.length} areas found',
                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'shopName': shopNameController.text,
              'address': addressController.text,
              'pincode': pincodeController.text,
              'city': cityController.text,
              'category': categoryController.text,
              'description': descriptionController.text,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
