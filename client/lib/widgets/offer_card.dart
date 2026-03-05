import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_design_tokens.dart';
import '../models/offer_model.dart';
import '../screens/common/offer_detail_screen.dart';
import '../screens/customer/customer_chat_bot_screen.dart';
import '../services/auth_service.dart';
import '../core/utils/dialog_helper.dart';
import 'offer_banner_preview.dart';

class OfferCard extends StatefulWidget {
  final OfferModel offer;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showLikes;
  final VoidCallback? onLikeChanged;
  final bool openDetailOnTap;

  const OfferCard({
    super.key,
    required this.offer,
    this.onTap,
    this.trailing,
    this.showLikes = true,
    this.onLikeChanged,
    this.openDetailOnTap = true,
  });

  @override
  State<OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<OfferCard>
    with SingleTickerProviderStateMixin {
  late bool _isLiked;
  late int _likesCount;
  bool _isToggling = false;
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.offer.isLiked;
    _likesCount = widget.offer.likesCount;

    _heartController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(OfferCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.offer.id != widget.offer.id ||
        oldWidget.offer.isLiked != widget.offer.isLiked ||
        oldWidget.offer.likesCount != widget.offer.likesCount) {
      _isLiked = widget.offer.isLiked;
      _likesCount = widget.offer.likesCount;
    }
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    if (_isToggling) return;
    setState(() {
      _isToggling = true;
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });
    _heartController.forward(from: 0);
    try {
      final result = await AuthService.instance.toggleOfferLike(widget.offer.id);
      setState(() {
        _isLiked = result['isLiked'] as bool;
        _likesCount = result['likesCount'] as int;
        _isToggling = false;
      });
      widget.onLikeChanged?.call();
    } catch (e) {
      setState(() {
        _isLiked = !_isLiked;
        _likesCount += _isLiked ? -1 : 1;
        _isToggling = false;
      });
      if (mounted) {
        DialogHelper.showErrorSnackBar(context, 'Failed to update like');
      }
    }
  }

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }
    if (widget.openDetailOnTap) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OfferDetailScreen(
            offer: widget.offer,
            onLikeChanged: widget.onLikeChanged,
            onChatPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CustomerChatBotScreen(),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpired = widget.offer.status == 'expired';

    final shopDisplayName =
        widget.offer.shopName?.trim().isNotEmpty == true
            ? widget.offer.shopName!
            : 'Shop';

    // Optional: badge for higher subscription tier.
    // Currently not wired to backend; leave null until metadata is added.
    const String? tierLabel = null;

    String discountLabel;
    final dynamic rawDiscount = widget.offer.discountValue;
    final num? discountVal = rawDiscount is num
        ? rawDiscount
        : num.tryParse(rawDiscount?.toString() ?? '');
    if (widget.offer.discountType == 'percentage' && discountVal != null) {
      final decimals = discountVal % 1 == 0 ? 0 : 1;
      discountLabel = '${discountVal.toStringAsFixed(decimals)}%';
    } else if (widget.offer.discountType == 'fixed' && discountVal != null) {
      final decimals = discountVal % 1 == 0 ? 0 : 1;
      discountLabel = '₹${discountVal.toStringAsFixed(decimals)}';
    } else {
      discountLabel = 'Offer';
    }

    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(AppTokens.radiusLG),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _handleTap,
        splashColor: AppColors.highlight.withValues(alpha: 0.4),
        highlightColor: AppColors.highlight.withValues(alpha: 0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Banner / image ──────────────────────────────────────────────
            OfferBannerPreview(
              title: widget.offer.title,
              discountType: widget.offer.discountType,
              discountValue: widget.offer.discountValue,
              width: double.infinity,
              height: 140,
            ),

            // ── Info strip ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.spaceMD,
                AppTokens.spaceSM + 2,
                AppTokens.spaceSM,
                AppTokens.spaceSM + 2,
              ),
              child: Row(
                children: [
                  // Shop name + discount badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shopDisplayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (tierLabel != null && tierLabel.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            tierLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.highlight,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              discountLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.accent,
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (widget.offer.discountType == 'percentage')
                              Text(
                                ' OFF',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.accent,
                                  letterSpacing: 0.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            if (isExpired) ...[
                              const SizedBox(width: AppTokens.spaceSM),
                              Text(
                                'EXPIRED',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.error,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (widget.offer.validTo != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              _formatValidity(widget.offer.validTo!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                                letterSpacing: 0.2,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Like button
                  if (widget.trailing != null)
                    widget.trailing!
                  else if (widget.showLikes)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: _heartScale,
                          child: GestureDetector(
                            onTap: _toggleLike,
                            child: Padding(
                              padding: const EdgeInsets.all(AppTokens.spaceSM),
                              child: Icon(
                                _isLiked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_outline_rounded,
                                color: _isLiked
                                    ? AppColors.error
                                    : AppColors.textMuted,
                                size: AppTokens.iconMD,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          '$_likesCount',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatValidity(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);
    if (diff.isNegative) return 'Expired';
    if (diff.inDays == 0) return 'Ends today';
    if (diff.inDays == 1) return 'Ends tomorrow';
    if (diff.inDays < 7) return 'Ends in ${diff.inDays}d';
    return 'Until ${date.day}/${date.month}/${date.year}';
  }
}
