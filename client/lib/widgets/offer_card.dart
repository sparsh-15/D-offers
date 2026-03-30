import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_design_tokens.dart';
import '../models/offer_model.dart';
import '../screens/common/offer_detail_screen.dart';
import '../screens/customer/customer_chat_bot_screen.dart';
import '../services/auth_service.dart';
import '../services/reward_service.dart';
import '../core/utils/dialog_helper.dart';
import 'coin_splash_burst.dart';
import 'offer_banner_preview.dart';
import 'shop_logo_widget.dart';

class OfferCard extends StatefulWidget {
  final OfferModel offer;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showLikes;
  final VoidCallback? onLikeChanged;
  final ValueChanged<OfferModel>? onOfferUpdated;
  final bool openDetailOnTap;

  const OfferCard({
    super.key,
    required this.offer,
    this.onTap,
    this.trailing,
    this.showLikes = true,
    this.onLikeChanged,
    this.onOfferUpdated,
    this.openDetailOnTap = true,
  });

  @override
  State<OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<OfferCard> with TickerProviderStateMixin {
  static const double _defaultBannerAspectRatio = 4 / 3;
  static const double _minBannerAspectRatio = 0.7;
  static const double _maxBannerAspectRatio = 2.2;

  late bool _isLiked;
  late int _likesCount;
  bool _isToggling = false;
  late AnimationController _heartController;
  late Animation<double> _heartScale;
  double _bannerAspectRatio = _defaultBannerAspectRatio;
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;

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

    _resolveBannerAspectRatio();
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

    final oldPhoto =
        oldWidget.offer.photos.isNotEmpty ? oldWidget.offer.photos.first : null;
    final newPhoto =
        widget.offer.photos.isNotEmpty ? widget.offer.photos.first : null;
    if (oldPhoto != newPhoto) {
      _bannerAspectRatio = _defaultBannerAspectRatio;
      _clearImageListener();
      _resolveBannerAspectRatio();
    }
  }

  @override
  void dispose() {
    _clearImageListener();
    _heartController.dispose();
    super.dispose();
  }

