import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/theme_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../services/auth_service.dart';
import '../../models/shopkeeper_profile_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/gradient_card.dart';
import 'subscription_plans_screen.dart';

class OnboardingFlow extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingFlow({super.key, required this.onComplete});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  bool _loading = true;
  ShopkeeperProfileModel? _profile;
  Map<String, dynamic>? _subscriptionStatus;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() => _loading = true);
    try {
      // Check profile
      ShopkeeperProfileModel? profile;
      try {
        profile = await AuthService.instance.getShopkeeperProfile();
      } catch (e) {
        // Profile doesn't exist yet
        profile = null;
      }

      // Check subscription (you'll need to add this API call)
      Map<String, dynamic>? subscription;
      try {
        // TODO: Add API call to check subscription status
        subscription = null; // For now, assume no subscription
      } catch (e) {
        subscription = null;
      }

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _subscriptionStatus = subscription;
        _loading = false;
      });

      // If both are complete, call onComplete
      if (_isProfileComplete() && _hasActiveSubscription()) {
        widget.onComplete();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  bool _isProfileComplete() {
    return _profile != null &&
        _profile!.shopName.isNotEmpty &&
        _profile!.pincode.isNotEmpty &&
        _profile!.city.isNotEmpty;
  }

  bool _hasActiveSubscription() {
    // TODO: Check actual subscription status
    return _subscriptionStatus != null &&
        _subscriptionStatus!['status'] == 'active';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
              gradient: ThemeHelper.getBackgroundGradient(context)),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Show profile completion first
    if (!_isProfileComplete()) {
      return _buildProfileCompletionScreen();
    }

    // Then show subscription
    if (!_hasActiveSubscription()) {
      return _buildSubscriptionScreen();
    }

    // Both complete - this shouldn't be reached as onComplete is called
    return const Scaffold(
      body: Center(child: Text('Loading...')),
    );
  }

  Widget _buildProfileCompletionScreen() {
    return Scaffold(
      body: Container(
        decoration:
            BoxDecoration(gradient: ThemeHelper.getBackgroundGradient(context)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),
                        FadeInDown(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.store_rounded,
                              size: 80,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        FadeInDown(
                          delay: const Duration(milliseconds: 200),
                          child: Text(
                            'Complete Your Shop Profile',
                            style: Theme.of(context).textTheme.displaySmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInDown(
                          delay: const Duration(milliseconds: 300),
                          child: Text(
                            'Let customers know about your business',
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 48),
                        FadeInUp(
                          delay: const Duration(milliseconds: 400),
                          child: _buildRequirementCard(
                            icon: Icons.business_rounded,
                            title: 'Shop Name',
                            description: 'Your business name',
                            isComplete: _profile?.shopName.isNotEmpty ?? false,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInUp(
                          delay: const Duration(milliseconds: 500),
                          child: _buildRequirementCard(
                            icon: Icons.location_on_rounded,
                            title: 'Location',
                            description: 'Pincode and city',
                            isComplete:
                                (_profile?.pincode.isNotEmpty ?? false) &&
                                    (_profile?.city.isNotEmpty ?? false),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInUp(
                          delay: const Duration(milliseconds: 600),
                          child: _buildRequirementCard(
                            icon: Icons.category_rounded,
                            title: 'Category',
                            description: 'Type of business (optional)',
                            isComplete: true,
                            isOptional: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                FadeInUp(
                  delay: const Duration(milliseconds: 700),
                  child: CustomButton(
                    text: 'Complete Profile',
                    onPressed: () => _openProfileDialog(),
                    icon: Icons.arrow_forward_rounded,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionScreen() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            // Go back to profile completion
            setState(() {
              _profile = null;
            });
          },
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              // Skip for now - allow limited access
              widget.onComplete();
            },
            icon: const Icon(Icons.skip_next_rounded),
            label: const Text('Skip for now'),
          ),
        ],
      ),
      body: Container(
        decoration:
            BoxDecoration(gradient: ThemeHelper.getBackgroundGradient(context)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),
                        FadeInDown(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.workspace_premium_rounded,
                              size: 80,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        FadeInDown(
                          delay: const Duration(milliseconds: 200),
                          child: Text(
                            'Choose Your Plan',
                            style: Theme.of(context).textTheme.displaySmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInDown(
                          delay: const Duration(milliseconds: 300),
                          child: Text(
                            'Select a subscription plan to start creating offers',
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 48),
                        FadeInUp(
                          delay: const Duration(milliseconds: 400),
                          child: GradientCard(
                            gradient: AppColors.primaryGradient,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.white,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Profile Complete!',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(color: AppColors.white),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Your shop profile is ready. Now choose a plan to start.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: AppColors.white
                                              .withValues(alpha: 0.9)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeInUp(
                          delay: const Duration(milliseconds: 500),
                          child: _buildFeatureItem('Create unlimited offers'),
                        ),
                        FadeInUp(
                          delay: const Duration(milliseconds: 550),
                          child: _buildFeatureItem('Reach more customers'),
                        ),
                        FadeInUp(
                          delay: const Duration(milliseconds: 600),
                          child: _buildFeatureItem('Track offer performance'),
                        ),
                        FadeInUp(
                          delay: const Duration(milliseconds: 650),
                          child: _buildFeatureItem('Get customer leads'),
                        ),
                      ],
                    ),
                  ),
                ),
                FadeInUp(
                  delay: const Duration(milliseconds: 700),
                  child: CustomButton(
                    text: 'View Plans',
                    onPressed: () async {
                      if (_profile == null || _profile!.category.isEmpty) {
                        DialogHelper.showErrorSnackBar(
                          context,
                          'Please complete your profile first',
                        );
                        return;
                      }

                      // Navigate to subscription plans screen
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubscriptionPlansScreen(
                            shopCategory: _profile!.category,
                          ),
                        ),
                      );

                      // Refresh status after returning
                      _checkStatus();
                    },
                    icon: Icons.arrow_forward_rounded,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isComplete,
    bool isOptional = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isComplete
                    ? AppColors.green.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isComplete ? Icons.check_circle_rounded : icon,
                color: isComplete ? AppColors.green : AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (isOptional) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Optional',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Future<void> _openProfileDialog() async {
    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (context) => _ProfileDialog(profile: _profile),
    );

    if (result == null) return;
    if (result['shopName']?.trim().isEmpty ?? true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shop name is required'),
          backgroundColor: AppColors.red,
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.green,
        ),
      );
      _checkStatus(); // Recheck status
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }
}

class _ProfileDialog extends StatefulWidget {
  final ShopkeeperProfileModel? profile;

  const _ProfileDialog({this.profile});

  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  late final TextEditingController shopNameController;
  late final TextEditingController addressController;
  late final TextEditingController pincodeController;
  late final TextEditingController cityController;
  late final TextEditingController descriptionController;

  bool _isLoadingPincode = false;
  bool _isLoadingCategories = true;
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
    descriptionController =
        TextEditingController(text: widget.profile?.description ?? '');

    _selectedCategory = widget.profile?.category;

    pincodeController.addListener(_onPincodeChanged);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      // TODO: Call API to get categories
      // final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/meta/categories'));
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;
      setState(() {
        _categories = [
          {'value': 'retail', 'label': 'Retail Store'},
          {'value': 'restaurant', 'label': 'Restaurant'},
          {'value': 'grocery', 'label': 'Grocery Store'},
          {'value': 'pharmacy', 'label': 'Pharmacy'},
          {'value': 'electronics', 'label': 'Electronics'},
          {'value': 'clothing', 'label': 'Clothing & Fashion'},
          {'value': 'beauty_salon', 'label': 'Beauty Salon & Spa'},
          {'value': 'gym_fitness', 'label': 'Gym & Fitness'},
          {'value': 'education', 'label': 'Education & Training'},
          {'value': 'healthcare', 'label': 'Healthcare'},
          {'value': 'automotive', 'label': 'Automotive'},
          {'value': 'home_services', 'label': 'Home Services'},
          {'value': 'entertainment', 'label': 'Entertainment'},
          {'value': 'food_beverage', 'label': 'Food & Beverage'},
          {'value': 'jewelry', 'label': 'Jewelry'},
          {'value': 'books_stationery', 'label': 'Books & Stationery'},
          {'value': 'sports', 'label': 'Sports & Outdoors'},
          {'value': 'pet_care', 'label': 'Pet Care'},
          {'value': 'travel', 'label': 'Travel & Tourism'},
          {'value': 'other', 'label': 'Other'},
        ];
        _isLoadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCategories = false);
    }
  }

  @override
  void dispose() {
    pincodeController.removeListener(_onPincodeChanged);
    shopNameController.dispose();
    addressController.dispose();
    pincodeController.dispose();
    cityController.dispose();
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
        _availableAreas = areas;

        if (areas.length == 1) {
          _selectedArea = areas[0]['name'];
          cityController.text = areas[0]['name'] ?? '';
        } else if (areas.isEmpty) {
          cityController.text = result['district']?.toString() ?? '';
        } else {
          cityController.clear();
          _selectedArea = null;
        }
      });
    } catch (e) {
      // Silently fail
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
      title: const Text('Complete Shop Profile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: shopNameController,
              decoration: const InputDecoration(
                labelText: 'Shop Name *',
                hintText: 'Enter your shop name',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                hintText: 'Street address',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pincodeController,
              decoration: const InputDecoration(
                labelText: 'Pincode *',
                hintText: '6-digit pincode',
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 12),
            _availableAreas.length > 1
                ? DropdownButtonFormField<String>(
                    initialValue: _selectedArea,
                    decoration:
                        const InputDecoration(labelText: 'City / Area *'),
                    hint: const Text('Select your area'),
                    isExpanded: true,
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
                    decoration: const InputDecoration(
                      labelText: 'City *',
                      hintText: 'Your city',
                    ),
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
            const SizedBox(height: 12),
            _isLoadingCategories
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Business Category',
                      hintText: 'Select your business type',
                    ),
                    isExpanded: true,
                    items: _categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category['value'],
                        child: Text(category['label']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Brief description of your business',
              ),
              maxLines: 3,
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
