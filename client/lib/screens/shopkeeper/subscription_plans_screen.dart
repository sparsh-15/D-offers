import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Subscription Plan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[50],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _plans.isEmpty
              ? _buildEmptyState()
              : _buildPlansList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Plans Available',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'There are no subscription plans available for your business category at the moment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
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
          delay: Duration(milliseconds: 100 * index),
          child: _buildPlanCard(plan),
        );
      },
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plan Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '$monthlyPrice',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '/$durationDays days',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Plan Details
              _buildDetailRow(
                Icons.local_offer_rounded,
                'Offers',
                maxOffers == -1 ? 'Unlimited' : '$maxOffers per month',
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.photo_library_rounded,
                'Photos',
                '$maxPhotos per offer',
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.analytics_rounded,
                'Analytics',
                analyticsEnabled ? 'Enabled' : 'Basic',
                color: analyticsEnabled ? Colors.green[700] : Colors.grey[600],
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.support_agent_rounded,
                'Support',
                prioritySupport ? 'Priority' : 'Standard',
                color: prioritySupport ? Colors.green[700] : Colors.grey[600],
              ),

              // Features
              if (features.isNotEmpty) ...[
                const SizedBox(height: 20),
                Divider(color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  'Features',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.green[700],
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],

              const SizedBox(height: 20),

              // Subscribe Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _subscribeToPlan(plan),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Subscribe Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
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
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: color ?? Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _subscribeToPlan(Map<String, dynamic> plan) async {
    // final planId = plan['_id'] ?? plan['id']; // TODO: Use for payment integration
    final displayName = plan['displayName'] ?? plan['name'];
    final monthlyPrice = plan['monthlyPrice'] ?? 0;

    final confirm = await DialogHelper.showConfirmDialog(
      context: context,
      title: 'Subscribe to $displayName',
      message:
          'You are about to subscribe to $displayName for ₹$monthlyPrice. Continue?',
      confirmText: 'Subscribe',
    );

    if (!confirm) return;

    // TODO: Implement payment flow and subscription creation
    // For now, show a message
    if (!mounted) return;
    DialogHelper.showInfoSnackBar(
      context,
      'Payment integration coming soon! Plan: $displayName',
    );
  }
}