  int _extractLedgerAmount(Map<String, dynamic>? payload, {int fallback = 50}) {
    final ledger = payload?['ledgerEntry'];
    if (ledger is Map<String, dynamic>) {
      final amount = ledger['amount'];
      if (amount is num) return amount.toInt();
      final parsed = int.tryParse('$amount');
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  String _likeRewardFailureMessage(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    final normalized = message.toLowerCase();
    if (normalized.contains('daily like reward limit')) {
      return 'Daily like reward limit reached.';
    }
    if (normalized.contains('daily coin earning cap exceeded')) {
      return 'Daily coin earning cap reached for today.';
    }
    if (normalized.contains('reward already granted')) {
      return 'Coins for this offer are already claimed.';
    }
    return 'Like saved, but coins were not added.';
  }

  void _playCoinSplash({required int amount, required bool isDebit}) {
    if (!mounted) return;
    showCoinSplashFullscreen(
      context,
      amount: amount,
      isDebit: isDebit,
    );
  }

  void _clearImageListener() {
    if (_imageStream != null && _imageStreamListener != null) {
      _imageStream!.removeListener(_imageStreamListener!);
    }
    _imageStream = null;
    _imageStreamListener = null;
  }

  void _resolveBannerAspectRatio() {
    if (widget.offer.photos.isEmpty || !mounted) return;

    final provider = CachedNetworkImageProvider(widget.offer.photos.first);
    final stream = provider.resolve(const ImageConfiguration());
    final listener = ImageStreamListener((ImageInfo info, bool _) {
      final width = info.image.width.toDouble();
      final height = info.image.height.toDouble();
      if (width <= 0 || height <= 0 || !mounted) return;

      final resolvedAspectRatio =
          (width / height).clamp(_minBannerAspectRatio, _maxBannerAspectRatio);

      if ((_bannerAspectRatio - resolvedAspectRatio).abs() > 0.01) {
        setState(() {
          _bannerAspectRatio = resolvedAspectRatio;
        });
      }

      _clearImageListener();
    }, onError: (_, __) {
      _clearImageListener();
    });

    _clearImageListener();
    _imageStream = stream;
    _imageStreamListener = listener;
    stream.addListener(listener);
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
      final result =
          await AuthService.instance.toggleOfferLike(widget.offer.id);
      final isLikedNow = result['isLiked'] as bool;
      setState(() {
        _isLiked = isLikedNow;
        _likesCount = result['likesCount'] as int;
        _isToggling = false;
      });

      if (isLikedNow) {
        int? splashAmount;
        try {
          final reward =
              await RewardService.instance.awardLikeReward(widget.offer.id);
          final isDuplicate = reward['duplicate'] == true;
          if (!isDuplicate) {
            splashAmount = _extractLedgerAmount(reward);
          }
        } catch (rewardError) {
          debugPrint('Like reward award failed: $rewardError');
          if (mounted) {
            DialogHelper.showErrorSnackBar(
              context,
              _likeRewardFailureMessage(rewardError),
            );
          }
        }
        if (splashAmount != null) {
          _playCoinSplash(
            amount: splashAmount,
            isDebit: false,
          );
        }
      } else {
        try {
          final reversal =
              await RewardService.instance.reverseLikeReward(widget.offer.id);
          final reversed = reversal['reversed'] == true;
          final reason = reversal['reason']?.toString();
          if (reversed) {
            _playCoinSplash(
              amount: _extractLedgerAmount(reversal),
              isDebit: true,
            );
          }
          final message = !reversed
              ? RewardService.instance.unlikeReversalReasonMessage(reason)
              : null;
          if (mounted && message != null && message.isNotEmpty) {
            DialogHelper.showErrorSnackBar(context, message);
          }
        } catch (reverseError) {
          debugPrint('Like reward reverse failed: $reverseError');
        }
      }

      widget.onOfferUpdated?.call(
        widget.offer.copyWith(
          isLiked: _isLiked,
          likesCount: _likesCount,
        ),
      );
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
            onOfferUpdated: widget.onOfferUpdated,
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

    final shopDisplayName = widget.offer.shopName?.trim().isNotEmpty == true
        ? widget.offer.shopName!
        : 'Shop';

    final String? tierLabel = widget.offer.isFeatured
        ? (widget.offer.shopRankingTier == 'top3' ? 'Top Deal' : 'Featured')
        : null;

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

    final hasPhoto = widget.offer.photos.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
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
                // ── Banner / image (fixed aspect ratio for consistent thumbnails) ─
                AspectRatio(
                  aspectRatio: _bannerAspectRatio,
                  child: hasPhoto
                      ? Container(
                          color: AppColors.elevated,
                          child: CachedNetworkImage(
                            imageUrl: widget.offer.photos.first,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.textMuted,
                            ),
                          ),
                        )
                      : const OfferBannerPreview(
                          title: '',
                          discountType: '',
                          discountValue: null,
                          width: double.infinity,
                          height: double.infinity,
                        ),
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
                            Row(
                              children: [
                                ShopLogoWidget(
                                  logoUrl: widget.offer.shopLogoUrl,
                                  radius: 12,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    shopDisplayName,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (tierLabel != null && tierLabel.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentDim
                                      .withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(
                                      AppTokens.radiusFull),
                                  border: Border.all(
                                    color: AppColors.accentDim
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  tierLabel.toUpperCase(),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.accentDim,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    fontSize: 10,
                                  ),
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
                            Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                ScaleTransition(
                                  scale: _heartScale,
                                  child: GestureDetector(
                                    onTap: _toggleLike,
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                          AppTokens.spaceSM),
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
                              ],
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
        ),
      ],
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
