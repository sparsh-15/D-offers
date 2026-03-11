import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/dialog_helper.dart';
import '../../models/shopkeeper_profile_model.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';
import '../../services/upload_service.dart';
import '../../widgets/shop_logo_widget.dart';
import '../../core/utils/theme_helper.dart';
import 'ai_credit_packs_screen.dart';

class ShopBusinessDetailsPage extends StatefulWidget {
  const ShopBusinessDetailsPage({super.key});

  @override
  State<ShopBusinessDetailsPage> createState() =>
      _ShopBusinessDetailsPageState();
}

class _ShopBusinessDetailsPageState extends State<ShopBusinessDetailsPage> {
  static const int _maxShopImages = 10;

  ShopkeeperProfileModel? _profile;
  bool _loading = true;
  String? _error;
  bool _uploadingLogo = false;
  bool _uploadingImages = false;

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

  Future<void> _uploadLogo() async {
    if (_uploadingLogo) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingLogo = true);
    try {
      final logoUrl = await UploadService.instance.uploadShopLogo(File(picked.path));
      final updated = await AuthService.instance.updateLogoUrl(logoUrl);
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _uploadingLogo = false;
      });
      DialogHelper.showSuccessSnackBar(context, 'Shop logo updated');
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingLogo = false);
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }

  Future<void> _addShopImages() async {
    final profile = _profile;
    if (profile == null || _uploadingImages) return;

    final remainingSlots = _maxShopImages - profile.shopImages.length;
    if (remainingSlots <= 0) {
      DialogHelper.showInfoSnackBar(
        context,
        'You can upload up to $_maxShopImages shop images.',
      );
      return;
    }

    final pickedFiles = await ImagePicker().pickMultiImage(
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
      limit: remainingSlots,
    );
    if (pickedFiles.isEmpty || !mounted) return;

    setState(() => _uploadingImages = true);
    try {
      final uploadedUrls = await UploadService.instance.uploadShopImages(
        pickedFiles.map((file) => File(file.path)).toList(),
      );
      final updated = await AuthService.instance.updateShopImages([
        ...profile.shopImages,
        ...uploadedUrls,
      ]);
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _uploadingImages = false;
      });
      DialogHelper.showSuccessSnackBar(context, 'Shop images updated');
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingImages = false);
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }

  Future<void> _removeShopImage(String imageUrl) async {
    final profile = _profile;
    if (profile == null || _uploadingImages) return;

    setState(() => _uploadingImages = true);
    try {
      final updated = await AuthService.instance.updateShopImages(
        profile.shopImages.where((image) => image != imageUrl).toList(),
      );
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _uploadingImages = false;
      });
      DialogHelper.showSuccessSnackBar(context, 'Shop image removed');
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingImages = false);
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
              Stack(
                alignment: Alignment.center,
                children: [
                  ShopLogoWidget(
                    logoUrl: profile.logoUrl,
                    radius: 32,
                    isEditable: true,
                    onTap: _uploadLogo,
                  ),
                  if (_uploadingLogo)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Color(0x66000000),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    ),
                ],
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
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _uploadingLogo ? null : _uploadLogo,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(140, 44),
                      ),
                      icon: const Icon(Icons.photo_camera_rounded),
                      label: Text(
                        profile.logoUrl?.isNotEmpty == true
                            ? 'Update logo'
                            : 'Upload logo',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Shop photos'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${profile.shopImages.length} / $_maxShopImages uploaded',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _uploadingImages ? null : _addShopImages,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(120, 44),
                ),
                icon: _uploadingImages
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_photo_alternate_rounded),
                label: const Text('Add photos'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (profile.shopImages.isEmpty)
            _buildMultilineBox(
              context,
              icon: Icons.photo_library_outlined,
              value:
                  'Add storefront or ambience photos so customers can recognize your shop.',
            )
          else
            SizedBox(
              height: 132,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: profile.shopImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final imageUrl = profile.shopImages[index];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          width: 132,
                          height: 132,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 132,
                            height: 132,
                            color: AppColors.elevated,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: InkWell(
                          onTap: _uploadingImages
                              ? null
                              : () => _removeShopImage(imageUrl),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.background.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
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

