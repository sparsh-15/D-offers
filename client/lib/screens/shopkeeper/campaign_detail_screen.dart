import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/campaign_model.dart';
import '../../services/campaign_service.dart';

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
      final campaign = await CampaignService.instance.getCampaign(widget.campaignId);
      if (!mounted) return;
      setState(() {
        _campaign = campaign;
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

  Future<void> _launchCampaign() async {
    String paymentMethod = 'upi';
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
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
                            _InfoRow(
                              label: 'Reached',
                              value: '${campaign.analytics?.totalReached ?? campaign.actualAudienceReached}',
                            ),
                            _InfoRow(
                              label: 'Opened',
                              value: '${campaign.analytics?.opened ?? 0}',
                            ),
                            _InfoRow(
                              label: 'Clicked',
                              value: '${campaign.analytics?.clicked ?? 0}',
                            ),
                            _InfoRow(
                              label: 'Open rate',
                              value: '${campaign.analytics?.openRate.toStringAsFixed(2) ?? '0.00'}%',
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