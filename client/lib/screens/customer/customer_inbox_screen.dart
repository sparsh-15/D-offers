import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../models/campaign_model.dart';
import '../../models/offer_model.dart';
import '../../screens/common/offer_detail_screen.dart';
import '../../services/auth_service.dart';
import '../../services/campaign_service.dart';
import '../../widgets/data_state_wrapper.dart';

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final messages = await CampaignService.instance.getInboxMessages();
      if (!mounted) return;
      setState(() {
        _messages = messages;
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
      appBar: AppBar(title: const Text('Inbox')),
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
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final initial =
                  (message.shopkeeperName ?? 'S').isNotEmpty
                      ? (message.shopkeeperName ?? 'S')[0].toUpperCase()
                      : 'S';
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => _openMessage(message),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Leading avatar
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: message.isRead
                                  ? AppColors.surface
                                  : AppColors.accent
                                      .withValues(alpha: 0.15),
                              backgroundImage:
                                  (message.bannerUrl != null &&
                                          message.bannerUrl!.isNotEmpty)
                                      ? CachedNetworkImageProvider(
                                          message.bannerUrl!)
                                      : null,
                              child: (message.bannerUrl == null ||
                                      message.bannerUrl!.isEmpty)
                                  ? Text(
                                      initial,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: message.isRead
                                            ? AppColors.textSecondary
                                            : AppColors.accent,
                                      ),
                                    )
                                  : null,
                            ),
                            if (!message.isRead)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.title,
                                style: TextStyle(
                                  fontWeight: message.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                  fontSize: 14,
                                  color: message.isRead
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${message.shopkeeperName ?? ''} · ${_timeAgo(message.createdAt)}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                message.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if ((message.offerId ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.local_offer_rounded,
                                        size: 12,
                                        color: AppColors.accent,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Offer attached — tap to view',
                                        style: TextStyle(
                                          color: AppColors.accent,
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
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textMuted,
                        ),
                      ],
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

// ─── Detail bottom sheet ──────────────────────────────────────────────────────

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
    setState(() {
      _loadingOffer = true;
      _offerError = null;
    });
    try {
      final offer =
          await AuthService.instance.getCustomerOffer(widget.message.offerId!);
      if (!mounted) return;
      Navigator.of(context).pop();
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => OfferDetailScreen(offer: offer),
        ),
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
    final text = StringBuffer();
    text.writeln('🎁 ${msg.title}');
    text.writeln('From: ${msg.shopkeeperName ?? 'Shop'}');
    text.writeln();
    text.write(msg.body);
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
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle + actions bar
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
                          color: AppColors.textSecondary
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.share_rounded),
                      tooltip: 'Share',
                      onPressed: _share,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  children: [
                    // Title
                    Text(
                      msg.title,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 6),
                    // Shop + date row
                    Row(
                      children: [
                        const Icon(Icons.storefront_rounded,
                            size: 14,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          msg.shopkeeperName ?? 'Shop',
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        const Text('·',
                            style: TextStyle(
                                color: AppColors.textSecondary)),
                        const SizedBox(width: 8),
                        const Icon(Icons.schedule_rounded,
                            size: 14,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(msg.createdAt),
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13),
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
                            color: AppColors.surface,
                            child: const Center(
                                child: CircularProgressIndicator()),
                          ),
                          errorWidget: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                    // Message body
                    const SizedBox(height: 20),
                    Text(
                      msg.body,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    // Offer CTA
                    if (hasOffer) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                AppColors.accent.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.local_offer_rounded,
                                    color: AppColors.accent, size: 18),
                                const SizedBox(width: 8),
                                const Text(
                                  'Exclusive Offer Inside',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'This campaign includes an offer from this shop. View full details, validity, and discount.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            if (_offerError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _offerError!,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 12),
                                ),
                              ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed:
                                    _loadingOffer ? null : _viewOffer,
                                icon: _loadingOffer
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : const Icon(Icons.arrow_forward_rounded),
                                label: Text(_loadingOffer
                                    ? 'Loading offer…'
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

// ─── Helpers ──────────────────────────────────────────────────────────────────

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
  final months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}
