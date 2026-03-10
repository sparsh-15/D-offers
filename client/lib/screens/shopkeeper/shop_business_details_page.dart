import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/theme_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';
import '../../models/shopkeeper_profile_model.dart';
import 'ai_credit_packs_screen.dart';

class ShopBusinessDetailsPage extends StatefulWidget {
  const ShopBusinessDetailsPage({super.key});

  @override
  State<ShopBusinessDetailsPage> createState() =>
      _ShopBusinessDetailsPageState();
}

class _ShopBusinessDetailsPageState extends State<ShopBusinessDetailsPage> {
  ShopkeeperProfileModel? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await AuthService.instance.getShopkeeperProfile();
      if (!mounted) return;
      setState(() {
        _profile = p;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = ThemeHelper.getBackgroundGradient(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business details'),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 40,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Unable to load business details',
                              style: theme.textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error ?? '',
                              style: theme.textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _load,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final profile = _profile;
    if (profile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Business profile is not set yet.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final ownerName =
        profile.ownerName ?? (AuthStore.currentUser?.name ?? 'Owner');
    final ownerPhone =
        profile.ownerPhone ?? (AuthStore.currentUser?.phone ?? '');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary,
                child: Icon(
                  Icons.store_rounded,
                  size: 32,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.shopName.isEmpty ? 'My Shop' : profile.shopName,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    if (profile.category.isNotEmpty)
                      Text(
                        profile.category,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Owner details'),
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            icon: Icons.person_rounded,
            label: 'Owner name',
            value: ownerName,
          ),
          if (ownerPhone.isNotEmpty)
            _buildInfoRow(
              context,
              icon: Icons.phone_rounded,
              label: 'Contact number',
              value: '+91 $ownerPhone',
            ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Location'),
          const SizedBox(height: 8),
          if (profile.address.isNotEmpty)
            _buildInfoRow(
              context,
              icon: Icons.location_on_rounded,
              label: 'Address',
              value: profile.address,
            ),
          _buildInfoRow(
            context,
            icon: Icons.map_rounded,
            label: 'City & PIN',
            value: [
              if (profile.city.isNotEmpty) profile.city,
              if (profile.pincode.isNotEmpty) profile.pincode,
            ].join(', '),
          ),
          const SizedBox(height: 24),
          if (profile.description.isNotEmpty) ...[
            _buildSectionTitle(context, 'Description'),
            const SizedBox(height: 8),
            _buildMultilineBox(
              context,
              icon: Icons.info_outline_rounded,
              value: profile.description,
            ),
            const SizedBox(height: 24),
          ],
          _buildSectionTitle(context, 'AI banners'),
          const SizedBox(height: 8),
          Text(
            'Use AI credit packs to generate high-quality banner creatives for your offers.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AiCreditPacksScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('View AI Banner Packs'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
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
                  value.isEmpty ? '—' : value,
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

  Widget _buildMultilineBox(
    BuildContext context, {
    required IconData icon,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

