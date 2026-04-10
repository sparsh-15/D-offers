import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  void _onWalletBalanceChanged() {
    final balance = RewardService.instance.latestWalletBalance;
    if (!mounted || balance == null) return;

    setState(() {
      _wallet = {
        ...?_wallet,
        'balance': balance,
      };
    });
  }

  @override
  void initState() {
    super.initState();
    RewardService.instance.walletBalanceNotifier
        .addListener(_onWalletBalanceChanged);
    _loadInitial();
  }

  @override
  void dispose() {
    RewardService.instance.walletBalanceNotifier
        .removeListener(_onWalletBalanceChanged);
    super.dispose();
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
        _wallet = {
          ...((responses[0] as Map<String, dynamic>?) ?? const {}),
        };
        _expiry = responses[1];
        _entries = entries;
        _skip = entries.length;
        _total = (ledgerResponse['total'] as num?)?.toInt() ?? entries.length;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final rawError = e.toString();
      final lowerError = rawError.toLowerCase();

      final friendlyError = lowerError.contains('insufficient permissions')
          ? 'Wallet access denied for current role. $rawError'
          : rawError;

      setState(() {
        _error = friendlyError;
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
    return Scaffold(
      backgroundColor: _WalletPalette.canvas,
      appBar: AppBar(
        backgroundColor: _WalletPalette.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          color: _WalletPalette.textSecondary,
        ),
        title: Text(
          widget.title,
          style: GoogleFonts.dmSans(
            color: _WalletPalette.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadInitial,
        color: _WalletPalette.accent,
        backgroundColor: Colors.white,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: _WalletPalette.accent),
              )
            : _error != null
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            color: _WalletPalette.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Transaction history',
                                style: GoogleFonts.dmSans(
                                  color: _WalletPalette.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${_entries.length} transactions',
                                style: GoogleFonts.dmSans(
                                  color: _WalletPalette.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_entries.isEmpty)
                            Container(
                              decoration: BoxDecoration(
                                color: _WalletPalette.surface,
                                borderRadius: BorderRadius.circular(18),
                                border:
                                    Border.all(color: _WalletPalette.border),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'No transactions yet.',
                                style: GoogleFonts.dmSans(
                                  color: _WalletPalette.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          else
                            ..._entries
                                .map((entry) => _buildLedgerTile(context, entry)),
                          if (_skip < _total)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: OutlinedButton(
                                onPressed: _loadingMore ? null : _loadMore,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _WalletPalette.textPrimary,
                                  side: const BorderSide(
                                    color: _WalletPalette.border,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _loadingMore
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: _WalletPalette.accent,
                                        ),
                                      )
                                    : Text(
                                        'Load More',
                                        style: GoogleFonts.dmSans(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, {required bool compact}) {
    final balance = (_wallet?['balance'] as num?)?.toInt() ?? 0;
    final totalExpiring = (_expiry?['totalExpiring'] as num?)?.toInt() ?? 0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9A5A18), Color(0xFFE88428)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8A4F14).withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 13 : 15),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -18,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              right: 38,
              bottom: -34,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFF1CF).withValues(alpha: 0.12),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AVAILABLE COINS',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFFFFF8ED),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$balance',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 42,
                        height: 0.95,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'coins',
                        style: GoogleFonts.dmSans(
                          color: const Color(0xFFFFF8ED),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_circle_fill_rounded,
                        size: 14,
                        color: Color(0xFFFFF1CF),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Expiring soon: $totalExpiring coins',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryCard(BuildContext context, {required bool compact}) {
    final upcoming =
        (_expiry?['upcomingExpiries'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();

    return Container(
      decoration: BoxDecoration(
        color: _WalletPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _WalletPalette.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 13 : 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Expiry summary',
                  style: GoogleFonts.dmSans(
                    color: _WalletPalette.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _WalletPalette.accentSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${upcoming.length} batches',
                    style: GoogleFonts.dmSans(
                      color: _WalletPalette.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (upcoming.isEmpty)
              Text(
                'No upcoming expiries',
                style: GoogleFonts.dmSans(
                  color: _WalletPalette.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              ...upcoming.take(3).map((item) {
                final date =
                    DateTime.tryParse(item['expiresAt']?.toString() ?? '');
                final amount = (item['amount'] as num?)?.toInt() ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _WalletPalette.tile,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 10,
                          color: _WalletPalette.accent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            date != null ? _formatDate(date) : '-',
                            style: GoogleFonts.dmSans(
                              color: _WalletPalette.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '$amount coins',
                          style: GoogleFonts.dmSans(
                            color: _WalletPalette.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerTile(BuildContext context, Map<String, dynamic> entry) {
    final direction = entry['direction']?.toString() ?? 'credit';
    final amount = (entry['amount'] as num?)?.toInt() ?? 0;
    final actionType = entry['actionType']?.toString() ?? '-';
    final sourceRef = entry['sourceRef']?.toString().trim();
    final sourceLabel = entry['sourceLabel']?.toString().trim();
    final createdAt = DateTime.tryParse(entry['createdAt']?.toString() ?? '');
    final isCredit = direction == 'credit';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _WalletPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _WalletPalette.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _WalletPalette.successSoft,
            child: Icon(
              Icons.card_giftcard_rounded,
              color: _WalletPalette.success,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _prettyAction(actionType),
                  style: GoogleFonts.dmSans(
                    color: _WalletPalette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sourceLabel != null && sourceLabel.isNotEmpty
                      ? sourceLabel
                      : (sourceRef != null && sourceRef.isNotEmpty
                          ? sourceRef
                          : 'Coin transaction'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    color: _WalletPalette.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  createdAt != null ? _formatDateTime(createdAt) : '-',
                  style: GoogleFonts.dmSans(
                    color: _WalletPalette.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${isCredit ? '+' : '-'}$amount',
            style: GoogleFonts.dmSans(
              color: isCredit ? _WalletPalette.success : _WalletPalette.error,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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

class _WalletPalette {
  static const canvas = Color(0xFFF6F8FB);
  static const surface = Color(0xFFFFFFFF);
  static const tile = Color(0xFFF4F7FB);
  static const border = Color(0xFFDDE4ED);
  static const textPrimary = Color(0xFF132033);
  static const textSecondary = Color(0xFF5E6D82);
  static const accent = Color(0xFFE88428);
  static const accentSoft = Color(0xFFFCE6D4);
  static const success = Color(0xFF1F9D65);
  static const successSoft = Color(0xFFE4F6EC);
  static const warn = Color(0xFFB26B18);
  static const error = Color(0xFFDC2626);
}
