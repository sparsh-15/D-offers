import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/dialog_helper.dart';
import '../../services/subscription_service.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  final String shopCategory;

  const SubscriptionPlansScreen({
    super.key,
    required this.shopCategory,
  });

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  List<Map<String, dynamic>> _plans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _loading = true);
    try {
      final plans = await SubscriptionService.instance.getRecommendedPlans(
        widget.shopCategory,
      );

      if (!mounted) return;
      setState(() {
        _plans = plans;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      DialogHelper.showErrorSnackBar(
        context,
        'Failed to load plans: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Subscription Plan'),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            )
          : _plans.isEmpty
              ? _buildEmptyState()
              : _buildPlansList(),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 80,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              'No Plans Available',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'There are no subscription plans available for your business category right now.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _plans.length,
      itemBuilder: (context, index) {
        final plan = _plans[index];
        return FadeInUp(
          delay: Duration(milliseconds: 90 * index),
          child: _buildPlanCard(plan),
        );
      },
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final outlineColor = theme.dividerColor.withValues(alpha: 0.8);

    final displayName = plan['displayName'] ?? plan['name'] ?? 'Unnamed Plan';
    final description = plan['description'] ?? '';
    final monthlyPrice = plan['monthlyPrice'] ?? 0;
    final durationDays = plan['durationDays'] ?? 30;
    final maxOffers = plan['maxOffers'] ?? 0;
    final maxPhotos = plan['maxPhotosPerOffer'] ?? 5;
    final analyticsEnabled = plan['analyticsEnabled'] ?? false;
    final prioritySupport = plan['prioritySupport'] ?? false;
    final features = List<String>.from(plan['features'] ?? []);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: outlineColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rs.',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$monthlyPrice',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '/$durationDays days',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow(
              icon: Icons.local_offer_rounded,
              label: 'Offers',
              value: maxOffers == -1 ? 'Unlimited' : '$maxOffers per month',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.photo_library_rounded,
              label: 'Photos',
              value: '$maxPhotos per offer',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.analytics_rounded,
              label: 'Analytics',
              value: analyticsEnabled ? 'Enabled' : 'Basic',
              color: analyticsEnabled ? AppColors.success : null,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.support_agent_rounded,
              label: 'Support',
              value: prioritySupport ? 'Priority' : 'Standard',
              color: prioritySupport ? AppColors.success : null,
            ),
            if (features.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Features',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _subscribeToPlan(plan),
                child: const Text('Subscribe Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final valueColor = color ?? theme.textTheme.bodyMedium?.color;

    return Row(
      children: [
        Icon(
          icon,
          color: color ?? AppColors.primary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _subscribeToPlan(Map<String, dynamic> plan) async {
    final displayName = plan['displayName'] ?? plan['name'];
    final monthlyPrice = plan['monthlyPrice'] ?? 0;

    final confirm = await DialogHelper.showConfirmDialog(
      context: context,
      title: 'Subscribe to $displayName',
      message:
          'You are about to subscribe to $displayName for Rs.$monthlyPrice. Continue?',
      confirmText: 'Subscribe',
    );

    if (!confirm) return;

    if (!mounted) return;
    DialogHelper.showInfoSnackBar(
      context,
      'Payment integration coming soon. Plan: $displayName',
    );
  }
}
