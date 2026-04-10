import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/campaign_model.dart';
import '../../screens/common/offer_detail_screen.dart';
import '../../services/auth_service.dart';
import '../../services/campaign_service.dart';
import '../../widgets/data_state_wrapper.dart';

// ── Light palette ─────────────────────────────────────────────────────────────
class _IP {
  static const canvas        = Color(0xFFF3F5F8);
  static const surface       = Color(0xFFFFFFFF);
  static const elevated      = Color(0xFFF4F7FB);
  static const border        = Color(0xFFDCE3EC);
  static const accent        = Color(0xFFE88428);
  static const accentSoft    = Color(0xFFFBE7D6);
  static const textPrimary   = Color(0xFF1E2433);
  static const textSecondary = Color(0xFF334155);
  static const textMuted     = Color(0xFF667085);
  static const unreadDot     = Color(0xFFE88428);
  static const white         = Color(0xFFFFFFFF);
}

class CustomerInboxScreen extends StatefulWidget {
  const CustomerInboxScreen({super.key});

  @override
  State<CustomerInboxScreen> createState() => _CustomerInboxScreenState();
}

class _CustomerInboxScreenState extends State<CustomerInboxScreen> {
  bool _loading = true;
  String? _error;
  List<InboxMessageModel> _messages = const [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() { _loading = true; _error = null; });
    try {
      final messages = await CampaignService.instance.getInboxMessages();
      if (!mounted) return;
      setState(() { _messages = messages; _loading = false; });
    } catch (error) {
      if (!mounted) return;
      setState(() { _error = error.toString(); _loading = false; });
    }
  }

  void _markRead(InboxMessageModel message) {
    setState(() {
      _messages = _messages.map((item) {
        if (item.id != message.id) return item;
        return InboxMessageModel(
          id: item.id,
          campaignId: item.campaignId,
          shopkeeperId: item.shopkeeperId,
          offerId: item.offerId,
          title: item.title,
          body: item.body,
          bannerUrl: item.bannerUrl,
          isRead: true,
          readAt: DateTime.now(),
          createdAt: item.createdAt,
          shopkeeperName: item.shopkeeperName,
          campaignStatus: item.campaignStatus,
        );
      }).toList();
    });
  }

  Future<void> _openMessage(InboxMessageModel message) async {
    if (!message.isRead) {
      try {
        await CampaignService.instance.markInboxMessageRead(message.id);
        if (mounted) _markRead(message);
      } catch (_) {}
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _InboxDetailSheet(message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _IP.canvas,
      appBar: AppBar(
        backgroundColor: _IP.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: _IP.canvas,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _IP.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Campaigns',
          style: GoogleFonts.dmSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _IP.textPrimary,
          ),
        ),
      ),
      body: DataStateWrapper(
        loading: _loading,
        error: _error,
        isEmpty: _messages.isEmpty,
        onRetry: _loadMessages,
        emptyTitle: 'No campaign messages yet',
        emptyMessage:
            'When shops launch campaigns for your area, they will show up here.',
        child: RefreshIndicator(
          onRefresh: _loadMessages,
          color: _IP.accent,
          backgroundColor: _IP.surface,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final initial = message.shopkeeperName.isNotEmpty
                  ? message.shopkeeperName[0].toUpperCase()
                  : 'S';

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: _IP.surface,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: () => _openMessage(message),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: message.isRead
                              ? _IP.border
                              : _IP.accent.withValues(alpha: 0.35),
                          width: message.isRead ? 1 : 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Avatar ─────────────────────────────────────
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: message.isRead
                                    ? _IP.elevated
                                    : _IP.accentSoft,
                                backgroundImage: (message.bannerUrl != null &&
                                        message.bannerUrl!.isNotEmpty)
                                    ? CachedNetworkImageProvider(
                                        message.bannerUrl!)
                                    : null,
                                child: (message.bannerUrl == null ||
                                        message.bannerUrl!.isEmpty)
                                    ? Text(
                                        initial,
                                        style: GoogleFonts.dmSans(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                          color: message.isRead
                                              ? _IP.textMuted
                                              : _IP.accent,
                                        ),
                                      )
                                    : null,
                              ),
                              if (!message.isRead)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 11,
                                    height: 11,
                                    decoration: BoxDecoration(
                                      color: _IP.unreadDot,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: _IP.surface, width: 2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // ── Content ────────────────────────────────────
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        message.title,
                                        style: GoogleFonts.dmSans(
                                          fontWeight: message.isRead
                                              ? FontWeight.w500
                                              : FontWeight.w700,
                                          fontSize: 14,
                                          color: message.isRead
                                              ? _IP.textSecondary
                                              : _IP.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      _timeAgo(message.createdAt),
                                      style: GoogleFonts.dmSans(
                                        fontSize: 11,
                                        color: _IP.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  message.shopkeeperName,
                                  style: GoogleFonts.dmSans(
                                    color: _IP.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  message.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: _IP.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                                if ((message.offerId ?? '').isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.local_offer_rounded,
                                          size: 12,
                                          color: _IP.accent,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Offer attached — tap to view',
                                          style: GoogleFonts.dmSans(
                                            color: _IP.accent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: _IP.textMuted,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Detail bottom sheet ───────────────────────────────────────────────────────

class _InboxDetailSheet extends StatefulWidget {
  const _InboxDetailSheet({required this.message});
  final InboxMessageModel message;

  @override
  State<_InboxDetailSheet> createState() => _InboxDetailSheetState();
}

class _InboxDetailSheetState extends State<_InboxDetailSheet> {
  bool _loadingOffer = false;
  String? _offerError;

  Future<void> _viewOffer() async {
    setState(() { _loadingOffer = true; _offerError = null; });
    try {
      final offer =
          await AuthService.instance.getCustomerOffer(widget.message.offerId!);
      if (!mounted) return;
      Navigator.of(context).pop();
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => OfferDetailScreen(offer: offer)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _offerError = 'Could not load offer. Please try again.';
        _loadingOffer = false;
      });
    }
  }

  void _share() {
    final msg = widget.message;
    final text = StringBuffer()
      ..writeln('🎁 ${msg.title}')
      ..writeln('From: ${msg.shopkeeperName}')
      ..writeln()
      ..write(msg.body);
    Share.share(text.toString());
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final hasOffer = (msg.offerId ?? '').isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: _IP.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Handle + actions ────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _IP.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.share_rounded,
                          color: _IP.textSecondary),
                      tooltip: 'Share',
                      onPressed: _share,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: _IP.textSecondary),
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: _IP.border),
              // ── Scrollable content ──────────────────────────────────────
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  children: [
                    // Title
                    Text(
                      msg.title,
                      style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _IP.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Shop + date row
                    Row(
                      children: [
                        const Icon(Icons.storefront_rounded,
                            size: 14, color: _IP.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          msg.shopkeeperName,
                          style: GoogleFonts.dmSans(
                              color: _IP.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Text('·',
                            style: GoogleFonts.dmSans(
                                color: _IP.textMuted)),
                        const SizedBox(width: 8),
                        const Icon(Icons.schedule_rounded,
                            size: 14, color: _IP.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(msg.createdAt),
                          style: GoogleFonts.dmSans(
                              color: _IP.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                    // Banner image
                    if (msg.bannerUrl != null &&
                        msg.bannerUrl!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: msg.bannerUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            height: 200,
                            color: _IP.elevated,
                            child: const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: _IP.accent),
                            ),
                          ),
                          errorWidget: (_, __, ___) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    ],
                    // Body
                    const SizedBox(height: 20),
                    Text(
                      msg.body,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        height: 1.6,
                        color: _IP.textPrimary,
                      ),
                    ),
                    // Offer CTA
                    if (hasOffer) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _IP.accentSoft,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _IP.accent.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.local_offer_rounded,
                                    color: _IP.accent, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Exclusive Offer Inside',
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: _IP.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'This campaign includes an offer from this shop. View full details, validity, and discount.',
                              style: GoogleFonts.dmSans(
                                color: _IP.textSecondary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            if (_offerError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _offerError!,
                                  style: GoogleFonts.dmSans(
                                      color: const Color(0xFFE24D69),
                                      fontSize: 12),
                                ),
                              ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed:
                                    _loadingOffer ? null : _viewOffer,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _IP.accent,
                                  foregroundColor: _IP.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                  textStyle: GoogleFonts.dmSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700),
                                ),
                                icon: _loadingOffer
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: _IP.white),
                                      )
                                    : const Icon(
                                        Icons.arrow_forward_rounded),
                                label: Text(_loadingOffer
                                    ? 'Loading offer...'
                                    : 'View Offer'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _timeAgo(DateTime? dt) {
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  return _formatDate(dt);
}

String _formatDate(DateTime? dt) {
  if (dt == null) return '';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}
