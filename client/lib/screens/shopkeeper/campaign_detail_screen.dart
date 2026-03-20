import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/campaign_model.dart';
import '../../services/campaign_service.dart';
import '../../services/subscription_service.dart';
import 'subscription_plans_screen.dart';

class CampaignDetailScreen extends StatefulWidget {
  final String campaignId;
  final CampaignModel? initialCampaign;

  const CampaignDetailScreen({
    super.key,
    required this.campaignId,
    this.initialCampaign,
  });

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  CampaignModel? _campaign;
  Map<String, dynamic>? _subscription;
  bool _loading = true;
  bool _paying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _campaign = widget.initialCampaign;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        CampaignService.instance.getCampaign(widget.campaignId),
        SubscriptionService.instance.getSubscription(),
      ]);
      final campaign = results[0] as CampaignModel;
      final subscription = results[1] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _campaign = campaign;
        _subscription = subscription;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  bool get _analyticsEnabled => _subscription?['analyticsEnabled'] == true;

  Future<void> _showUpgradePrompt({
    required String title,
    required String message,
    List<Map<String, dynamic>> recommendations = const [],
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.elevated,
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (recommendations.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Recommended plans:'),
                const SizedBox(height: 8),
                ...recommendations.take(3).map(
                  (plan) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '- ${plan['name'] ?? plan['planType']} (Rs ${plan['price'] ?? '-'}/month)',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () {
                final shopCategory = (_campaign?.shopCategory ?? '').trim();
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SubscriptionPlansScreen(
                      shopCategory:
                          shopCategory.isEmpty ? 'all' : shopCategory,
                    ),
                  ),
                );
              },
              child: const Text('Upgrade'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchCampaign() async {
    final isActive = _subscription?['isActive'] == true;
    if (!isActive) {
      await _showUpgradePrompt(
        title: 'Subscription Required',
        message: 'Your trial has ended. Upgrade to continue launching campaigns.',
      );
      return;
    }

    String paymentMethod = 'upi';
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.elevated,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
          contentTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
          title: const Text('Launch Campaign'),
          content: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: paymentMethod,
                    items: const [
                      DropdownMenuItem(value: 'upi', child: Text('UPI')),
                      DropdownMenuItem(value: 'card', child: Text('Card')),
                      DropdownMenuItem(value: 'netbanking', child: Text('Net Banking')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() => paymentMethod = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Transaction ID (optional)',
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Pay & Launch'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      controller.dispose();
      return;
    }

    setState(() => _paying = true);
    try {
      final campaign = await CampaignService.instance.payCampaign(
        widget.campaignId,
        paymentMethod: paymentMethod,
        transactionId: controller.text.trim(),
      );
      if (!mounted) return;
      setState(() => _campaign = campaign);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campaign launched successfully.')),
      );
    } on CampaignAccessException catch (error) {
      if (!mounted) return;
      final reached = _campaign?.analytics?.totalReached ?? _campaign?.actualAudienceReached ?? 0;
      final details = error.details;
      final recommendations = details['recommendedPlans'] is List
          ? List<Map<String, dynamic>>.from(details['recommendedPlans'] as List)
          : const <Map<String, dynamic>>[];
      await _showUpgradePrompt(
        title: 'Upgrade to Continue',
        message: '${error.message} Your campaign already reached $reached users. Upgrade to continue growth.',
        recommendations: recommendations,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      controller.dispose();
      if (mounted) {
        setState(() => _paying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final campaign = _campaign;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaign Detail'),
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : campaign == null
                  ? const Center(child: Text('Campaign not found'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          campaign.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(label: Text(campaign.status.replaceAll('_', ' '))),
                            Chip(label: Text('Rs ${campaign.totalCost.toStringAsFixed(0)}')),
                            Chip(label: Text('${campaign.selectedAudienceSize} targets')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(campaign.description ?? 'No description provided.'),
                        const SizedBox(height: 20),
                        _InfoSection(
                          title: 'Audience',
                          children: [
                            _InfoRow(
                              label: 'Targeting mode',
                              value: campaign.targetPincode != null && campaign.targetPincode!.isNotEmpty
                                  ? 'Pincode'
                                  : campaign.targetCity != null && campaign.targetCity!.isNotEmpty
                                      ? 'City-wise'
                                      : campaign.targetState != null && campaign.targetState!.isNotEmpty
                                          ? 'State-wise'
                                          : 'Pan India',
                            ),
                            _InfoRow(label: 'State', value: campaign.targetState ?? '-'),
                            _InfoRow(label: 'City', value: campaign.targetCity ?? '-'),
                            _InfoRow(label: 'Area', value: campaign.targetArea ?? '-'),
                            _InfoRow(label: 'Pincode', value: campaign.targetPincode ?? '-'),
                            _InfoRow(
                              label: 'Age',
                              value: '${campaign.targetAgeMin ?? '-'} - ${campaign.targetAgeMax ?? '-'}',
                            ),
                            _InfoRow(label: 'Gender', value: campaign.targetGender ?? 'all'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _InfoSection(
                          title: 'Analytics',
                          children: [
                            if (!_analyticsEnabled)
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.warning.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Advanced analytics is locked on your current plan.',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text('Upgrade to unlock deeper campaign insights.'),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () => _showUpgradePrompt(
                                        title: 'Unlock Analytics',
                                        message: 'Get full campaign analytics with a paid plan.',
                                      ),
                                      child: const Text('See Upgrade Options'),
                                    ),
                                  ],
                                ),
                              ),
                            _InfoRow(
                              label: 'Scheduled at',
                              value: campaign.scheduledAt?.toLocal().toString() ?? '-',
                            ),
                            _InfoRow(
                              label: 'Reached',
                              value: '${campaign.analytics?.totalReached ?? campaign.actualAudienceReached}',
                            ),
                            _InfoRow(
                              label: 'Opened',
                              value: _analyticsEnabled ? '${campaign.analytics?.opened ?? 0}' : 'Upgrade required',
                            ),
                            _InfoRow(
                              label: 'Clicked',
                              value: _analyticsEnabled ? '${campaign.analytics?.clicked ?? 0}' : 'Upgrade required',
                            ),
                            _InfoRow(
                              label: 'Open rate',
                              value: _analyticsEnabled
                                  ? '${campaign.analytics?.openRate.toStringAsFixed(2) ?? '0.00'}%'
                                  : 'Upgrade required',
                            ),
                          ],
                        ),
                      ],
                    ),
      bottomNavigationBar: campaign != null && campaign.status == 'draft'
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: _paying ? null : _launchCampaign,
                icon: _paying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.rocket_launch_rounded),
                label: const Text('Pay & Launch Campaign'),
              ),
            )
          : null,
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderMid),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}