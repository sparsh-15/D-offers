import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/theme_helper.dart';
import '../../models/campaign_model.dart';
import '../../services/campaign_service.dart';
import '../../widgets/data_state_wrapper.dart';
import 'campaign_detail_screen.dart';

class CampaignsTab extends StatelessWidget {
  final Function(VoidCallback)? onRefreshCallbackSet;

  const CampaignsTab({super.key, this.onRefreshCallbackSet});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          BoxDecoration(gradient: ThemeHelper.getBackgroundGradient(context)),
      child: SafeArea(
        child: _CampaignsBody(
          onRefreshCallbackSet: onRefreshCallbackSet,
        ),
      ),
    );
  }
}

class _CampaignsBody extends StatefulWidget {
  final Function(VoidCallback)? onRefreshCallbackSet;

  const _CampaignsBody({this.onRefreshCallbackSet});

  @override
  State<_CampaignsBody> createState() => _CampaignsBodyState();
}

class _CampaignsBodyState extends State<_CampaignsBody> {
  final List<String> _filters = const ['all', 'draft', 'completed', 'queued'];
  String _selectedFilter = 'all';
  bool _loading = true;
  String? _error;
  List<CampaignModel> _campaigns = const [];

  @override
  void initState() {
    super.initState();
    widget.onRefreshCallbackSet?.call(_refresh);
    _loadCampaigns();
  }

  Future<void> _refresh() => _loadCampaigns();

  Future<void> _loadCampaigns() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final campaigns = await CampaignService.instance.getCampaigns(
        status: _selectedFilter,
      );
      if (!mounted) return;
      setState(() {
        _campaigns = campaigns;
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          backgroundColor: AppColors.transparent,
          title: const Text('Campaigns'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _refresh,
            ),
          ],
        ),
        SizedBox(
          height: 48,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final filter = _filters[index];
              final isSelected = filter == _selectedFilter;
              return ChoiceChip(
                label: Text(
                  filter == 'all'
                      ? 'All'
                      : '${filter[0].toUpperCase()}${filter.substring(1)}',
                ),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _selectedFilter = filter);
                  _loadCampaigns();
                },
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: _filters.length,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: DataStateWrapper(
            loading: _loading,
            error: _error,
            isEmpty: _campaigns.isEmpty,
            onRetry: _refresh,
            emptyTitle: 'No campaigns yet',
            emptyMessage:
                'Create your first campaign to reach customers in your target city.',
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: _campaigns.length,
                itemBuilder: (context, index) {
                  final campaign = _campaigns[index];
                  return FadeInUp(
                    delay: Duration(milliseconds: 60 * index),
                    child: _CampaignCard(
                      campaign: campaign,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CampaignDetailScreen(
                              campaignId: campaign.id,
                              initialCampaign: campaign,
                            ),
                          ),
                        );
                        _refresh();
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final CampaignModel campaign;
  final VoidCallback onTap;

  const _CampaignCard({
    required this.campaign,
    required this.onTap,
  });

  Color _statusColor() {
    switch (campaign.status) {
      case 'completed':
        return AppColors.success;
      case 'queued':
      case 'pending_payment':
        return AppColors.warning;
      case 'failed':
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      campaign.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor().withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      campaign.status.replaceAll('_', ' '),
                      style: TextStyle(
                        color: _statusColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                campaign.description ?? 'No description added yet.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _MetricChip(
                    icon: Icons.groups_rounded,
                    label: '${campaign.selectedAudienceSize} targets',
                  ),
                  _MetricChip(
                    icon: Icons.location_city_rounded,
                    label: campaign.targetCity ?? campaign.targetPincode ?? 'Custom',
                  ),
                  _MetricChip(
                    icon: Icons.payments_rounded,
                    label: 'Rs ${campaign.totalCost.toStringAsFixed(0)}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderMid),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}