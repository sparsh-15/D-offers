import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_design_tokens.dart';
import '../../core/utils/theme_helper.dart';
import '../../models/offer_model.dart';
import '../../models/redemption_model.dart';
import '../../services/auth_service.dart';
import '../../services/redemption_service.dart';
import '../../widgets/data_state_wrapper.dart';

class RedemptionHistoryScreen extends StatefulWidget {
  const RedemptionHistoryScreen({
    super.key,
    this.initialOfferId,
  });

  final String? initialOfferId;

  @override
  State<RedemptionHistoryScreen> createState() =>
      _RedemptionHistoryScreenState();
}

class _RedemptionHistoryScreenState extends State<RedemptionHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<RedemptionRecord> _items = [];
  final List<OfferModel> _offers = [];

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _error;

  int _offset = 0;
  final int _limit = 20;
  String? _selectedOfferId;

  @override
  void initState() {
    super.initState();
    _selectedOfferId = widget.initialOfferId;
    _scrollController.addListener(_onScroll);
    _bootstrap();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
      _offset = 0;
      _items.clear();
    });

    try {
      final offers = await AuthService.instance.getShopkeeperOffers();
      final activeOffers = offers.where((o) => o.status == 'active').toList();

      if (!mounted) return;
      setState(() {
        _offers
          ..clear()
          ..addAll(activeOffers);
      });

      await _loadPage(reset: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadPage({required bool reset}) async {
    if (_loadingMore) return;

    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _offset = 0;
      });
    } else {
      setState(() {
        _loadingMore = true;
        _error = null;
      });
    }

    try {
      final page = await RedemptionService.instance.history(
        offset: reset ? 0 : _offset,
        limit: _limit,
        offerId: _selectedOfferId,
      );

      if (!mounted) return;
      setState(() {
        if (reset) {
          _items
            ..clear()
            ..addAll(page.items);
        } else {
          _items.addAll(page.items);
        }
        _offset = page.nextOffset ?? (_items.length);
        _hasMore = page.hasMore;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.maxScrollExtent - position.pixels < 250) {
      _loadPage(reset: false);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'redeemed':
        return AppColors.success;
      case 'reversed':
        return AppColors.warning;
      default:
        return AppColors.textMuted;
    }
  }

  String _methodLabel(String method) {
    if (method.toLowerCase() == 'qr') return 'QR';
    return 'Manual';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Redemption History'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: ThemeHelper.getBackgroundGradient(context),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.spaceMD,
                  AppTokens.spaceSM,
                  AppTokens.spaceMD,
                  AppTokens.spaceSM,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spaceMD,
                    vertical: AppTokens.spaceSM,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(AppTokens.radiusMD),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      isExpanded: true,
                      value: _selectedOfferId != null &&
                              _offers.any((o) => o.id == _selectedOfferId)
                          ? _selectedOfferId
                          : null,
                      dropdownColor: AppColors.elevated,
                      hint: Text(
                        'Filter by offer',
                        style: theme.textTheme.bodyMedium,
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All offers'),
                        ),
                        ..._offers.toSet().fold<List<OfferModel>>(
                          [],
                          (unique, offer) => unique.any((o) => o.id == offer.id)
                              ? unique
                              : [...unique, offer],
                        ).map(
                          (offer) => DropdownMenuItem<String?>(
                            value: offer.id,
                            child: Text(
                              offer.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedOfferId = value);
                        _loadPage(reset: true);
                      },
                    ),
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _loadPage(reset: true),
                  child: DataStateWrapper(
                    loading: _loading,
                    error: _error,
                    isEmpty: _items.isEmpty,
                    onRetry: () => _loadPage(reset: true),
                    emptyTitle: 'No redemptions yet',
                    emptyMessage:
                        'Verified and redeemed coupons will appear here.',
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        AppTokens.spaceMD,
                        AppTokens.spaceSM,
                        AppTokens.spaceMD,
                        AppTokens.space2XL,
                      ),
                      itemCount: _items.length + (_loadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _items.length) {
                          return const Padding(
                            padding: EdgeInsets.all(AppTokens.spaceMD),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final item = _items[index];
                        final redeemedAt = item.redeemedAt == null
                            ? '--'
                            : DateFormat('dd MMM yyyy, hh:mm a')
                                .format(item.redeemedAt!.toLocal());

                        return Container(
                          margin:
                              const EdgeInsets.only(bottom: AppTokens.spaceSM),
                          padding: const EdgeInsets.all(AppTokens.spaceMD),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusMD),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.offer.title,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: AppTokens.spaceSM),
                                  _Tag(
                                    label: item.status.toUpperCase(),
                                    color: _statusColor(item.status),
                                  ),
                                  const SizedBox(width: AppTokens.spaceXS),
                                  _Tag(
                                    label:
                                        _methodLabel(item.verificationMethod),
                                    color: AppColors.info,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTokens.spaceSM),
                              Text(
                                'Coupon: ${item.coupon.code}',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: AppTokens.spaceXS),
                              Text(
                                'Redeemed by: ${item.redeemedBy.name} (${item.redeemedBy.role})',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppTokens.spaceXS),
                              Text(
                                'Time: $redeemedAt',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceSM,
        vertical: AppTokens.spaceXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
      ),
    );
  }
}
