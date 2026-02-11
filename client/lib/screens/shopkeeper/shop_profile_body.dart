import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/dialog_helper.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';
import '../../models/shopkeeper_profile_model.dart';
import '../../widgets/theme_toggle.dart';
import '../role_selection/role_selection_screen.dart';

class _ShopProfileBody extends StatefulWidget {
  const _ShopProfileBody();

  @override
  State<_ShopProfileBody> createState() => _ShopProfileBodyState();
}

class _ShopProfileBodyState extends State<_ShopProfileBody> {
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
                    _buildProfileOption(
                        context, Icons.logout_rounded, 'Logout',
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
    final shopNameController =
        TextEditingController(text: _profile?.shopName ?? '');
    final addressController =
        TextEditingController(text: _profile?.address ?? '');
    final pincodeController =
        TextEditingController(text: _profile?.pincode ?? '');
    final cityController = TextEditingController(text: _profile?.city ?? '');
    final categoryController =
        TextEditingController(text: _profile?.category ?? '');
    final descriptionController =
        TextEditingController(text: _profile?.description ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
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
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                TextField(
                  controller: pincodeController,
                  decoration: const InputDecoration(labelText: 'Pincode'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(labelText: 'City'),
                ),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != true) return;
    if (shopNameController.text.trim().isEmpty) {
      DialogHelper.showErrorSnackBar(context, 'Shop name is required');
      return;
    }

    try {
      final updated = await AuthService.instance.upsertShopkeeperProfile(
        shopName: shopNameController.text.trim(),
        address: addressController.text.trim().isEmpty
            ? null
            : addressController.text.trim(),
        pincode: pincodeController.text.trim().isEmpty
            ? null
            : pincodeController.text.trim(),
        city: cityController.text.trim().isEmpty
            ? null
            : cityController.text.trim(),
        category: categoryController.text.trim().isEmpty
            ? null
            : categoryController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
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

