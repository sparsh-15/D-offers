import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_design_tokens.dart';
import '../../core/utils/theme_helper.dart';
import '../../models/customer_claim_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/data_state_wrapper.dart';

class CustomerClaimsTab extends StatefulWidget {
  const CustomerClaimsTab({super.key});

  @override
  State<CustomerClaimsTab> createState() => _CustomerClaimsTabState();
}

class _CustomerClaimsTabState extends State<CustomerClaimsTab> {
  final List<CustomerClaim> _items = [];
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _error;
  String _selectedFilter = 'all'; // all | active | redeemed | expired

  int _offset = 0;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPage(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
      final page = await AuthService.instance.getMyClaims(
        offset: reset ? 0 : _offset,
        limit: _limit,
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
        _offset = page.nextOffset ?? _items.length;
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
    if (!_hasMore ||
        _loading ||
        _loadingMore ||
        !_scrollController.hasClients) {
      return;
    }

    final pos = _scrollController.position;
    if (pos.maxScrollExtent - pos.pixels < 250) {
      _loadPage(reset: false);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'redeemed':
        return AppColors.success;
      case 'expired':
        return AppColors.warning;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '--';
    return DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal());
  }

  List<CustomerClaim> _getFilteredItems() {
    if (_selectedFilter == 'all') return _items;
    return _items.where((claim) {
      switch (_selectedFilter) {
        case 'active':
          return claim.isActive;
        case 'redeemed':
          return claim.isRedeemed;
        case 'expired':
          return claim.isExpired;
        default:
          return true;
      }
    }).toList();
  }

  void _showQr(CustomerClaim claim) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Claim QR'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: AppColors.white,
                padding: const EdgeInsets.all(AppTokens.spaceSM),
                child: QrImageView(
                  data: claim.qrPayload,
                  version: QrVersions.auto,
                  size: 220,
                ),
              ),
              const SizedBox(height: AppTokens.spaceMD),
              Text(
                'Coupon: ${claim.coupon.code}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredItems = _getFilteredItems();

    return Container(
      decoration: BoxDecoration(
        gradient: ThemeHelper.getBackgroundGradient(context),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadPage(reset: true),
          child: DataStateWrapper(
            loading: _loading,
            error: _error,
            isEmpty: filteredItems.isEmpty,
            onRetry: () => _loadPage(reset: true),
            emptyTitle: 'No claimed deals',
            emptyMessage: _selectedFilter == 'all'
                ? 'Claim deals from offer details to see them here.'
                : 'No deals found in this category.',
            child: Column(
              children: [
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.spaceMD,
                    AppTokens.spaceSM,
                    AppTokens.spaceMD,
                    AppTokens.spaceSM,
                  ),
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All', Icons.list),
                      const SizedBox(width: AppTokens.spaceXS),
                      _buildFilterChip('active', 'Active', Icons.schedule),
                      const SizedBox(width: AppTokens.spaceXS),
                      _buildFilterChip(
                          'redeemed', 'Redeemed', Icons.check_circle),
                      const SizedBox(width: AppTokens.spaceXS),
                      _buildFilterChip('expired', 'Expired', Icons.access_time),
                    ],
                  ),
                ),
                // Claims list
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.spaceMD,
                      AppTokens.spaceSM,
                      AppTokens.spaceMD,
                      AppTokens.space2XL,
                    ),
                    itemCount: filteredItems.length + (_loadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= filteredItems.length) {
                        return const Padding(
                          padding: EdgeInsets.all(AppTokens.spaceMD),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final claim = filteredItems[index];
                      final statusColor = _statusColor(claim.status);

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
                                    claim.offer.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppTokens.spaceSM),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTokens.spaceSM,
                                    vertical: AppTokens.spaceXS,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                        AppTokens.radiusFull),
                                    border: Border.all(
                                        color: statusColor.withValues(
                                            alpha: 0.45)),
                                  ),
                                  child: Text(
                                    claim.status.toUpperCase(),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: statusColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTokens.spaceSM),
                            Text('Coupon: ${claim.coupon.code}'),
                            const SizedBox(height: AppTokens.spaceXS),
                            Text(
                              'Claimed: ${_formatDate(claim.claimedAt)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (claim.expiresAt != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: AppTokens.spaceXS),
                                child: Row(
                                  children: [
                                    Icon(
                                      claim.isActive &&
                                              claim.daysUntilExpiry != null &&
                                              claim.daysUntilExpiry! <= 3
                                          ? Icons.warning_rounded
                                          : Icons.access_time,
                                      size: 14,
                                      color: claim.isActive &&
                                              claim.daysUntilExpiry != null &&
                                              claim.daysUntilExpiry! <= 3
                                          ? AppColors.warning
                                          : AppColors.textMuted,
                                    ),
                                    const SizedBox(width: AppTokens.spaceXS),
                                    Expanded(
                                      child: Text(
                                        claim.expiryDisplayText,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: claim.isActive &&
                                                  claim.daysUntilExpiry !=
                                                      null &&
                                                  claim.daysUntilExpiry! <= 3
                                              ? AppColors.warning
                                              : AppColors.textMuted,
                                          fontWeight: claim.isActive &&
                                                  claim.daysUntilExpiry !=
                                                      null &&
                                                  claim.daysUntilExpiry! <= 3
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: AppTokens.spaceSM),
                            if (claim.isActive)
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _showQr(claim),
                                  icon: const Icon(Icons.qr_code_2_rounded),
                                  label: const Text('Show QR for Shopkeeper'),
                                ),
                              ),
                            if (!claim.isActive)
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _showQr(claim),
                                  icon: const Icon(Icons.qr_code_2_rounded),
                                  label: const Text('View QR'),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      avatar: Icon(icon, size: 16),
      label: Text(label),
      backgroundColor: AppColors.cardBackground,
      selectedColor: AppColors.info.withValues(alpha: 0.2),
      side: BorderSide(
        color: isSelected ? AppColors.info : AppColors.borderSubtle,
      ),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.info : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }
}
