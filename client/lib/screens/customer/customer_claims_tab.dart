import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/constants/app_design_tokens.dart';
import '../../models/customer_claim_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/data_state_wrapper.dart';

// ── Light palette ─────────────────────────────────────────────────────────────
class _CL {
  static const canvas        = Color(0xFFF3F5F8);
  static const surface       = Color(0xFFFFFFFF);
  static const elevated      = Color(0xFFF4F7FB);
  static const border        = Color(0xFFDCE3EC);
  static const accent        = Color(0xFFE88428);
  static const accentSoft    = Color(0xFFFBE7D6);
  static const textPrimary   = Color(0xFF1E2433);
  static const textSecondary = Color(0xFF334155);
  static const textMuted     = Color(0xFF667085);
  static const success       = Color(0xFF1F9D65);
  static const successBg     = Color(0xFFE4F6EC);
  static const warning       = Color(0xFFD97706);
  static const warningBg     = Color(0xFFFEF3C7);
  static const error         = Color(0xFFE24D69);
  static const errorBg       = Color(0xFFFDEBEC);
  static const info          = Color(0xFF2563EB);
  static const infoBg        = Color(0xFFEFF6FF);
  static const white         = Color(0xFFFFFFFF);
}

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
  String _selectedFilter = 'all';

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
      setState(() { _loading = true; _error = null; _offset = 0; });
    } else {
      setState(() { _loadingMore = true; _error = null; });
    }
    try {
      final page = await AuthService.instance.getMyClaims(
        offset: reset ? 0 : _offset,
        limit: _limit,
      );
      if (!mounted) return;
      setState(() {
        if (reset) { _items..clear()..addAll(page.items); }
        else { _items.addAll(page.items); }
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
    if (!_hasMore || _loading || _loadingMore || !_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.maxScrollExtent - pos.pixels < 250) _loadPage(reset: false);
  }

  // Returns (fg, bg) colors for status
  (Color, Color) _statusColors(String status) {
    switch (status.toLowerCase()) {
      case 'redeemed':  return (_CL.success, _CL.successBg);
      case 'expired':   return (_CL.warning, _CL.warningBg);
      case 'cancelled': return (_CL.error,   _CL.errorBg);
      default:          return (_CL.info,    _CL.infoBg);
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
        case 'active':   return claim.isActive;
        case 'redeemed': return claim.isRedeemed;
        case 'expired':  return claim.isExpired;
        default:         return true;
      }
    }).toList();
  }

  void _showQr(CustomerClaim claim) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _CL.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Claim QR',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _CL.textPrimary,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: _CL.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _CL.border),
                ),
                padding: const EdgeInsets.all(12),
                child: QrImageView(
                  data: claim.qrPayload,
                  version: QrVersions.auto,
                  size: 220,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _CL.elevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _CL.border),
                ),
                child: Text(
                  'Coupon: ${claim.coupon.code}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _CL.accent,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: _CL.textSecondary),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _getFilteredItems();

    return ColoredBox(
      color: _CL.canvas,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadPage(reset: true),
          color: _CL.accent,
          backgroundColor: _CL.surface,
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
                // ── Filter chips ───────────────────────────────────────────
                Container(
                  color: _CL.canvas,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Row(
                      children: [
                        _filterChip('all',      'All',      Icons.list_rounded),
                        const SizedBox(width: 8),
                        _filterChip('active',   'Active',   Icons.schedule_rounded),
                        const SizedBox(width: 8),
                        _filterChip('redeemed', 'Redeemed', Icons.check_circle_outline_rounded),
                        const SizedBox(width: 8),
                        _filterChip('expired',  'Expired',  Icons.access_time_rounded),
                      ],
                    ),
                  ),
                ),
                // ── Claims list ────────────────────────────────────────────
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    itemCount: filteredItems.length + (_loadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= filteredItems.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _CL.accent),
                          ),
                        );
                      }

                      final claim = filteredItems[index];
                      final (statusFg, statusBg) = _statusColors(claim.status);
                      final isUrgent = claim.isActive &&
                          claim.daysUntilExpiry != null &&
                          claim.daysUntilExpiry! <= 3;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: _CL.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _CL.border),
                          boxShadow: [
                            BoxShadow(
                              color: _CL.textPrimary.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Header ───────────────────────────────────
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      claim.offer.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: _CL.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: statusFg.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      claim.status.toUpperCase(),
                                      style: GoogleFonts.dmSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: statusFg,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // ── Coupon code ───────────────────────────────
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: _CL.accentSoft,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: _CL.accent.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.confirmation_number_outlined,
                                        size: 16, color: _CL.accent),
                                    const SizedBox(width: 8),
                                    Text(
                                      claim.coupon.code,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: _CL.accent,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // ── Meta info ─────────────────────────────────
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded,
                                          size: 13, color: _CL.textMuted),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Claimed: ${_formatDate(claim.claimedAt)}',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          color: _CL.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (claim.expiresAt != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          isUrgent
                                              ? Icons.warning_rounded
                                              : Icons.event_outlined,
                                          size: 13,
                                          color: isUrgent
                                              ? _CL.warning
                                              : _CL.textMuted,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          claim.expiryDisplayText,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 12,
                                            color: isUrgent
                                                ? _CL.warning
                                                : _CL.textMuted,
                                            fontWeight: isUrgent
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // ── QR button ─────────────────────────────────
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                              child: SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: claim.isActive
                                    ? ElevatedButton.icon(
                                        onPressed: () => _showQr(claim),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _CL.accent,
                                          foregroundColor: _CL.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          textStyle: GoogleFonts.dmSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700),
                                        ),
                                        icon: const Icon(
                                            Icons.qr_code_2_rounded,
                                            size: 18),
                                        label: const Text(
                                            'Show QR for Shopkeeper'),
                                      )
                                    : OutlinedButton.icon(
                                        onPressed: () => _showQr(claim),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: _CL.textSecondary,
                                          side: const BorderSide(
                                              color: _CL.border),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          textStyle: GoogleFonts.dmSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        icon: const Icon(
                                            Icons.qr_code_2_rounded,
                                            size: 18),
                                        label: const Text('View QR'),
                                      ),
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

  Widget _filterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _CL.accentSoft : _CL.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          border: Border.all(
            color: isSelected ? _CL.accent : _CL.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: isSelected ? _CL.accent : _CL.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _CL.accent : _CL.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
