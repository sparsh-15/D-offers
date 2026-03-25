import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/dialog_helper.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';
import '../../models/shopkeeper_profile_model.dart';
import '../../services/location_service.dart';
import '../../services/subscription_service.dart';
import '../../services/upload_service.dart';
import 'ai_credit_packs_screen.dart';
import '../../widgets/theme_toggle.dart';
import '../../widgets/profile_option_tile.dart';
import '../../widgets/pincode_location_section.dart';
import '../../widgets/shop_logo_widget.dart';
import '../auth/login_screen.dart';
import '../common/settings_page.dart';
import '../common/help_support_page.dart';
import '../common/about_page.dart';
import '../common/customer_experience_shell.dart';
import 'shop_business_details_page.dart';
import 'current_plan_details_page.dart';
import 'shop_rewards_screen.dart';
import 'subscription_plans_screen.dart';

class ShopProfileBody extends StatefulWidget {
  final Map<String, dynamic>? subscription;
  final int? offerCount;

  const ShopProfileBody({
    super.key,
    this.subscription,
    this.offerCount,
  });

  @override
  State<ShopProfileBody> createState() => _ShopProfileBodyState();
}

class _ShopProfileBodyState extends State<ShopProfileBody> {
  ShopkeeperProfileModel? _profile;
  bool _loading = true;
  bool _uploadingLogo = false;

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

  Future<void> _uploadLogo() async {
    if (_uploadingLogo) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingLogo = true);
    try {
      final logoUrl = await UploadService.instance.uploadShopLogo(
        File(picked.path),
      );
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
          backgroundColor: AppColors.transparent,
          title: const Text('Shop Profile'),
          actions: const [
            ThemeToggleButton(),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            ShopLogoWidget(
                              logoUrl: _profile?.logoUrl,
                              radius: 38,
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
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_profile?.category.isNotEmpty == true)
                          Text(
                            _profile!.category,
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.elevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Customer View',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Browse app as customer',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: true,
                            onChanged: (_) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CustomerExperienceShell(
                                    sourceLabel: 'Shopkeeper',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildCompactSubscription(context),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  children: [
                    const ThemeToggle(),
                    ProfileOptionTile(
                      icon: Icons.edit_rounded,
                      title: 'Edit Shop Profile',
                      onTap: () => _openEditProfileDialog(context),
                    ),
                    ProfileOptionTile(
                      icon: Icons.business_rounded,
                      title: 'Business Details',
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ShopBusinessDetailsPage(),
                          ),
                        );
                        if (!mounted) return;
                        await _load();
                      },
                    ),
                    ProfileOptionTile(
                      icon: Icons.workspace_premium_rounded,
                      title: 'Manage Subscription Plans',
                      onTap: () => _openCurrentPlanDetails(context),
                    ),
                    ProfileOptionTile(
                      icon: Icons.emoji_events_rounded,
                      title: 'Rewards & Milestones',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ShopRewardsScreen(),
                          ),
                        );
                      },
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

