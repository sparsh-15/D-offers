import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'ai_credit_packs_screen.dart';
import 'subscription_plans_screen.dart';

class CurrentPlanDetailsPage extends StatelessWidget {
  const CurrentPlanDetailsPage({
    super.key,
    required this.subscription,
    required this.offerCount,
    required this.shopCategory,
  });

  final Map<String, dynamic> subscription;
  final int offerCount;
  final String shopCategory;

  DateTime? _parseSubscriptionDate(dynamic value) {
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

  String _formatDate(DateTime date) {
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

  @override
  Widget build(BuildContext context) {
    final planSnapshot =
        subscription['planSnapshot'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final isTrial = subscription['trial'] == true || planSnapshot['isTrial'] == true;
    final isFreeStarter =
        subscription['freeStarter'] == true || planSnapshot['tier'] == 'free';
    final planName = isTrial
        ? (planSnapshot['trialDisplayName'] ?? 'Free Trial')
        : (planSnapshot['displayName'] ?? planSnapshot['name'] ?? 'Plan');

    final status = (subscription['status'] ?? 'inactive').toString();
    final startDate = _parseSubscriptionDate(subscription['startDate']);
    final endDate = _parseSubscriptionDate(subscription['endDate']);
    final daysLeft = _calculateDaysLeft(endDate);
    final isExpired = status.toLowerCase() == 'expired' || (daysLeft != null && daysLeft < 0);

    final statusColor = isExpired
        ? AppColors.error
        : status.toLowerCase() == 'active'
            ? AppColors.accent
            : status.toLowerCase() == 'pending'
                ? AppColors.warning
                : AppColors.textSecondary;

    final Object? maxOffers = planSnapshot['maxOffers'];
    final offerUsage = maxOffers == null || maxOffers == -1
        ? 'Unlimited offers'
        : '$offerCount / $maxOffers offers used';

    final Object? monthlyAiLimit = planSnapshot['monthlyAiLimit'];
    final int usedThisCycle = (subscription['usedThisCycle'] as num?)?.toInt() ?? 0;
    final int extraCredits =
        (subscription['extraCreditsCurrentCycle'] as num?)?.toInt() ?? 0;
    final aiUsage = monthlyAiLimit == null || monthlyAiLimit == -1
        ? 'AI banners: Unlimited'
        : 'AI banners: $usedThisCycle / ${ (monthlyAiLimit as num?)?.toInt() ?? 0 } used'
            '${extraCredits > 0 ? ' (+$extraCredits extra)' : ''}';

    final List<dynamic> rawFeatures = (planSnapshot['features'] as List?) ?? const [];
    final features = rawFeatures.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();

    String validityLabel = 'No validity data';
    if (endDate != null) {
      if (isExpired) {
        validityLabel = 'Expired on ${_formatDate(endDate)}';
      } else if (daysLeft == null) {
        validityLabel = 'Ends on ${_formatDate(endDate)}';
      } else if (daysLeft == 0) {
        validityLabel = 'Expires today';
      } else {
        validityLabel = '$daysLeft days left';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Plan Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.elevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        planName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
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
                const SizedBox(height: 8),
                Text(
                  validityLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isExpired ? AppColors.error : AppColors.textSecondary,
                      ),
                ),
                if (startDate != null)
                  Text(
                    'Started: ${_formatDate(startDate)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                if (endDate != null)
                  Text(
                    'Ends: ${_formatDate(endDate)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (isTrial)
                      _pill(context, 'Trial'),
                    if (isFreeStarter)
                      _pill(context, 'Free Starter'),
                    if (!isTrial && !isFreeStarter)
                      _pill(context, 'Paid Plan'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _detailsCard(
            context,
            title: 'Usage & Limits',
            lines: [
              offerUsage,
              aiUsage,
            ],
          ),
          if (features.isNotEmpty) ...[
            const SizedBox(height: 12),
            _detailsCard(
              context,
              title: 'Plan Features',
              lines: features,
            ),
          ],
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SubscriptionPlansScreen(
                    shopCategory: shopCategory,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.trending_up_rounded),
            label: const Text('Upgrade / View All Plans'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AiCreditPacksScreen(),
                ),
              );
            },
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Manage AI Packs'),
          ),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Widget _detailsCard(BuildContext context, {required String title, required List<String> lines}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_circle_outline_rounded, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
