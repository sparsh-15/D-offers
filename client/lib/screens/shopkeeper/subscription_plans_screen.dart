import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/theme_helper.dart';
import '../../services/subscription_service.dart';
import '../../widgets/data_state_wrapper.dart';
import 'payment_screen.dart';

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
  String? _error;

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
        context,
        'Failed to load plans: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: ThemeHelper.buildBackButton(context),
        title: const Text('Choose Subscription Plan'),
      ),
      body: DataStateWrapper(
        loading: _loading,
        error: _error,
        isEmpty: _plans.isEmpty,
        onRetry: _loadPlans,
        emptyTitle: 'No Plans Available',
        emptyMessage:
            'There are no subscription plans available for your business category right now.',
        child: _buildPlansList(),
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
    final maxOffers = plan['maxOffers'] ?? 0;
    final maxPhotos = plan['maxPhotosPerOffer'] ?? 5;
    final analyticsEnabled = plan['analyticsEnabled'] ?? false;
    final prioritySupport = plan['prioritySupport'] ?? false;
    final monthlyAiLimit = plan['monthlyAiLimit'];
    final rankingTier = plan['rankingTier'] ?? 'normal';
    final aiCreditTier = plan['aiCreditTier'] ?? 'silver';
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
                      const Text(
                        '/month',
                        style: TextStyle(
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
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.auto_awesome_rounded,
              label: 'AI Banners',
              value: monthlyAiLimit == null || monthlyAiLimit == -1
                  ? 'Unlimited'
                  : '$monthlyAiLimit per month',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.trending_up_rounded,
              label: 'Ranking',
              value: rankingTier == 'top3'
                  ? 'Top 3'
                  : rankingTier == 'priority'
                      ? 'Priority'
                      : 'Standard',
              color: rankingTier != 'normal' ? AppColors.success : null,
            ),
            if (aiCreditTier != 'silver') ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                icon: Icons.discount_rounded,
                label: 'AI credits',
                value: 'Discounted ($aiCreditTier)',
                color: AppColors.success,
              ),
            ],
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

    // Navigate to payment screen
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          plan: plan,
          onPaymentSuccess: () {
            // Show success message
            DialogHelper.showSuccessSnackBar(
              context,
              'Successfully subscribed to $displayName!',
            );
            // Navigate back to dashboard or refresh
            Navigator.of(context).pop(); // Pop subscription plans screen
          },
        ),
      ),
    );
  }
}
