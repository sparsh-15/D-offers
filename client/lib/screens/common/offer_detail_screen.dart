import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_design_tokens.dart';
import '../../models/offer_model.dart';
import '../../services/auth_service.dart';

/// Premium offer detail screen — full-bleed header, bottom-pinned CTA.
class OfferDetailScreen extends StatefulWidget {
  const OfferDetailScreen({
    super.key,
    required this.offer,
    this.onLikeChanged,
    this.onOfferUpdated,
    this.onChatPressed,
  });

  final OfferModel offer;
  final VoidCallback? onLikeChanged;
  final ValueChanged<OfferModel>? onOfferUpdated;
  final VoidCallback? onChatPressed;

  @override
  State<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends State<OfferDetailScreen>
    with SingleTickerProviderStateMixin {
  late bool _isLiked;
  late int _likesCount;
  bool _isToggling = false;
  bool _termsExpanded = false;
  bool _isSubmittingCallback = false;

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
    ]).animate(CurvedAnimation(parent: _heartController, curve: Curves.easeInOut));
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
      if (mounted) {
        setState(() {
          _isLiked = result['isLiked'] as bool;
          _likesCount = result['likesCount'] as int;
          _isToggling = false;
        });
        widget.onOfferUpdated?.call(
          widget.offer.copyWith(
            isLiked: _isLiked,
            likesCount: _likesCount,
          ),
        );
        widget.onLikeChanged?.call();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likesCount += _isLiked ? -1 : 1;
          _isToggling = false;
        });
      }
    }
  }

  void _claimOffer() {
    final code = widget.offer.id.substring(0, 8).toUpperCase();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLG)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.spaceLG, AppTokens.spaceLG, AppTokens.spaceLG, AppTokens.space2XL,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your deal code',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppTokens.spaceSM),
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppTokens.spaceMD,
                horizontal: AppTokens.spaceLG,
              ),
              decoration: BoxDecoration(
                color: AppColors.elevated,
                borderRadius: BorderRadius.circular(AppTokens.radiusMD),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    code,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.accent,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied')),
                      );
                    },
                    child: const Icon(Icons.copy_rounded,
                        color: AppColors.textSecondary, size: AppTokens.iconMD),
                  ),
                ],
              ),
            ),
            if (widget.offer.validTo != null) ...[
              const SizedBox(height: AppTokens.spaceSM),
              Text(
                'Valid until ${_formatDate(widget.offer.validTo!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w400,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _negotiateOffer() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLG)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppTokens.spaceLG,
          AppTokens.spaceLG,
          AppTokens.spaceLG,
          MediaQuery.of(context).viewInsets.bottom + AppTokens.space2XL,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Send a request',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTokens.spaceSM),
            Text(
              'The store will review your offer.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppTokens.spaceMD),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'What would you like to negotiate?',
              ),
            ),
            const SizedBox(height: AppTokens.spaceMD),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Request sent')),
                );
              },
              child: const Text('Send Request'),
            ),
          ],
        ),
      ),
    );
  }

  void _shareOffer() {
    final offer = widget.offer;
    final shopName =
        offer.shopName?.trim().isNotEmpty == true ? offer.shopName! : 'Local shop';
    final dynamic rawDiscount = offer.discountValue;
    final num? discountVal = rawDiscount is num
        ? rawDiscount
        : num.tryParse(rawDiscount?.toString() ?? '');

    String discountText;
    if (offer.discountType == 'percentage' && discountVal != null) {
      final decimals = discountVal % 1 == 0 ? 0 : 1;
      discountText = '${discountVal.toStringAsFixed(decimals)}% OFF';
    } else if (offer.discountType == 'fixed' && discountVal != null) {
      final decimals = discountVal % 1 == 0 ? 0 : 1;
      discountText = '₹${discountVal.toStringAsFixed(decimals)} OFF';
    } else {
      discountText = 'Exclusive offer';
    }

    const appLink = 'https://doffers.app/download';

    final text = StringBuffer()
      ..writeln('${offer.title} — $discountText')
      ..writeln('at $shopName on D\'Offers')
      ..writeln()
      ..writeln('Download the app: $appLink');

    Share.share(text.toString());
  }

  Future<void> _showCallbackSheet() async {
    final controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLG)),
      ),
      builder: (ctx) {
        final mediaQuery = MediaQuery.of(ctx);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppTokens.spaceLG,
            AppTokens.spaceLG,
            AppTokens.spaceLG,
            mediaQuery.viewInsets.bottom + AppTokens.space2XL,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Request a callback',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppTokens.spaceXS),
                Text(
                  widget.offer.shopName?.isNotEmpty == true
                      ? widget.offer.shopName!
                      : 'Shop',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppTokens.spaceMD),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    hintText: 'Add a short note for the shop (optional)',
                  ),
                ),
                const SizedBox(height: AppTokens.spaceMD),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: AppTokens.spaceSM),
                    ElevatedButton(
                      onPressed: _isSubmittingCallback
                          ? null
                          : () async {
                              setState(() => _isSubmittingCallback = true);
                              setSheetState(() {});
                              try {
                                await AuthService.instance.requestOfferCallback(
                                  widget.offer.id,
                                  message: controller.text,
                                );
                                if (mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Callback request sent to the shop',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e.toString().replaceFirst('Exception: ', ''),
                                      ),
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isSubmittingCallback = false);
                                  setSheetState(() {});
                                }
                              }
                            },
                      child: _isSubmittingCallback
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOverflowMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLG)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppTokens.spaceSM),
            ListTile(
              leading: const Icon(Icons.share_outlined, color: AppColors.textSecondary),
              title: const Text('Share offer'),
              onTap: () {
                Navigator.pop(context);
                _shareOffer();
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone_callback_outlined, color: AppColors.textSecondary),
              title: const Text('Request callback'),
              onTap: () {
                Navigator.pop(context);
                _showCallbackSheet();
              },
            ),
            if (widget.onChatPressed != null)
              ListTile(
                leading: const Icon(Icons.chat_outlined, color: AppColors.textSecondary),
                title: const Text('Ask AI assistant'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onChatPressed!();
                },
              ),
            const SizedBox(height: AppTokens.spaceSM),
          ],
        ),
      ),
    );
  }

  void _showPhotoGallery(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PhotoGalleryScreen(
          photos: widget.offer.photos,
          initialIndex: initialIndex,
          offerId: widget.offer.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final offer = widget.offer;
    final hasPhotos = offer.photos.isNotEmpty;

    final shopDisplayName =
        offer.shopName?.trim().isNotEmpty == true ? offer.shopName! : 'Local Shop';

    String discountText;
    final dynamic rawDiscount = offer.discountValue;
    final num? discountVal = rawDiscount is num
        ? rawDiscount
        : num.tryParse(rawDiscount?.toString() ?? '');
    if (offer.discountType == 'percentage' && discountVal != null) {
      final decimals = discountVal % 1 == 0 ? 0 : 1;
      discountText = '${discountVal.toStringAsFixed(decimals)}% OFF';
    } else if (offer.discountType == 'fixed' && discountVal != null) {
      final decimals = discountVal % 1 == 0 ? 0 : 1;
      discountText = '₹${discountVal.toStringAsFixed(decimals)} OFF';
    } else {
      discountText = 'Exclusive Offer';
    }

    final isExpired = offer.status == 'expired';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Scrollable content ─────────────────────────────────────────────
          CustomScrollView(
            slivers: [
              // ── Header (photo or typographic) ──────────────────────────────
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.background,
                leading: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    margin: const EdgeInsets.all(AppTokens.spaceSM),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.textPrimary),
                  ),
                ),
                actions: [
                  GestureDetector(
                    onTap: _showOverflowMenu,
                    child: Container(
                      margin: const EdgeInsets.all(AppTokens.spaceSM),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.more_horiz_rounded,
                          color: AppColors.textPrimary),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: hasPhotos
                      ? _PhotoHeader(
                          photoUrl: offer.photos.first,
                          offerId: offer.id,
                          onTap: () => _showPhotoGallery(0),
                        )
                      : _TypographicHeader(
                          discountText: discountText,
                          title: offer.title,
                        ),
                ),
              ),

              // ── Body ───────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.spaceLG, AppTokens.spaceLG,
                    AppTokens.spaceLG, 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Shop name
                      Text(
                        shopDisplayName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppTokens.spaceXS),
                      Row(
                        children: [
                          Text(
                            discountText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (offer.category.trim().isNotEmpty) ...[
                            const SizedBox(width: AppTokens.spaceSM),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                color: AppColors.textMuted,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppTokens.spaceSM),
                            Text(
                              offer.category,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          if (isExpired) ...[
                            const SizedBox(width: AppTokens.spaceSM),
                            Text(
                              '· EXPIRED',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Validity
                      if (offer.validFrom != null || offer.validTo != null) ...[
                        const SizedBox(height: AppTokens.spaceMD),
                        const Divider(color: AppColors.borderSubtle, height: 1),
                        const SizedBox(height: AppTokens.spaceMD),
                        Row(
                          children: [
                            if (offer.validFrom != null)
                              Expanded(
                                child: _ValidityColumn(
                                  label: 'From',
                                  value: _formatDate(offer.validFrom!),
                                ),
                              ),
                            if (offer.validFrom != null && offer.validTo != null)
                              const SizedBox(
                                height: 36,
                                child: VerticalDivider(
                                  color: AppColors.borderSubtle,
                                  width: AppTokens.spaceLG,
                                ),
                              ),
                            if (offer.validTo != null)
                              Expanded(
                                child: _ValidityColumn(
                                  label: 'Until',
                                  value: _formatDate(offer.validTo!),
                                ),
                              ),
                          ],
                        ),
                      ],

                      // Description
                      if (offer.description.trim().isNotEmpty) ...[
                        const SizedBox(height: AppTokens.spaceMD),
                        const Divider(color: AppColors.borderSubtle, height: 1),
                        const SizedBox(height: AppTokens.spaceMD),
                        Text(
                          offer.description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ],

                      // Photos grid
                      if (hasPhotos && offer.photos.length > 1) ...[
                        const SizedBox(height: AppTokens.spaceLG),
                        Text(
                          'Photos',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTokens.spaceSM),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: offer.photos.length,
                            itemBuilder: (ctx, i) => GestureDetector(
                              onTap: () => _showPhotoGallery(i),
                              child: Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: AppTokens.spaceSM),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(AppTokens.radiusMD),
                                  color: AppColors.elevated,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: CachedNetworkImage(
                                  imageUrl: offer.photos[i],
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.accentDim,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => const Icon(
                                    Icons.broken_image_outlined,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Terms (collapsible)
                      if (offer.termsAndConditions.trim().isNotEmpty) ...[
                        const SizedBox(height: AppTokens.spaceLG),
                        const Divider(color: AppColors.borderSubtle, height: 1),
                        GestureDetector(
                          onTap: () => setState(() => _termsExpanded = !_termsExpanded),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTokens.spaceMD,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Terms & Conditions',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                Icon(
                                  _termsExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_termsExpanded) ...[
                          Text(
                            offer.termsAndConditions,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textMuted,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: AppTokens.spaceMD),
                        ],
                      ],

                      // Space for pinned CTA
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Bottom CTA ─────────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.background.withValues(alpha: 0),
                    AppColors.background,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.35],
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                AppTokens.spaceLG,
                AppTokens.space2XL,
                AppTokens.spaceLG,
                MediaQuery.of(context).padding.bottom + AppTokens.spaceLG,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: isExpired ? null : _claimOffer,
                    child: Text(isExpired ? 'This deal has expired' : 'Unlock this deal'),
                  ),
                  const SizedBox(height: AppTokens.spaceSM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _negotiateOffer,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                        ),
                        child: const Text('Negotiate'),
                      ),
                      // Like button inline
                      ScaleTransition(
                        scale: _heartScale,
                        child: GestureDetector(
                          onTap: _toggleLike,
                          child: Row(
                            children: [
                              Icon(
                                _isLiked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_outline_rounded,
                                color: _isLiked
                                    ? AppColors.error
                                    : AppColors.textMuted,
                                size: AppTokens.iconMD,
                              ),
                              const SizedBox(width: AppTokens.spaceXS),
                              Text(
                                '$_likesCount',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _PhotoHeader extends StatelessWidget {
  final String photoUrl;
  final String offerId;
  final VoidCallback onTap;

  const _PhotoHeader({
    required this.photoUrl,
    required this.offerId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'offer_photo_${offerId}_0',
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: photoUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => const ColoredBox(color: AppColors.cardBackground),
              errorWidget: (_, __, ___) =>
                  const ColoredBox(color: AppColors.cardBackground),
            ),
            // Scrim for back button legibility
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xAA000000), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypographicHeader extends StatelessWidget {
  final String discountText;
  final String title;

  const _TypographicHeader({required this.discountText, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: AppColors.cardBackground,
      padding: const EdgeInsets.fromLTRB(
        AppTokens.spaceLG, AppTokens.space2XL, AppTokens.spaceLG, AppTokens.spaceMD,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            discountText,
            style: theme.textTheme.displayLarge?.copyWith(
              color: AppColors.accent,
              height: 1,
            ),
          ),
          const SizedBox(height: AppTokens.spaceSM),
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ValidityColumn extends StatelessWidget {
  final String label;
  final String value;

  const _ValidityColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ── Photo gallery ────────────────────────────────────────────────────────────

class _PhotoGalleryScreen extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;
  final String offerId;

  const _PhotoGalleryScreen({
    required this.photos,
    required this.initialIndex,
    required this.offerId,
  });

  @override
  State<_PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<_PhotoGalleryScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.photos.length}',
          style: const TextStyle(color: AppColors.white70),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (ctx, i) => Center(
          child: Hero(
            tag: 'offer_photo_${widget.offerId}_$i',
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: widget.photos[i],
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.white54,
                    strokeWidth: 2,
                  ),
                ),
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_outlined,
                      size: 64, color: AppColors.white54),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
