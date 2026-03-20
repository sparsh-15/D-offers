import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/theme_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../widgets/data_state_wrapper.dart';
import '../../widgets/gradient_card.dart';
import '../../services/subscription_service.dart';

class SubscriptionGovernanceScreen extends StatefulWidget {
  const SubscriptionGovernanceScreen({super.key});

  @override
  State<SubscriptionGovernanceScreen> createState() =>
      _SubscriptionGovernanceScreenState();
}

class _SubscriptionGovernanceScreenState
    extends State<SubscriptionGovernanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Governance'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Plans', icon: Icon(Icons.list_alt_rounded)),
            Tab(text: 'Subscriptions', icon: Icon(Icons.subscriptions_rounded)),
            Tab(text: 'AI Packs', icon: Icon(Icons.auto_awesome_rounded)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics_rounded)),
          ],
        ),
      ),
      body: Container(
        decoration:
            BoxDecoration(gradient: ThemeHelper.getBackgroundGradient(context)),
        child: TabBarView(
          controller: _tabController,
          children: const [
            PlansManagementTab(),
            SubscriptionsManagementTab(),
            AiCreditPacksTab(),
            SubscriptionAnalyticsTab(),
          ],
        ),
      ),
    );
  }
}

// ============ Plans Management Tab ============
class PlansManagementTab extends StatefulWidget {
  const PlansManagementTab({super.key});

  @override
  State<PlansManagementTab> createState() => _PlansManagementTabState();
}

class _PlansManagementTabState extends State<PlansManagementTab> {
  List<Map<String, dynamic>> _plans = [];
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  String? _error;
  /// null or 'all' = show all; else filter by this category value
  String? _filterCategory;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Load categories and plans in parallel
      await Future.wait([
        _loadCategories(),
        _loadPlans(),
      ]);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await SubscriptionService.instance.getCategories();