  Widget _buildCompactSubscription(BuildContext context) {
    final sub = widget.subscription;
    if (sub == null) {
      return const SizedBox.shrink();
    }
    final planSnapshot =
        sub['planSnapshot'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final isTrial = sub['trial'] == true || planSnapshot['isTrial'] == true;
    final planName = isTrial
        ? (planSnapshot['trialDisplayName'] ?? 'Free Trial')
        : (planSnapshot['displayName'] ?? planSnapshot['name'] ?? 'Plan');
    final status = (sub['status'] ?? 'inactive').toString();
    final endDate = _parseSubscriptionEndDate(sub['endDate']);
    final daysLeft = _calculateDaysLeft(endDate);
    final isExpired =
        status.toLowerCase() == 'expired' || (daysLeft != null && daysLeft < 0);
    final statusColor = _subscriptionStatusColor(status, isExpired);
    final Object? maxOffers = planSnapshot['maxOffers'];
    final Object? monthlyAiLimit = planSnapshot['monthlyAiLimit'];
    final int usedThisCycle = (sub['usedThisCycle'] as num?)?.toInt() ?? 0;
    final int extraCredits =
        (sub['extraCreditsCurrentCycle'] as num?)?.toInt() ?? 0;
    late final String offerLabel;
    if (maxOffers == null || maxOffers == -1) {
      offerLabel = 'Unlimited offers';
    } else {
      offerLabel = '${widget.offerCount ?? 0} / $maxOffers offers used';
    }

    String? aiLabel;
    if (monthlyAiLimit != null && monthlyAiLimit != -1) {
      final int limit = (monthlyAiLimit as num?)?.toInt() ?? 0;
      aiLabel =
          'AI banners: $usedThisCycle / $limit used${extraCredits > 0 ? ' (+$extraCredits extra)' : ''}';
    }

    String validityLabel = 'No validity data';
    if (endDate != null) {
      if (isExpired) {
        validityLabel = 'Expired on ${_formatSubscriptionDate(endDate)}';
      } else if (daysLeft == null) {
        validityLabel = 'Ends on ${_formatSubscriptionDate(endDate)}';
      } else if (daysLeft == 0) {
        validityLabel = 'Expires today';
      } else {
        validityLabel = '$daysLeft days left';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  planName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              validityLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        isExpired ? AppColors.error : AppColors.textSecondary,
                  ),
            ),
          ),
          children: [
            Divider(color: AppColors.borderSubtle, height: 1),
            const SizedBox(height: 8),
            Text(
              'Subscription Details',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              offerLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (aiLabel != null)
              Text(
                aiLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            if (!isExpired &&
                endDate != null &&
                daysLeft != null &&
                daysLeft > 0)
              Text(
                'Ends on ${_formatSubscriptionDate(endDate)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openCurrentPlanDetails(context),
                  icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                  label: const Text('Manage Plan'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AiCreditPacksScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text('AI Packs'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _subscriptionStatusColor(String status, bool isExpired) {
    if (isExpired) return AppColors.error;
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.accent;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  DateTime? _parseSubscriptionEndDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  int? _calculateDaysLeft(DateTime? endDate) {
    if (endDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDay = DateTime(endDate.year, endDate.month, endDate.day);
    return endDay.difference(today).inDays;
  }

  String _formatSubscriptionDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    return '$day $month ${date.year}';
  }

  void _openSubscriptionPlansScreen(BuildContext context) {
    final category =
        (_profile?.category.isNotEmpty ?? false) ? _profile!.category : 'all';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SubscriptionPlansScreen(shopCategory: category),
      ),
    );
  }

  Future<void> _openCurrentPlanDetails(BuildContext context) async {
    final sub = widget.subscription;
    if (sub == null) {
      _openSubscriptionPlansScreen(context);
      return;
    }
    final category =
        (_profile?.category.isNotEmpty ?? false) ? _profile!.category : 'all';
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CurrentPlanDetailsPage(
          subscription: sub,
          offerCount: widget.offerCount ?? 0,
          shopCategory: category,
        ),
      ),
    );
  }

  Future<void> _openEditProfileDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>?>(
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
        latitude: result['latitude'] as double?,
        longitude: result['longitude'] as double?,
        category: result['category']?.trim().isEmpty ?? true
            ? null
            : result['category']!.trim(),
        description: result['description']?.trim().isEmpty ?? true
            ? null
            : result['description']!.trim(),
        clearLocationCoordinates:
            result['clearLocationCoordinates'] as bool? ?? false,
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
  bool _isLoadingCurrentLocation = false;
  List<Map<String, dynamic>> _availableAreas = [];
  List<Map<String, dynamic>> _categories = [];
  String? _selectedArea;
  String? _selectedCategory;
  double? _latitude;
  double? _longitude;
  bool _shouldClearCoordinates = false;
  bool _suppressLocationChangeTracking = false;
  bool _suppressPincodeLookup = false;

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
    _latitude = widget.profile?.latitude;
    _longitude = widget.profile?.longitude;

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
    pincodeController.addListener(_onLocationFieldEdited);
    cityController.addListener(_onLocationFieldEdited);
    addressController.addListener(_onLocationFieldEdited);
    _loadCategories();
  }

  @override
  void dispose() {
    pincodeController.removeListener(_onPincodeChanged);
    pincodeController.removeListener(_onLocationFieldEdited);
    cityController.removeListener(_onLocationFieldEdited);
    addressController.removeListener(_onLocationFieldEdited);
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
    if (_suppressPincodeLookup) return;
    final pincode = pincodeController.text;
    if (pincode.length == 6) {
      _lookupPincode(pincode);
    } else {
      _runWithSuppressedLocationChangeTracking(() {
        setState(() {
          _availableAreas = [];
          _selectedArea = null;
        });
        cityController.clear();
        stateController.clear();
      });
    }
  }

  void _onLocationFieldEdited() {
    if (_suppressLocationChangeTracking) return;
    if (_latitude == null && _longitude == null) return;

    setState(() {
      _latitude = null;
      _longitude = null;
      _shouldClearCoordinates = true;
    });
  }

  void _runWithSuppressedLocationChangeTracking(VoidCallback action) {
    _suppressLocationChangeTracking = true;
    action();
    _suppressLocationChangeTracking = false;
  }

  double? _parseLocationCoordinate(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim());
  }

  Future<void> _lookupPincode(String pincode) async {
    setState(() => _isLoadingPincode = true);
    try {
      final result = await AuthService.instance.lookupPincode(pincode);
      if (!mounted) return;

      final areas = result['areas'] as List<Map<String, dynamic>>? ?? [];

      setState(() {
        _availableAreas = areas;
        _selectedArea = areas.isNotEmpty ? areas[0]['name']?.toString() : null;
      });
      _runWithSuppressedLocationChangeTracking(() {
        stateController.text = result['state']?.toString() ?? '';
        cityController.text = result['district']?.toString() ?? '';
      });
    } catch (e) {
      // Silently fail - user can enter manually
    } finally {
      if (mounted) {
        setState(() => _isLoadingPincode = false);
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoadingCurrentLocation = true);
    try {
      final locationData =
          await LocationService.instance.getCurrentLocationWithAddress();
      final pincode = (locationData['pincode']?.toString() ?? '').trim();
      final city = (locationData['city']?.toString() ?? '').trim();
      final state = (locationData['state']?.toString() ?? '').trim();
      final street = (locationData['street']?.toString() ?? '').trim();
      final subLocality =
          (locationData['subLocality']?.toString() ?? '').trim();
      final detectedAddress =
          [street, subLocality].where((value) => value.isNotEmpty).join(', ');

      _suppressPincodeLookup = true;
      _runWithSuppressedLocationChangeTracking(() {
        if (pincode.isNotEmpty) {
          pincodeController.text = pincode;
        }
        if (city.isNotEmpty) {
          cityController.text = city;
        }
        stateController.text = state;
        if (detectedAddress.isNotEmpty) {
          addressController.text = detectedAddress;
        }
      });
      _suppressPincodeLookup = false;

      if (pincode.length == 6) {
        await _lookupPincode(pincode);
      }

      if (!mounted) return;
      setState(() {
        _latitude = _parseLocationCoordinate(locationData['latitude']);
        _longitude = _parseLocationCoordinate(locationData['longitude']);
        _shouldClearCoordinates = false;
        _isLoadingCurrentLocation = false;
      });

      DialogHelper.showSuccessSnackBar(
        context,
        'Current shop location added.',
      );
    } catch (e) {
      _suppressPincodeLookup = false;
      if (!mounted) return;
      setState(() => _isLoadingCurrentLocation = false);
      var message = 'Could not detect current location.';
      final errorText = e.toString().toLowerCase();
      if (errorText.contains('denied')) {
        message = 'Location permission denied.';
      } else if (errorText.contains('disabled')) {
        message = 'Location services are disabled.';
      }
      DialogHelper.showErrorSnackBar(context, message);
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
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      surfaceTintColor: AppColors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.borderMid),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.highlight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderMid),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.storefront_outlined,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Edit Shop Profile',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Update the customer-facing details for your shop.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed:
                    _isLoadingCurrentLocation ? null : _useCurrentLocation,
                icon: _isLoadingCurrentLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_outlined),
                label: Text(
                  _isLoadingCurrentLocation
                      ? 'Detecting current shop location...'
                      : 'Use current shop location',
                ),
              ),
            ),
            if (_latitude != null && _longitude != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Coordinates will be saved with this profile.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ),
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
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.borderMid),
            ),
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'shopName': shopNameController.text,
              'address': addressController.text,
              'pincode': pincodeController.text,
              'city': cityController.text,
              'latitude': _latitude,
              'longitude': _longitude,
              'category': _selectedCategory ?? '',
              'description': descriptionController.text,
              'clearLocationCoordinates': _shouldClearCoordinates,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// Detail row widget was used for the old in-tab \"Shop details\" card
// and is no longer needed now that business details have a dedicated screen.
