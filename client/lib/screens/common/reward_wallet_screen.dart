import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/theme_helper.dart';
import '../../services/reward_service.dart';

class RewardWalletScreen extends StatefulWidget {
  const RewardWalletScreen({
    super.key,
    this.title = 'My Wallet',
  });

  final String title;

  @override
  State<RewardWalletScreen> createState() => _RewardWalletScreenState();
}

class _RewardWalletScreenState extends State<RewardWalletScreen> {
  Map<String, dynamic>? _wallet;
  Map<String, dynamic>? _expiry;
  List<Map<String, dynamic>> _entries = const [];
  bool _loading = true;
  bool _loadingMore = false;
  int _skip = 0;
  static const int _pageSize = 20;
  int _total = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
      _entries = [];
      _skip = 0;
      _total = 0;
    });

    try {
      final responses = await Future.wait([
        RewardService.instance.getMyWallet(),
        RewardService.instance.getMyExpirySummary(),
        RewardService.instance.getMyLedger(limit: _pageSize, skip: 0),
      ]);

      if (!mounted) return;

      final ledgerResponse = responses[2];
      final entries = (ledgerResponse['entries'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();

      setState(() {
        _wallet = responses[0];
        _expiry = responses[1];
        _entries = entries;
        _skip = entries.length;
        _total = (ledgerResponse['total'] as num?)?.toInt() ?? entries.length;
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

  Future<void> _loadMore() async {
    if (_loadingMore || _skip >= _total) return;

    setState(() => _loadingMore = true);
    try {
      final ledger = await RewardService.instance.getMyLedger(
        limit: _pageSize,
        skip: _skip,
      );
      final entries = (ledger['entries'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();

      if (!mounted) return;
      setState(() {
        _entries = [..._entries, ...entries];
        _skip += entries.length;
        _total = (ledger['total'] as num?)?.toInt() ?? _total;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: ThemeHelper.buildBackButton(context),
        title: Text(widget.title),
      ),
      body: Container(
        decoration:
            BoxDecoration(gradient: ThemeHelper.getBackgroundGradient(context)),
        child: RefreshIndicator(
          onRefresh: _loadInitial,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 430;
                        return ListView(
                          padding: EdgeInsets.all(compact ? 12 : 16),
                          children: [
                            _buildBalanceCard(context, compact: compact),
                            const SizedBox(height: 12),
                            _buildExpiryCard(context, compact: compact),
                            const SizedBox(height: 16),
                            Text(
                              'Transaction History',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            if (_entries.isEmpty)
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'No transactions yet.',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              )
                            else
                              ..._entries.map(
                                  (entry) => _buildLedgerTile(context, entry)),
                            if (_skip < _total)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: OutlinedButton(
                                  onPressed: _loadingMore ? null : _loadMore,
                                  child: _loadingMore
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Text('Load More'),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, {required bool compact}) {
    final theme = Theme.of(context);
    final balance = (_wallet?['balance'] as num?)?.toInt() ?? 0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.monetization_on_rounded,
                  color: AppColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Available Coins', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 2),
                  Text(
                    '$balance',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryCard(BuildContext context, {required bool compact}) {
    final theme = Theme.of(context);
    final totalExpiring = (_expiry?['totalExpiring'] as num?)?.toInt() ?? 0;
    final upcoming =
        (_expiry?['upcomingExpiries'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Expiry Summary', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(
              '$totalExpiring coins expiring soon',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.warning),
            ),
            const SizedBox(height: 8),
            if (upcoming.isEmpty)
              Text('No upcoming expiries', style: theme.textTheme.bodySmall)
            else
              ...upcoming.take(3).map((item) {
                final date =
                    DateTime.tryParse(item['expiresAt']?.toString() ?? '');
                final amount = (item['amount'] as num?)?.toInt() ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${date != null ? _formatDate(date) : '-'}  •  $amount coins',
                    style: theme.textTheme.bodySmall,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerTile(BuildContext context, Map<String, dynamic> entry) {
    final theme = Theme.of(context);
    final direction = entry['direction']?.toString() ?? 'credit';
    final amount = (entry['amount'] as num?)?.toInt() ?? 0;
    final actionType = entry['actionType']?.toString() ?? '-';
    final createdAt = DateTime.tryParse(entry['createdAt']?.toString() ?? '');
    final isCredit = direction == 'credit';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (isCredit ? AppColors.success : AppColors.warning)
              .withValues(alpha: 0.16),
          child: Icon(
            isCredit ? Icons.add_rounded : Icons.remove_rounded,
            color: isCredit ? AppColors.success : AppColors.warning,
          ),
        ),
        title:
            Text(_prettyAction(actionType), style: theme.textTheme.bodyMedium),
        subtitle: Text(
          createdAt != null ? _formatDateTime(createdAt) : '-',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Text(
          '${isCredit ? '+' : '-'}$amount',
          style: theme.textTheme.titleMedium?.copyWith(
            color: isCredit ? AppColors.success : AppColors.warning,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _prettyAction(String raw) {
    return raw
        .split('_')
        .map((part) =>
            part.isEmpty ? '' : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${_formatDate(date)} $hour:$minute';
  }
}