      if (!mounted) return;
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      print('Error loading categories: $e');
      // Fallback to empty list
      if (!mounted) return;
      setState(() {
        _categories = [];
      });
    }
  }

  Future<void> _loadPlans() async {
    try {
      final plans = await SubscriptionService.instance.getAllPlans();

      if (!mounted) return;
      setState(() {
        _plans = plans;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredPlans = _filterCategory == null ||
            _filterCategory == 'all' ||
            _filterCategory!.isEmpty
        ? _plans
        : _plans.where((p) => (p['category'] ?? '') == _filterCategory).toList();

    // Display order: higher price first
    num toNum(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v;
      if (v is String) return num.tryParse(v) ?? 0;
      return 0;
    }
    filteredPlans.sort((a, b) {
      final priceA = toNum(a['monthlyPrice'] ?? a['price']);
      final priceB = toNum(b['monthlyPrice'] ?? b['price']);
      return priceB.compareTo(priceA);
    });

    return Column(
      children: [
        // Always-visible header with Add Plan button
        Padding(
          padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${filteredPlans.length} Plans',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Flexible(
                fit: FlexFit.loose,
                child: ElevatedButton.icon(
                  onPressed: () => _showPlanDialog(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Plan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: Row(
            children: [
              Text(
                'Category: ',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: (_filterCategory == null ||
                          _filterCategory == 'all' ||
                          (_filterCategory?.isEmpty ?? true) ||
                          !_categories.any((c) => c['value'] == _filterCategory))
                      ? 'all'
                      : _filterCategory!,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('All categories')),
                    ..._categories.map<DropdownMenuItem<String>>((cat) {
                      final value = cat['value'] as String? ?? '';
                      final label = cat['label'] as String? ?? value;
                      return DropdownMenuItem(
                        value: value,
                        child: Text(label),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterCategory = (value == 'all' || value == null) ? null : value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : (_error != null && _error!.isNotEmpty)
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 48, color: AppColors.error),
                          const SizedBox(height: 12),
                          Text(_error!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadData,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try again'),
                          ),
                        ],
                      ),
                    )
                  : filteredPlans.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inbox_rounded,
                                  size: 48,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              Text(
                                'No plans yet. Tap "Add Plan" above to create one.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredPlans.length,
                          itemBuilder: (context, index) {
                            final plan = filteredPlans[index];
                            return FadeInUp(
                              delay: Duration(milliseconds: 100 * index),
                              child: _buildPlanCard(plan),
                            );
                          },
                        ),
        ),
        ],
      );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final isActive = plan['isActive'] as bool? ?? true;
    final categoryValue = plan['category'] as String? ?? '';
    final categoryLabel = _categories.firstWhere(
      (cat) => cat['value'] == categoryValue,
      orElse: () => {'label': categoryValue},
    )['label'];

    // Use correct API field names
    final displayName = plan['displayName'] ?? plan['name'] ?? 'Unnamed Plan';
    final monthlyPrice = plan['monthlyPrice'] ?? plan['price'] ?? 0;
    final maxOffers = plan['maxOffers'] ?? plan['offerLimit'] ?? 0;
    final monthlyAiLimit = plan['monthlyAiLimit'];
    final tierLabel = plan['tier'] ?? plan['rankingTier'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isActive ? AppColors.green : AppColors.grey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isActive ? 'Active' : 'Inactive',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Category: $categoryLabel',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showPlanDialog(plan: plan);
                    } else if (value == 'toggle') {
                      _togglePlanStatus(plan);
                    } else if (value == 'delete') {
                      _deletePlan(plan);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 20),
                          SizedBox(width: 12),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            isActive
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(isActive ? 'Deactivate' : 'Activate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_rounded,
                              size: 20, color: AppColors.error),
                          SizedBox(width: 12),
                          Text('Delete',
                              style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildPlanDetail(
                    'Price',
                    '₹$monthlyPrice',
                    Icons.currency_rupee_rounded,
                  ),
                ),
                Expanded(
                  child: _buildPlanDetail(
                    'Offers',
                    maxOffers == -1 ? 'Unlimited' : '$maxOffers',
                    Icons.local_offer_rounded,
                  ),
                ),
              ],
            ),
            if (tierLabel.toString().isNotEmpty || monthlyAiLimit != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (tierLabel.toString().isNotEmpty)
                    Expanded(
                      child: _buildPlanDetail(
                        'Tier',
                        tierLabel.toString(),
                        Icons.star_rounded,
                      ),
                    ),
                  if (monthlyAiLimit != null)
                    Expanded(
                      child: _buildPlanDetail(
                        'AI/mo',
                        monthlyAiLimit == -1 ? 'Unlimited' : '$monthlyAiLimit',
                        Icons.auto_awesome_rounded,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlanDetail(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.grey600,
          ),
        ),
      ],
    );
  }

  Future<void> _showPlanDialog({Map<String, dynamic>? plan}) async {
    final isEdit = plan != null;
    final mutedStyle = TextStyle(color: AppColors.textMuted, fontSize: 10);
    final sectionStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted);

    // Use correct API field names
    final displayNameController = TextEditingController(
      text: plan?['displayName'] ?? plan?['name'] ?? '',
    );
    final priceController = TextEditingController(
      text: (plan?['monthlyPrice'] ?? plan?['price'] ?? '').toString(),
    );
    final offerLimitController = TextEditingController(
      text: (plan?['maxOffers'] ?? plan?['offerLimit'] ?? 10).toString(),
    );
    final maxPhotosController = TextEditingController(
      text: (plan?['maxPhotosPerOffer'] ?? 5).toString(),
    );
    final monthlyAiLimitController = TextEditingController(
      text: (plan?['monthlyAiLimit'] ?? 0).toString(),
    );
    final descriptionController = TextEditingController(
      text: plan?['description'] ?? '',
    );

    String? selectedCategory = plan?['category'];
    // Tier is mandatory: default to silver when creating or when plan has no tier
    String selectedTier = (plan?['tier']?.toString().trim().isNotEmpty == true)
        ? (plan!['tier'] as String)
        : 'silver';
    String selectedRankingTier = selectedTier == 'trial'
      ? 'normal'
      : selectedTier == 'silver'
        ? 'normal'
        : selectedTier == 'gold'
            ? 'top3'
            : selectedTier == 'platinum'
                ? 'priority'
                : (plan?['rankingTier'] ?? 'normal');
    String selectedAiCreditTier = plan?['aiCreditTier'] ?? selectedTier;
    bool homepageRotation = plan?['homepageRotation'] == true;
    bool aiOptimizationSuggestions = plan?['aiOptimizationSuggestions'] == true;
    bool analyticsEnabled = plan?['analyticsEnabled'] == true;
    bool prioritySupport = plan?['prioritySupport'] == true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            isEdit ? 'Edit Plan' : 'Create Plan',
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: (MediaQuery.sizeOf(context).width * 0.9).clamp(280.0, 500.0),
              ),
              child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ─── Manual / input-based fields (above) ───
                      Text('Basic info', style: sectionStyle),
                      const SizedBox(height: 6),
                      TextField(
                        controller: displayNameController,
                        decoration: InputDecoration(
                          labelText: 'Display Name *',
                          hintText: 'e.g., Silver Plan - Retail',
                          helperText: 'Name shown on plan cards',
                          helperStyle: mutedStyle,
                          helperMaxLines: 2,
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Business Category *',
                          hintText: 'Shop type or All',
                          helperText: 'Retail, restaurant, or All',
                          helperStyle: mutedStyle,
                          helperMaxLines: 1,
                          isDense: true,
                        ),
                        isExpanded: true,
                        menuMaxHeight: 280,
                        items: [
                          const DropdownMenuItem(value: 'all', child: Text('All categories')),
                          ..._categories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category['value'],
                              child: Text(category['label'] ?? category['value'], overflow: TextOverflow.ellipsis),
                            );
                          }),
                        ],
                        onChanged: (value) => setDialogState(() => selectedCategory = value),
                        validator: (value) => (value == null || value.isEmpty) ? 'Select category' : null,
                      ),
                      const SizedBox(height: 14),
                      Text('Pricing', style: sectionStyle),
                      const SizedBox(height: 6),
                      TextField(
                        controller: priceController,
                        decoration: InputDecoration(
                          labelText: 'Monthly Price (₹) *',
                          hintText: 'e.g., 999',
                          helperText: 'Amount per month',
                          helperStyle: mutedStyle,
                          helperMaxLines: 1,
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                      Text('Offer & media limits', style: sectionStyle),
                      const SizedBox(height: 6),
                      TextField(
                        controller: offerLimitController,
                        decoration: InputDecoration(
                          labelText: 'Max Offers *',
                          hintText: '10 or -1 unlimited',
                          helperText: 'Max offers per shop',
                          helperStyle: mutedStyle,
                          helperMaxLines: 1,
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: maxPhotosController,
                        decoration: InputDecoration(
                          labelText: 'Max Photos Per Offer',
                          hintText: 'e.g., 5',
                          helperText: 'Photos per offer',
                          helperStyle: mutedStyle,
                          helperMaxLines: 1,
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                      Text('AI Banner Limit', style: sectionStyle),
                      const SizedBox(height: 6),
                      TextField(
                        controller: monthlyAiLimitController,
                        decoration: InputDecoration(
                          labelText: 'Monthly AI Banner Limit',
                          hintText: '2 or -1 unlimited',
                          helperText: 'AI banners per month',
                          helperStyle: mutedStyle,
                          helperMaxLines: 1,
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 18),
                      // ─── Pack price tier (drives ranking + AI tier in DB) ───
                      Text('Pack price tier', style: sectionStyle),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedTier,
                        decoration: InputDecoration(
                          labelText: 'Tier *',
                          hintText: 'Trial / Silver / Gold / Platinum',
                          helperText: 'Sets ranking & AI tier',
                          helperStyle: mutedStyle,
                          helperMaxLines: 1,
                          isDense: true,
                        ),
                        isExpanded: true,
                        menuMaxHeight: 220,
                        items: const [
                          DropdownMenuItem(value: 'trial', child: Text('Trial')),
                          DropdownMenuItem(value: 'silver', child: Text('Silver')),
                          DropdownMenuItem(value: 'gold', child: Text('Gold')),
                          DropdownMenuItem(value: 'platinum', child: Text('Platinum')),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setDialogState(() {
                            selectedTier = v;
                            if (v == 'trial') { selectedRankingTier = 'normal'; selectedAiCreditTier = 'silver'; }
                            else if (v == 'silver') { selectedRankingTier = 'normal'; selectedAiCreditTier = 'silver'; }
                            else if (v == 'gold') { selectedRankingTier = 'top3'; selectedAiCreditTier = 'gold'; }
                            else { selectedRankingTier = 'priority'; selectedAiCreditTier = 'platinum'; }
                          });
                        },
                        validator: (v) => (v == null || v.isEmpty) ? 'Select tier' : null,
                      ),
                      const SizedBox(height: 6),
                      CheckboxListTile(
                        title: const Text('Homepage Rotation', style: TextStyle(fontSize: 14)),
                        subtitle: Text('Platinum feature', style: mutedStyle),
                        value: homepageRotation,
                        onChanged: (v) => setDialogState(() => homepageRotation = v ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      CheckboxListTile(
                        title: const Text('AI Optimization Suggestions', style: TextStyle(fontSize: 14)),
                        subtitle: Text('AI tips', style: mutedStyle),
                        value: aiOptimizationSuggestions,
                        onChanged: (v) => setDialogState(() => aiOptimizationSuggestions = v ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      CheckboxListTile(
                        title: const Text('Analytics Enabled', style: TextStyle(fontSize: 14)),
                        subtitle: Text('Advanced analytics', style: mutedStyle),
                        value: analyticsEnabled,
                        onChanged: (v) => setDialogState(() => analyticsEnabled = v ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      CheckboxListTile(
                        title: const Text('Priority Support', style: TextStyle(fontSize: 14)),
                        subtitle: Text('Priority channel', style: mutedStyle),
                        value: prioritySupport,
                        onChanged: (v) => setDialogState(() => prioritySupport = v ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'Brief description for shopkeepers',
                          helperText: 'Optional',
                          helperStyle: mutedStyle,
                          helperMaxLines: 1,
                          isDense: true,
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedCategory == null || selectedCategory!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a category'),
                      backgroundColor: AppColors.red,
                    ),
                  );
                  return;
                }
                if (selectedTier.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a pack price tier'),
                      backgroundColor: AppColors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              child: Text(isEdit ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        if (isEdit) {
          // Update existing plan
          final planId = plan['_id'] ?? plan['id'];
          await SubscriptionService.instance.updatePlan(
            planId: planId,
            displayName: displayNameController.text.trim(),
            description: descriptionController.text.trim().isEmpty
                ? null
                : descriptionController.text.trim(),
            monthlyPrice: double.tryParse(priceController.text.trim()),
            category: selectedCategory,
            maxOffers: int.tryParse(offerLimitController.text.trim()),
            maxPhotosPerOffer: int.tryParse(maxPhotosController.text.trim()),
            monthlyAiLimit: int.tryParse(monthlyAiLimitController.text.trim()),
            rankingTier: selectedRankingTier,
            homepageRotation: homepageRotation,
            aiOptimizationSuggestions: aiOptimizationSuggestions,
            aiCreditTier: selectedAiCreditTier,
            tier: selectedTier,
            analyticsEnabled: analyticsEnabled,
            prioritySupport: prioritySupport,
          );

          if (!mounted) return;
          DialogHelper.showSuccessSnackBar(
            context,
            'Plan updated successfully',
          );
        } else {
          // Create new plan - auto-generate name from display name and category
          final displayName = displayNameController.text.trim();
          final category = selectedCategory!;

          // Generate plan ID: lowercase, replace spaces with underscores, add category
          final generatedName =
              '${displayName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}_$category'
                  .replaceAll(RegExp(r'_+'),
                      '_') // Replace multiple underscores with single
                  .replaceAll(RegExp(r'^_|_$'),
                      ''); // Remove leading/trailing underscores

          await SubscriptionService.instance.createPlan(
            name: generatedName,
            displayName: displayName,
            category: category,
            monthlyPrice: double.parse(priceController.text.trim()),
            description: descriptionController.text.trim().isEmpty
                ? null
                : descriptionController.text.trim(),
            maxOffers: int.parse(offerLimitController.text.trim()),
            maxPhotosPerOffer: int.tryParse(maxPhotosController.text.trim()) ?? 5,
            monthlyAiLimit: int.tryParse(monthlyAiLimitController.text.trim()) ?? 0,
            rankingTier: selectedRankingTier,
            homepageRotation: homepageRotation,
            aiOptimizationSuggestions: aiOptimizationSuggestions,
            aiCreditTier: selectedAiCreditTier,
            tier: selectedTier,
            analyticsEnabled: analyticsEnabled,
            prioritySupport: prioritySupport,
          );

          if (!mounted) return;
          DialogHelper.showSuccessSnackBar(
            context,
            'Plan created successfully',
          );
        }

        _loadPlans();
      } catch (e) {
        if (!mounted) return;
        DialogHelper.showErrorSnackBar(
          context,
          'Failed to ${isEdit ? 'update' : 'create'} plan: $e',
        );
      }
    }
  }

  Future<void> _togglePlanStatus(Map<String, dynamic> plan) async {
    try {
      final planId = plan['_id'] ?? plan['id'];
      final currentStatus = plan['isActive'] as bool? ?? true;

      await SubscriptionService.instance.updatePlan(
        planId: planId,
        isActive: !currentStatus,
      );

      if (!mounted) return;
      DialogHelper.showSuccessSnackBar(
        context,
        'Plan ${!currentStatus ? 'activated' : 'deactivated'} successfully',
      );
      _loadPlans();
    } catch (e) {
      if (!mounted) return;
      DialogHelper.showErrorSnackBar(
        context,
        'Failed to toggle plan status: $e',
      );
    }
  }

  Future<void> _deletePlan(Map<String, dynamic> plan) async {
    final displayName = plan['displayName'] ?? plan['name'] ?? 'this plan';
    final confirm = await DialogHelper.showConfirmDialog(
      context: context,
      title: 'Delete Plan',
      message: 'Are you sure you want to delete "$displayName"?',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (!confirm) return;

    try {
      final planId = plan['_id'] ?? plan['id'];
      await SubscriptionService.instance.deletePlan(planId);

      if (!mounted) return;
      DialogHelper.showSuccessSnackBar(context, 'Plan deleted successfully');
      _loadPlans();
    } catch (e) {
      if (!mounted) return;
      DialogHelper.showErrorSnackBar(
        context,
        'Failed to delete plan: $e',
      );
    }
  }
}

// ============ Subscriptions Management Tab ============
class SubscriptionsManagementTab extends StatefulWidget {
  const SubscriptionsManagementTab({super.key});

  @override
  State<SubscriptionsManagementTab> createState() =>
      _SubscriptionsManagementTabState();
}

class _SubscriptionsManagementTabState
    extends State<SubscriptionsManagementTab> {
  List<Map<String, dynamic>> _subscriptions = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all'; // all, active, expired
  int _page = 1;
  int _totalPages = 1;
  int _pageSize = 20;
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
    _cityController.addListener(_onLocationFilterChanged);
    _pincodeController.addListener(_onLocationFilterChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _cityController.removeListener(_onLocationFilterChanged);
    _pincodeController.removeListener(_onLocationFilterChanged);
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _onLocationFilterChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _debounceTimer = null;
      setState(() => _page = 1);
      _loadSubscriptions();
    });
  }

  Future<void> _loadSubscriptions() async {
    setState(() => _loading = true);
    try {
      String? statusFilter;
      if (_filter == 'active') statusFilter = 'active';
      if (_filter == 'expired') statusFilter = 'expired';

      final city = _cityController.text.trim();
      final pincode = _pincodeController.text.trim();

      final result = await SubscriptionService.instance.getAllSubscriptions(
        status: statusFilter,
        city: city.isEmpty ? null : city,
        pincode: pincode.isEmpty ? null : pincode,
        page: _page,
        limit: _pageSize,
      );

      if (!mounted) return;
      setState(() {
        _subscriptions = List<Map<String, dynamic>>.from(
          result['subscriptions'] ?? [],
        );
        final pagination = result['pagination'] as Map<String, dynamic>? ?? {};
        _page = pagination['page'] ?? _page;
        _totalPages = pagination['pages'] ?? _totalPages;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
      DialogHelper.showErrorSnackBar(
          context, 'Failed to load subscriptions: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredSubscriptions {
    if (_filter == 'all') return _subscriptions;
    return _subscriptions.where((s) => s['status'] == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final activeCount =
        _subscriptions.where((s) => s['status'] == 'active').length;
    final expiredCount =
        _subscriptions.where((s) => s['status'] == 'expired').length;

    return DataStateWrapper(
      loading: _loading,
      error: _error,
      isEmpty: _subscriptions.isEmpty,
      onRetry: _loadSubscriptions,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GradientCard(
                        gradient: const LinearGradient(
                          colors: [AppColors.cardBackground, AppColors.highlight],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.textSecondary,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$activeCount',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Active',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientCard(
                      gradient: const LinearGradient(
                        colors: [AppColors.cardBackground, AppColors.highlight],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.cancel_rounded,
                            color: AppColors.textSecondary,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$expiredCount',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Expired',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'all', label: Text('All')),
                  ButtonSegment(value: 'active', label: Text('Active')),
                  ButtonSegment(value: 'expired', label: Text('Expired')),
                ],
                selected: {_filter},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _filter = newSelection.first;
                    _page = 1;
                  });
                  _loadSubscriptions();
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        hintText: 'e.g. Pune',
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: (_) {
                        setState(() => _page = 1);
                        _loadSubscriptions();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _pincodeController,
                      decoration: const InputDecoration(
                        labelText: 'Pincode',
                        hintText: 'e.g. 411001',
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      keyboardType: TextInputType.number,
                      onSubmitted: (_) {
                        setState(() => _page = 1);
                        _loadSubscriptions();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredSubscriptions.length,
            itemBuilder: (context, index) {
              final sub = _filteredSubscriptions[index];
              return _buildSubscriptionCard(sub);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Page $_page of $_totalPages',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _page > 1 && !_loading
                        ? () {
                            setState(() {
                              _page -= 1;
                            });
                            _loadSubscriptions();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Prev'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _page < _totalPages && !_loading
                        ? () {
                            setState(() {
                              _page += 1;
                            });
                            _loadSubscriptions();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('Next'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildSubscriptionCard(Map<String, dynamic> sub) {
    final isActive = sub['status'] == 'active';

    // Extract shopkeeper info (prefer populated relation from API)
    final dynamic shopkeeperData = sub['shopkeeper'] ?? sub['shopkeeperId'];
    final shopName = shopkeeperData is Map
        ? (shopkeeperData['name'] ?? 'Unknown Shop')
        : 'Unknown Shop';

    // Extract plan info (prefer populated relation from API)
    final dynamic planData = sub['plan'] ?? sub['planId'];
    final planName = planData is Map
        ? (planData['displayName'] ?? planData['name'] ?? 'Unknown Plan')
        : 'Unknown Plan';
    final price = planData is Map
        ? (planData['monthlyPrice'] ?? sub['actualPrice'] ?? 0)
        : (sub['actualPrice'] ?? 0);

    // Format dates
    final startDate = sub['startDate'] != null
        ? DateTime.parse(sub['startDate']).toString().split(' ')[0]
        : 'N/A';
    final endDate = sub['endDate'] != null
        ? DateTime.parse(sub['endDate']).toString().split(' ')[0]
        : 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.green.withValues(alpha: 0.1)
                : AppColors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isActive ? AppColors.green : AppColors.red,
          ),
        ),
        title: Text(shopName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plan: $planName - ₹$price'),
            Text('$startDate to $endDate'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'renew') {
              _renewSubscription(sub);
            } else if (value == 'cancel') {
              _cancelSubscription(sub);
            }
          },
          itemBuilder: (context) => [
            if (sub['status'] == 'expired')
              const PopupMenuItem(
                value: 'renew',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Renew'),
                  ],
                ),
              ),
            if (sub['status'] == 'active')
              const PopupMenuItem(
                value: 'cancel',
                child: Row(
                  children: [
                    Icon(Icons.cancel_rounded,
                        size: 20, color: AppColors.error),
                    SizedBox(width: 12),
                    Text('Cancel', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _renewSubscription(Map<String, dynamic> sub) async {
    try {
      final subscriptionId = sub['_id'] ?? sub['id'];
      await SubscriptionService.instance.renewSubscription(
        subscriptionId: subscriptionId,
        durationMonths: 1,
      );

      if (!mounted) return;
      DialogHelper.showSuccessSnackBar(
        context,
        'Subscription renewed successfully',
      );
      _loadSubscriptions();
    } catch (e) {
      if (!mounted) return;
      DialogHelper.showErrorSnackBar(
        context,
        'Failed to renew subscription: $e',
      );
    }
  }

  Future<void> _cancelSubscription(Map<String, dynamic> sub) async {
    // Extract shop name
    final shopkeeper = sub['shopkeeperId'];
    final shopName =
        shopkeeper is Map ? (shopkeeper['name'] ?? 'this shop') : 'this shop';

    final confirm = await DialogHelper.showConfirmDialog(
      context: context,
      title: 'Cancel Subscription',
      message: 'Are you sure you want to cancel subscription for "$shopName"?',
      confirmText: 'Cancel Subscription',
      isDestructive: true,
    );

    if (!confirm) return;

    try {
      final subscriptionId = sub['_id'] ?? sub['id'];
      await SubscriptionService.instance.cancelSubscription(
        subscriptionId,
        'Cancelled by admin',
      );

      if (!mounted) return;
      DialogHelper.showSuccessSnackBar(
        context,
        'Subscription cancelled successfully',
      );
      _loadSubscriptions();
    } catch (e) {
      if (!mounted) return;
      DialogHelper.showErrorSnackBar(
        context,
        'Failed to cancel subscription: $e',
      );
    }
  }
}

// ============ AI Credit Packs Tab ============
class AiCreditPacksTab extends StatefulWidget {
  const AiCreditPacksTab({super.key});

  @override
  State<AiCreditPacksTab> createState() => _AiCreditPacksTabState();
}

class _AiCreditPacksTabState extends State<AiCreditPacksTab> {
  List<Map<String, dynamic>> _packs = [];
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  String? _error;
  String? _filterCategory;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      await Future.wait([_loadCategories(), _loadPacks()]);
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await SubscriptionService.instance.getCategories();
      if (!mounted) return;
      setState(() => _categories = categories);
    } catch (_) {
      if (!mounted) return;
      setState(() => _categories = []);
    }
  }

  Future<void> _loadPacks() async {
    try {
      final packs = await SubscriptionService.instance.getAiCreditPacks(
        category: _filterCategory,
      );
      if (!mounted) return;
      setState(() {
        _packs = packs;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Always-visible header with Add Pack button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_packs.length} AI Credit Packs',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Flexible(
                fit: FlexFit.loose,
                child: ElevatedButton.icon(
                  onPressed: () => _showPackDialog(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Pack'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: Row(
            children: [
              Text('Category: ', style: Theme.of(context).textTheme.bodyMedium),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: (_filterCategory == null ||
                          _filterCategory == 'all' ||
                          (_filterCategory?.isEmpty ?? true) ||
                          !_categories.any((c) => c['value'] == _filterCategory))
                      ? 'all'
                      : _filterCategory!,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('All categories')),
                    ..._categories.map<DropdownMenuItem<String>>((cat) {
                      final value = cat['value'] as String? ?? '';
                      final label = cat['label'] as String? ?? value;
                      return DropdownMenuItem(
                        value: value,
                        child: Text(label),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterCategory = (value == 'all' || value == null) ? null : value;
                      _loading = true;
                    });
                    _loadPacks();
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : (_error != null && _error!.isNotEmpty)
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 48, color: AppColors.error),
                          const SizedBox(height: 12),
                          Text(_error!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadData,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try again'),
                          ),
                        ],
                      ),
                    )
                  : _packs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inbox_rounded,
                                  size: 48,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              Text(
                                'No AI packs yet. Tap "Add Pack" above to create one.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _packs.length,
                          itemBuilder: (context, index) {
                            final pack = _packs[index];
                            return FadeInUp(
                              delay: Duration(milliseconds: 100 * index),
                              child: _buildPackCard(pack),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildPackCard(Map<String, dynamic> pack) {
    final sku = pack['sku'] ?? '';
    final displayName = pack['displayName'] ?? sku;
    final category = pack['category'] as String? ?? 'all';
    final credits = pack['credits'] ?? 0;
    final priceSilver = pack['priceSilver'] ?? 0;
    final priceGold = pack['priceGold'] ?? 0;
    final pricePlatinum = pack['pricePlatinum'] ?? 0;
    final isActive = pack['isActive'] as bool? ?? true;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
        ),
        title: Text(displayName),
        subtitle: Text(
          '$credits credits • $category • Silver: ₹$priceSilver | Gold: ₹$priceGold | Platinum: ₹$pricePlatinum',
          style: TextStyle(fontSize: 12, color: AppColors.grey600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Inactive', style: TextStyle(color: AppColors.white, fontSize: 12)),
              ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') _showPackDialog(pack: pack);
                else if (v == 'delete') _deletePack(pack);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 20), SizedBox(width: 12), Text('Edit')])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, size: 20, color: AppColors.error), SizedBox(width: 12), Text('Delete', style: TextStyle(color: AppColors.error))])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPackDialog({Map<String, dynamic>? pack}) async {
    final isEdit = pack != null;
    List<Map<String, dynamic>> categories = [];
    try {
      categories = await SubscriptionService.instance.getCategories();
    } catch (_) {}

    final mutedStyle = TextStyle(color: AppColors.textMuted, fontSize: 10);
    final sectionStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted);

    final skuController = TextEditingController(text: pack?['sku'] ?? '');
    final displayNameController = TextEditingController(text: pack?['displayName'] ?? '');
    final creditsController = TextEditingController(text: (pack?['credits'] ?? 0).toString());
    final priceSilverController = TextEditingController(text: (pack?['priceSilver'] ?? 0).toString());
    final priceGoldController = TextEditingController(text: (pack?['priceGold'] ?? 0).toString());
    final pricePlatinumController = TextEditingController(text: (pack?['pricePlatinum'] ?? 0).toString());
    String? selectedCategory = pack?['category'] as String? ?? 'all';
    if (selectedCategory != 'all' && !categories.any((c) => c['value'] == selectedCategory)) {
      selectedCategory = 'all';
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            isEdit ? 'Edit Pack' : 'Add AI Credit Pack',
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: (MediaQuery.sizeOf(context).width * 0.9).clamp(280.0, 500.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Basic info', style: sectionStyle),
                  const SizedBox(height: 6),
                  if (isEdit)
                    TextField(
                      controller: skuController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'SKU',
                        helperText: 'Generated at create; cannot be changed',
                        helperStyle: mutedStyle,
                        isDense: true,
                      ),
                    )
                  else
                    Text(
                      'SKU will be generated from display name + category (e.g. starter_100_retail)',
                      style: mutedStyle,
                    ),
                  if (isEdit) const SizedBox(height: 10),
                  TextField(
                    controller: displayNameController,
                    decoration: InputDecoration(
                      labelText: 'Display Name *',
                      hintText: 'e.g. Starter 100 Credits',
                      helperText: 'Name shown on pack cards',
                      helperStyle: mutedStyle,
                      helperMaxLines: 1,
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: (selectedCategory == null || (selectedCategory?.isEmpty ?? true) || selectedCategory == 'all' ||
                            !categories.any((c) => c['value'] == selectedCategory))
                        ? 'all'
                        : selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Shop Category *',
                      helperText: 'Packs with "All" or this category are shown to shopkeepers',
                      helperStyle: mutedStyle,
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: 'all', child: Text('All categories')),
                      ...categories.map<DropdownMenuItem<String>>((cat) {
                        final value = cat['value'] as String? ?? '';
                        final label = cat['label'] as String? ?? value;
                        return DropdownMenuItem(value: value, child: Text(label));
                      }),
                    ],
                    onChanged: (value) => setDialogState(() => selectedCategory = value ?? 'all'),
                  ),
                  const SizedBox(height: 14),
                  Text('Credits & pricing', style: sectionStyle),
                  const SizedBox(height: 6),
                  TextField(
                    controller: creditsController,
                    decoration: InputDecoration(
                      labelText: 'Credits *',
                      hintText: 'e.g. 100',
                      helperText: 'AI credits included in this pack',
                      helperStyle: mutedStyle,
                      helperMaxLines: 1,
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: priceSilverController,
                    decoration: InputDecoration(
                      labelText: 'Price (Silver tier) ₹ *',
                      hintText: 'e.g. 199',
                      helperText: 'Price for Silver subscription tier',
                      helperStyle: mutedStyle,
                      helperMaxLines: 1,
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: priceGoldController,
                    decoration: InputDecoration(
                      labelText: 'Price (Gold tier) ₹ *',
                      hintText: 'e.g. 179',
                      helperText: 'Price for Gold subscription tier',
                      helperStyle: mutedStyle,
                      helperMaxLines: 1,
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: pricePlatinumController,
                    decoration: InputDecoration(
                      labelText: 'Price (Platinum tier) ₹ *',
                      hintText: 'e.g. 149',
                      helperText: 'Price for Platinum subscription tier',
                      helperStyle: mutedStyle,
                      helperMaxLines: 1,
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (displayNameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Display name is required'),
                    backgroundColor: AppColors.red,
                  ));
                  return;
                }
                final cat = selectedCategory ?? 'all';
                if (cat.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Please select a category'),
                    backgroundColor: AppColors.red,
                  ));
                  return;
                }
                final creditsStr = creditsController.text.trim();
                final creditsVal = int.tryParse(creditsStr);
                if (creditsStr.isEmpty || creditsVal == null || creditsVal < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Credits must be a valid number (0 or more)'),
                    backgroundColor: AppColors.red,
                  ));
                  return;
                }
                final priceSilverVal = double.tryParse(priceSilverController.text.trim());
                final priceGoldVal = double.tryParse(priceGoldController.text.trim());
                final pricePlatinumVal = double.tryParse(pricePlatinumController.text.trim());
                if (priceSilverVal == null || priceSilverVal < 0 ||
                    priceGoldVal == null || priceGoldVal < 0 ||
                    pricePlatinumVal == null || pricePlatinumVal < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('All prices must be valid numbers (0 or more)'),
                    backgroundColor: AppColors.red,
                  ));
                  return;
                }
                Navigator.pop(context, true);
              },
              child: Text(isEdit ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );

    if (result != true || !mounted) return;
    final cat = selectedCategory ?? 'all';
    try {
      if (isEdit) {
        await SubscriptionService.instance.updateAiCreditPack(
          packId: pack['id'] ?? pack['_id'],
          displayName: displayNameController.text.trim(),
          category: cat.isEmpty ? null : cat,
          credits: int.tryParse(creditsController.text.trim()),
          priceSilver: double.tryParse(priceSilverController.text.trim()),
          priceGold: double.tryParse(priceGoldController.text.trim()),
          pricePlatinum: double.tryParse(pricePlatinumController.text.trim()),
        );
        DialogHelper.showSuccessSnackBar(context, 'Pack updated successfully');
      } else {
        await SubscriptionService.instance.createAiCreditPack(
          displayName: displayNameController.text.trim(),
          category: cat,
          credits: int.tryParse(creditsController.text.trim()) ?? 0,
          priceSilver: double.tryParse(priceSilverController.text.trim()) ?? 0,
          priceGold: double.tryParse(priceGoldController.text.trim()) ?? 0,
          pricePlatinum: double.tryParse(pricePlatinumController.text.trim()) ?? 0,
        );
        DialogHelper.showSuccessSnackBar(context, 'Pack created successfully');
      }
      _loadData();
    } catch (e) {
      if (!mounted) return;
      DialogHelper.showErrorSnackBar(context, 'Failed: $e');
    }
  }

  Future<void> _deletePack(Map<String, dynamic> pack) async {
    final confirm = await DialogHelper.showConfirmDialog(
      context: context,
      title: 'Deactivate Pack',
      message: 'Deactivate "${pack['displayName'] ?? pack['sku']}"?',
      confirmText: 'Deactivate',
      isDestructive: true,
    );
    if (!confirm || !mounted) return;
    try {
      await SubscriptionService.instance.deleteAiCreditPack(pack['id'] ?? pack['_id']);
      if (!mounted) return;
      DialogHelper.showSuccessSnackBar(context, 'Pack deactivated');
      _loadData();
    } catch (e) {
      if (!mounted) return;
      DialogHelper.showErrorSnackBar(context, 'Failed: $e');
    }
  }
}

// ============ Analytics Tab ============
class SubscriptionAnalyticsTab extends StatefulWidget {
  const SubscriptionAnalyticsTab({super.key});

  @override
  State<SubscriptionAnalyticsTab> createState() =>
      _SubscriptionAnalyticsTabState();
}

class _SubscriptionAnalyticsTabState extends State<SubscriptionAnalyticsTab> {
  bool _loading = true;
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _revenueData;
  Map<String, dynamic>? _metricsData;

  bool _metricsLoading = false;
  final TextEditingController _pincodeFilterController =
      TextEditingController(text: '');
  final TextEditingController _cityFilterController =
      TextEditingController(text: '');
  String _statusFilter = 'active';

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  @override
  void dispose() {
    _pincodeFilterController.dispose();
    _cityFilterController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        SubscriptionService.instance.getMonitoringDashboard(),
        SubscriptionService.instance.getRevenueIntelligence(),
        SubscriptionService.instance.getSubscriptionMetrics(
          status: _statusFilter,
          pincode: _pincodeFilterController.text.trim().isEmpty
              ? null
              : _pincodeFilterController.text.trim(),
          city: _cityFilterController.text.trim().isEmpty
              ? null
              : _cityFilterController.text.trim(),
        ),
      ]);

      if (!mounted) return;
      setState(() {
        _dashboardData = results[0];
        _revenueData = results[1];
        _metricsData = results[2];
        _loading = false;
        _metricsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      DialogHelper.showErrorSnackBar(
        context,
        'Failed to load analytics: $e',
      );
    }
  }

  Future<void> _reloadMetrics() async {
    setState(() {
      _metricsLoading = true;
    });
    try {
      final data = await SubscriptionService.instance.getSubscriptionMetrics(
        status: _statusFilter,
        pincode: _pincodeFilterController.text.trim().isEmpty
            ? null
            : _pincodeFilterController.text.trim(),
        city: _cityFilterController.text.trim().isEmpty
            ? null
            : _cityFilterController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _metricsData = data;
        _metricsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _metricsLoading = false;
      });
      DialogHelper.showErrorSnackBar(
        context,
        'Failed to load subscription metrics: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final mrr = _dashboardData?['mrr'] ?? 0;
    final activeCount =
        _dashboardData?['statusCounts']?['active']?['count'] ?? 0;
    final activeRevenue =
        _dashboardData?['statusCounts']?['active']?['revenue'] ?? 0;
    final expiredCount =
        _dashboardData?['statusCounts']?['expired']?['count'] ?? 0;

    final planDistribution =
        _revenueData?['planDistribution'] as List<dynamic>? ?? [];

    final tiersTotals = _metricsData?['totals']?['byTier'] as Map? ?? {};
    final totalFiltered = _metricsData?['totals']?['total'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Analytics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GradientCard(
                  gradient: const LinearGradient(
                    colors: [AppColors.cardBackground, AppColors.highlight],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.currency_rupee_rounded,
                          color: AppColors.textSecondary, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        '₹${activeRevenue.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Total Revenue',
                        style: TextStyle(color: AppColors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientCard(
                  gradient: const LinearGradient(
                    colors: [AppColors.cardBackground, AppColors.highlight],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.trending_up_rounded,
                          color: AppColors.textSecondary, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        '₹${mrr.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'MRR',
                        style: TextStyle(color: AppColors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.green, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          '$activeCount',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('Active'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(Icons.cancel_rounded,
                            color: AppColors.red, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          '$expiredCount',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('Expired'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Subscription Metrics (filters)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'See how many shops are subscribed by pincode / city and tier.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          // Filters stacked vertically to avoid layout issues on small screens
          TextField(
            controller: _pincodeFilterController,
            decoration: const InputDecoration(
              labelText: 'Pincode (optional)',
              hintText: 'e.g. 411001',
              isDense: true,
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _cityFilterController,
            decoration: const InputDecoration(
              labelText: 'City (optional)',
              hintText: 'e.g. Pune',
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _statusFilter,
            decoration: const InputDecoration(
              labelText: 'Status',
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: 'active', child: Text('Active')),
              DropdownMenuItem(value: 'expired', child: Text('Expired')),
              DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
              DropdownMenuItem(value: 'all', child: Text('All')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _statusFilter = value;
              });
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _metricsLoading ? null : _reloadMetrics,
              icon: _metricsLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Apply'),
            ),
          ),
          const SizedBox(height: 16),
          if (_metricsData == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No metrics loaded yet'),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMetricCard('Total', '$totalFiltered'),
                _buildMetricCard('Silver', '${tiersTotals['silver'] ?? 0}'),
                _buildMetricCard('Gold', '${tiersTotals['gold'] ?? 0}'),
                _buildMetricCard(
                    'Platinum', '${tiersTotals['platinum'] ?? 0}'),
              ],
            ),
          const SizedBox(height: 24),
          Text(
            'Plan Distribution',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (planDistribution.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text('No plan distribution data available'),
                ),
              ),
            )
          else
            ...planDistribution.map((item) {
              final planName = item['_id'] ?? 'Unknown';
              final count = item['count'] ?? 0;
              final revenue = item['revenue'] ?? 0;
              final colors = [
                AppColors.blue,
                AppColors.purple,
                AppColors.orange,
                AppColors.green,
                AppColors.red,
              ];
              final color =
                  colors[planDistribution.indexOf(item) % colors.length];

              return _buildPlanDistribution(
                planName,
                count,
                revenue.toDouble(),
                color,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPlanDistribution(
      String plan, int count, double revenue, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '$count active subscriptions',
                    style: TextStyle(
                      color: AppColors.grey600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '₹${revenue.toStringAsFixed(0)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value) {
    return SizedBox(
      width: 150,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(label),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
