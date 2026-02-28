import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/theme_helper.dart';
import '../../core/utils/dialog_helper.dart';
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
    _tabController = TabController(length: 3, vsync: this);
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
      setState(() => _loading = false);
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_plans.length} Plans',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showPlanDialog(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.black,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _plans.length,
            itemBuilder: (context, index) {
              final plan = _plans[index];
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
    final durationDays = plan['durationDays'] ?? plan['duration'] ?? 30;
    final maxOffers = plan['maxOffers'] ?? plan['offerLimit'] ?? 0;

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
                    'Duration',
                    '$durationDays days',
                    Icons.calendar_today_rounded,
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

    // Use correct API field names
    final displayNameController = TextEditingController(
      text: plan?['displayName'] ?? plan?['name'] ?? '',
    );
    final priceController = TextEditingController(
      text: (plan?['monthlyPrice'] ?? plan?['price'] ?? '').toString(),
    );
    final durationController = TextEditingController(
      text: (plan?['durationDays'] ?? plan?['duration'] ?? 30).toString(),
    );
    final offerLimitController = TextEditingController(
      text: (plan?['maxOffers'] ?? plan?['offerLimit'] ?? 10).toString(),
    );
    final descriptionController = TextEditingController(
      text: plan?['description'] ?? '',
    );

    String? selectedCategory = plan?['category'];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Plan' : 'Create Plan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name *',
                    hintText: 'e.g., Basic Plan - Retail',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    hintText: 'Select business category',
                  ),
                  isExpanded: true,
                  items: _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category['value'],
                      child: Text(category['label']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Monthly Price (₹) *',
                    hintText: 'e.g., 999',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (days) *',
                    hintText: 'e.g., 30',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: offerLimitController,
                  decoration: const InputDecoration(
                    labelText: 'Max Offers *',
                    hintText: 'e.g., 10 or -1 for unlimited',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Brief description of the plan',
                  ),
                  maxLines: 2,
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
              onPressed: () {
                if (selectedCategory == null ||
                    (selectedCategory?.isEmpty ?? true)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a category'),
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
            durationDays: int.tryParse(durationController.text.trim()),
            category: selectedCategory,
            maxOffers: int.tryParse(offerLimitController.text.trim()),
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
            durationDays: int.parse(durationController.text.trim()),
            description: descriptionController.text.trim().isEmpty
                ? null
                : descriptionController.text.trim(),
            maxOffers: int.parse(offerLimitController.text.trim()),
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
  String _filter = 'all'; // all, active, expired

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    setState(() => _loading = true);
    try {
      String? statusFilter;
      if (_filter == 'active') statusFilter = 'active';
      if (_filter == 'expired') statusFilter = 'expired';

      final result = await SubscriptionService.instance.getAllSubscriptions(
        status: statusFilter,
      );

      if (!mounted) return;
      setState(() {
        _subscriptions = List<Map<String, dynamic>>.from(
          result['subscriptions'] ?? [],
        );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final activeCount =
        _subscriptions.where((s) => s['status'] == 'active').length;
    final expiredCount =
        _subscriptions.where((s) => s['status'] == 'expired').length;

    return Column(
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
                  });
                },
              ),
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
      ],
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

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        SubscriptionService.instance.getMonitoringDashboard(),
        SubscriptionService.instance.getRevenueIntelligence(),
      ]);

      if (!mounted) return;
      setState(() {
        _dashboardData = results[0];
        _revenueData = results[1];
        _loading = false;
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
}
