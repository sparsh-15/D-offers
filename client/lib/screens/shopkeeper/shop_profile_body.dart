import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/dialog_helper.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';
import '../../services/subscription_service.dart';
import '../../models/shopkeeper_profile_model.dart';
import '../../widgets/theme_toggle.dart';
import '../../widgets/profile_option_tile.dart';
import '../../widgets/pincode_location_section.dart';
import '../auth/login_screen.dart';
import '../common/settings_page.dart';
import '../common/help_support_page.dart';
import '../common/about_page.dart';

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
    final ownerName = AuthStore.currentUser?.name ?? '';
    final ownerPhone = AuthStore.currentUser?.phone ?? '';

    return Column(
      children: [
        AppBar(
          backgroundColor: AppColors.transparent,
          title: const Text('Shop Profile'),
          actions: const [
            ThemeToggleButton(),
          ],
        ),
        const SizedBox(height: 20),
        const CircleAvatar(
          radius: 50,
          backgroundColor: AppColors.primary,
          child: Icon(Icons.store_rounded, size: 50, color: AppColors.white),
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
        const SizedBox(height: 24),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  children: [
                    if (_profile != null) Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.elevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Shop details',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            if (ownerName.isNotEmpty)
                              _DetailRow(
                                icon: Icons.person_rounded,
                                label: 'Owner',
                                value: ownerName,
                              ),
                            if (ownerPhone.isNotEmpty)
                              _DetailRow(
                                icon: Icons.phone_rounded,
                                label: 'Contact',
                                value: '+91 $ownerPhone',
                              ),
                            if (_profile!.address.isNotEmpty)
                              _DetailRow(
                                icon: Icons.location_on_rounded,
                                label: 'Address',
                                value: _profile!.address,
                              ),
                            if (_profile!.city.isNotEmpty ||
                                _profile!.pincode.isNotEmpty)
                              _DetailRow(
                                icon: Icons.map_rounded,
                                label: 'Area',
                                value: [
                                  if (_profile!.city.isNotEmpty) _profile!.city,
                                  if (_profile!.pincode.isNotEmpty)
                                    _profile!.pincode,
                                ].join(', '),
                              ),
                            if (_profile!.description.isNotEmpty)
                              _DetailRow(
                                icon: Icons.info_outline_rounded,
                                label: 'Description',
                                value: _profile!.description,
                                maxLines: 3,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const ThemeToggle(),
                    ProfileOptionTile(
                      icon: Icons.edit_rounded,
                      title: 'Edit Shop Profile',
                      onTap: () => _openEditProfileDialog(context),
                    ),
                    ProfileOptionTile(
                      icon: Icons.business_rounded,
                      title: 'Business Details',
                      onTap: () => _openEditProfileDialog(context),
                    ),
                    ProfileOptionTile(
                      icon: Icons.settings_rounded,
                      title: 'Settings',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsPage(),
                          ),
                        );
                      },
                    ),
                    ProfileOptionTile(
                      icon: Icons.help_rounded,
                      title: 'Help & Support',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const HelpSupportPage(),
                          ),
                        );
                      },
                    ),
                    ProfileOptionTile(
                      icon: Icons.info_rounded,
                      title: 'About',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AboutPage(),
                          ),
                        );
                      },
                    ),
                    ProfileOptionTile(
                      icon: Icons.logout_rounded,
                      title: 'Logout',
                      isDestructive: true,
                      onTap: () async {
                        final shouldLogout =
                            await DialogHelper.showLogoutDialog(context);
                        if (shouldLogout && context.mounted) {
                          await AuthStore.clearPersistedAuth();
                          AuthStore.clear();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                          DialogHelper.showSuccessSnackBar(
                              context, 'Logged out successfully');
                        }
                      },
                    ),
                  ],
                ),
        ),
      ],
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
      try {
        await AuthService.instance.completeOnboardingProfile();
      } catch (_) {
        DialogHelper.showInfoSnackBar(
          context,
          'Profile saved, but onboarding status could not be updated. Please log in again.',
        );
      }
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
  late final TextEditingController descriptionController;

  bool _isLoadingPincode = false;
  bool _isLoadingCategories = false;
  List<Map<String, dynamic>> _availableAreas = [];
  List<Map<String, dynamic>> _categories = [];
  String? _selectedArea;
  String? _selectedCategory;

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
    descriptionController =
        TextEditingController(text: widget.profile?.description ?? '');

    // Prefill from current user if profile is empty so shopkeepers don't retype
    // everything they already entered during signup.
    final currentUser = AuthStore.currentUser;
    if (currentUser != null) {
      if (addressController.text.trim().isEmpty &&
          currentUser.address.trim().isNotEmpty) {
        addressController.text = currentUser.address.trim();
      }
      if (pincodeController.text.trim().isEmpty &&
          currentUser.pincode.trim().isNotEmpty) {
        pincodeController.text = currentUser.pincode.trim();
      }
      if (cityController.text.trim().isEmpty &&
          currentUser.city.trim().isNotEmpty) {
        cityController.text = currentUser.city.trim();
      }
    }

    // Category will be set after loading categories in _loadCategories()

    pincodeController.addListener(_onPincodeChanged);
    _loadCategories();
  }

  @override
  void dispose() {
    pincodeController.removeListener(_onPincodeChanged);
    shopNameController.dispose();
    addressController.dispose();
    pincodeController.dispose();
    cityController.dispose();
    stateController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final response = await SubscriptionService.instance.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = response;
        _isLoadingCategories = false;

        // Validate and set initial category
        final profileCategory = widget.profile?.category;
        if (profileCategory != null && profileCategory.isNotEmpty) {
          // Check if the profile category exists in the loaded categories
          final categoryExists = _categories.any(
            (cat) => cat['value'] == profileCategory,
          );

          if (categoryExists) {
            _selectedCategory = profileCategory;
          } else {
            // Profile has an old/invalid category value - reset to null
            _selectedCategory = null;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCategories = false);
      // Silently fail - user can still save without changing category
    }
  }

  void _onPincodeChanged() {
    final pincode = pincodeController.text;
    if (pincode.length == 6) {
      _lookupPincode(pincode);
    } else {
      setState(() {
        _availableAreas = [];
        _selectedArea = null;
      });
      cityController.clear();
      stateController.clear();
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
        cityController.text = result['district']?.toString() ?? '';
        _selectedArea = areas.isNotEmpty ? areas[0]['name']?.toString() : null;
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
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'This is the shop location customers will see in the app.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            PincodeLocationSection(
              pincodeController: pincodeController,
              cityController: cityController,
              stateController: stateController,
              addressController: addressController,
              isLoadingPincode: _isLoadingPincode,
              availableAreas: _availableAreas,
              selectedArea: _selectedArea,
              onAreaChanged: _onAreaSelected,
              addressLabel: 'Address',
            ),
            const SizedBox(height: 8),
            _isLoadingCategories
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Business Category',
                          hintText: 'Select your business type',
                        ),
                        isExpanded: true,
                        items: _categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category['value'],
                            child: Text(category['label'] ?? category['value']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                      ),
                      if (widget.profile?.category != null &&
                          widget.profile!.category.isNotEmpty &&
                          _selectedCategory == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 12),
                          child: Text(
                            'Previous category "${widget.profile!.category}" is no longer valid. Please select a new category.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                    ],
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
              'category': _selectedCategory ?? '',
              'description': descriptionController.text,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int maxLines;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
