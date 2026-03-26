import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/theme_helper.dart';
import '../../services/reward_service.dart';
import '../common/reward_wallet_screen.dart';

class ShopRewardsScreen extends StatefulWidget {
  const ShopRewardsScreen({super.key});

  @override
  State<ShopRewardsScreen> createState() => _ShopRewardsScreenState();
}

class _ShopRewardsScreenState extends State<ShopRewardsScreen> {
  Map<String, dynamic>? _milestones;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final milestones = await RewardService.instance.getShopkeeperMilestones();
      if (!mounted) return;
      setState(() {
        _milestones = milestones;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _redeem(String milestoneId) async {
    try {
      await RewardService.instance.redeemMilestone(milestoneId);
      if (!mounted) return;
      DialogHelper.showSuccessSnackBar(context, 'Redemption request submitted');
      _load();
    } catch (e) {
      if (!mounted) return;
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: ThemeHelper.buildBackButton(context),
        title: const Text('Rewards & Milestones'),
        actions: [
          IconButton(
            tooltip: 'Wallet',
            icon: const Icon(Icons.account_balance_wallet_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const RewardWalletScreen(title: 'Shop Wallet'),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration:
            BoxDecoration(gradient: ThemeHelper.getBackgroundGradient(context)),
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(_error!, textAlign: TextAlign.center),
                        ),
                      ],
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 430;
                        final lifetime =
                            (_milestones?['lifetimeCredited'] as num?)
                                    ?.toInt() ??
                                0;
                        final milestoneList =
                            (_milestones?['milestones'] as List<dynamic>? ??
                                    const [])
                                .cast<Map<String, dynamic>>();

                        return ListView(
                          padding: EdgeInsets.all(compact ? 12 : 16),
                          children: [
                            Card(
                              child: Padding(
                                padding: EdgeInsets.all(compact ? 12 : 16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent
                                            .withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                          Icons.emoji_events_rounded,
                                          color: AppColors.accent),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Lifetime Credited Coins',
                                              style: theme.textTheme.bodySmall),
                                          Text(
                                            '$lifetime',
                                            style: theme.textTheme.headlineSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text('Milestones',
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 8),
                            if (milestoneList.isEmpty)
                              const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('No milestones configured yet.'),
                                ),
                              )
                            else
                              ...milestoneList.map((milestone) {
                                final id = milestone['id']?.toString() ?? '';
                                final threshold =
                                    (milestone['thresholdCoins'] as num?)
                                            ?.toInt() ??
                                        0;
                                final rewardAmountPaise =
                                    (milestone['rewardAmountPaise'] as num?)
                                            ?.toInt() ??
                                        0;
                                final reached = milestone['reached'] == true;
                                final redemptionStatus =
                                    milestone['redemptionStatus']?.toString();
                                final canRedeem =
                                    reached && redemptionStatus == null;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: Padding(
                                    padding: EdgeInsets.all(compact ? 12 : 14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '$threshold Coins',
                                                style:
                                                    theme.textTheme.titleSmall,
                                              ),
                                            ),
                                            _buildStatusChip(
                                              context,
                                              reached: reached,
                                              redemptionStatus:
                                                  redemptionStatus,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Reward: ${_formatRupees(rewardAmountPaise)}',
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 10),
                                        if (canRedeem)
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: OutlinedButton(
                                              onPressed: () => _redeem(id),
                                              child: const Text('Redeem'),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                          ],
                        );
                      },
                    ),
        ),
      ),
    );
  }

    Widget _buildStatusChip(
      BuildContext context,
      {required bool reached, required String? redemptionStatus}) {
    final String text;
    final Color color;

    if (!reached) {
      text = 'Locked';
      color = AppColors.textMuted;
    } else if (redemptionStatus == null) {
      text = 'Reached';
      color = AppColors.success;
    } else {
      text = redemptionStatus.toUpperCase();
      color =
          redemptionStatus == 'rejected' ? AppColors.error : AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _formatRupees(int paise) {
    final rupees = paise / 100.0;
    return '₹${rupees.toStringAsFixed(rupees.truncateToDouble() == rupees ? 0 : 2)}';
  }
}
