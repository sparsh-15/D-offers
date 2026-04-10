import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_design_tokens.dart';
import '../models/offer_model.dart';
import '../screens/common/offer_detail_screen.dart';
import '../screens/customer/customer_chat_bot_screen.dart';
import '../services/offer_like_flow.dart';
import '../core/utils/dialog_helper.dart';
import 'coin_splash_burst.dart';
import 'offer_banner_preview.dart';
import 'shop_logo_widget.dart';

// ── Light palette ─────────────────────────────────────────────────────────────
class _CP {
  static const surface       = Color(0xFFFFFFFF);
  static const elevated      = Color(0xFFF4F7FB);
  static const border        = Color(0xFFDCE3EC);
  static const accent        = Color(0xFFE88428);
  static const accentSoft    = Color(0xFFFBE7D6);
  static const textPrimary   = Color(0xFF1E2433);
  static const textSecondary = Color(0xFF334155);
  static const textMuted     = Color(0xFF667085);
  static const error         = Color(0xFFE24D69);
  static const inkSplash     = Color(0x14E88428);
  static const inkHighlight  = Color(0x0AE88428);
}

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
    final optimisticLiked = !_isLiked;
    setState(() {
      _isToggling = true;
      _isLiked = optimisticLiked;
      _likesCount += optimisticLiked ? 1 : -1;
    });
    _heartController.forward(from: 0);
    if (optimisticLiked) {
      _playCoinSplash(
        amount: OfferLikeFlow.immediateLikeSplashAmount,
        isDebit: false,
      );
    }
    try {
      final toggle = await OfferLikeFlow.instance.toggleLike(widget.offer.id);
      if (!mounted) return;
      setState(() {
        _isLiked = toggle.isLiked;
        _likesCount = toggle.likesCount;
      });

      widget.onOfferUpdated?.call(
        widget.offer.copyWith(
          isLiked: _isLiked,
          likesCount: _likesCount,
        ),
      );

      final reward = await OfferLikeFlow.instance.settleReward(
        offerId: widget.offer.id,
        isLikedNow: _isLiked,
      );
      if (!mounted) return;

      if (!_isLiked && reward.unlikeSplashAmount != null) {
        _playCoinSplash(
          amount: reward.unlikeSplashAmount!,
          isDebit: true,
        );
      }
      if (reward.message != null && reward.message!.isNotEmpty) {
        DialogHelper.showErrorSnackBar(context, reward.message!);
      }
      widget.onLikeChanged?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLiked = !_isLiked;
        _likesCount += _isLiked ? -1 : 1;
      });
      if (mounted) {
        DialogHelper.showErrorSnackBar(context, 'Failed to update like');
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _isToggling = false;
      });
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
          color: _CP.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusLG),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _handleTap,
            splashColor: _CP.inkSplash,
            highlightColor: _CP.inkHighlight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Banner ──────────────────────────────────────────────────
                AspectRatio(
                  aspectRatio: _bannerAspectRatio,
                  child: hasPhoto
                      ? Container(
                          color: _CP.elevated,
                          child: CachedNetworkImage(
                            imageUrl: widget.offer.photos.first,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _CP.accent,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.broken_image_outlined,
                              color: _CP.textMuted,
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

                // ── Info strip ───────────────────────────────────────────────
                Container(
                  decoration: const BoxDecoration(
                    color: _CP.surface,
                    border: Border(
                      top: BorderSide(color: _CP.border, width: 1),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.spaceMD,
                    AppTokens.spaceSM + 2,
                    AppTokens.spaceSM,
                    AppTokens.spaceSM + 2,
                  ),
                  child: Row(
                    children: [
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
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _CP.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (tierLabel != null &&
                                tierLabel.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _CP.accentSoft,
                                  borderRadius: BorderRadius.circular(
                                      AppTokens.radiusFull),
                                  border: Border.all(
                                    color: _CP.accent.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  tierLabel.toUpperCase(),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: _CP.accent,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(
                                  discountLabel,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _CP.accent,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                if (widget.offer.discountType ==
                                    'percentage')
                                  Text(
                                    ' OFF',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _CP.accent,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                if (isExpired) ...[
                                  const SizedBox(width: AppTokens.spaceSM),
                                  Text(
                                    'EXPIRED',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: _CP.error,
                                      letterSpacing: 0.4,
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
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                    color: _CP.textMuted,
                                    letterSpacing: 0.1,
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
                                  padding: const EdgeInsets.all(
                                      AppTokens.spaceSM),
                                  child: Icon(
                                    _isLiked
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_outline_rounded,
                                    color: _isLiked
                                        ? _CP.error
                                        : _CP.textMuted,
                                    size: AppTokens.iconMD,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              '$_likesCount',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: _CP.textMuted,
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
        // ── Card border overlay ──────────────────────────────────────────────
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radiusLG),
                border: Border.all(color: _CP.border),
              ),
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
