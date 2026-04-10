import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_design_tokens.dart';
import '../../core/constants/app_strings.dart';
import '../../models/offer_model.dart';
import '../../models/role_enum.dart';
import '../../models/shopkeeper_profile_model.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';
import '../../services/offer_like_flow.dart';
import '../../widgets/coin_splash_burst.dart';
import '../../widgets/shop_logo_widget.dart';
import '../customer/customer_dashboard.dart';

// ── Light theme palette (matches home/profile/loans new theme) ───────────────
class _P {
  static const canvas         = Color(0xFFF3F5F8);
  static const surface        = Color(0xFFFFFFFF);
  static const cardBg         = Color(0xFFFFFFFF);
  static const elevated       = Color(0xFFF4F7FB);
  static const border         = Color(0xFFDCE3EC);
  static const borderSubtle   = Color(0xFFEAEEF4);
  static const accent         = Color(0xFFE88428);
  static const accentSoft     = Color(0xFFFBE7D6);
  static const accentGreen    = Color(0xFF1F9D65);
  static const accentGreenBg  = Color(0xFFE4F6EC);
  static const textPrimary    = Color(0xFF1E2433);
  static const textSecondary  = Color(0xFF334155);
  static const textMuted      = Color(0xFF667085);
  static const error          = Color(0xFFE24D69);
  static const errorBg        = Color(0xFFFDEBEC);
  static const black          = Color(0xFF000000);
  static const white          = Color(0xFFFFFFFF);
  static const white70        = Color(0xB3FFFFFF);
  static const white54        = Color(0x8AFFFFFF);
}

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
    with TickerProviderStateMixin {
  late bool _isLiked;
  late int _likesCount;
  bool _isToggling = false;
  bool _termsExpanded = false;
  bool _isSubmittingCallback = false;
  bool _isClaimingDeal = false;
  bool _isLoadingShop = false;
  String? _shopError;
  ShopkeeperProfileModel? _shopProfile;
  late final PageController _offerPhotoController;
  int _currentOfferPhotoIndex = 0;
  Timer? _offerPhotoAutoPlayTimer;

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
    _offerPhotoController = PageController();
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 50),
    ]).animate(
        CurvedAnimation(parent: _heartController, curve: Curves.easeInOut));

    _startOfferPhotoAutoPlay();
    _loadShopDetails();
  }

  @override
  void dispose() {
    _offerPhotoAutoPlayTimer?.cancel();
    _offerPhotoController.dispose();
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

  void _startOfferPhotoAutoPlay() {
    _offerPhotoAutoPlayTimer?.cancel();
    if (widget.offer.photos.length <= 1) return;

    _offerPhotoAutoPlayTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) {
        if (!mounted || !_offerPhotoController.hasClients) return;
        final nextIndex =
            (_currentOfferPhotoIndex + 1) % widget.offer.photos.length;
        _offerPhotoController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  void _pauseOfferPhotoAutoPlay() {
    _offerPhotoAutoPlayTimer?.cancel();
  }

  void _resumeOfferPhotoAutoPlay() {
    _startOfferPhotoAutoPlay();
  }

  void _selectOfferPhoto(int index) {
    if (!_offerPhotoController.hasClients) return;
    _pauseOfferPhotoAutoPlay();
    _offerPhotoController.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
    _resumeOfferPhotoAutoPlay();
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
      if (mounted) {
        setState(() {
          _isLiked = toggle.isLiked;
          _likesCount = toggle.likesCount;
        });
      }

      if (mounted) {
        widget.onOfferUpdated?.call(
          widget.offer.copyWith(
            isLiked: _isLiked,
            likesCount: _likesCount,
          ),
        );
      }

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(reward.message!)),
        );
      }
      widget.onLikeChanged?.call();
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likesCount += _isLiked ? -1 : 1;
        });
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _isToggling = false;
      });
    }
  }

  Future<void> _loadShopDetails() async {
    setState(() {
      _isLoadingShop = true;
      _shopError = null;
    });
    try {
      final profile = await AuthService.instance
          .getPublicShopProfile(widget.offer.shopkeeperId);
      if (!mounted) return;
      setState(() {
        _shopProfile = profile;
        _isLoadingShop = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingShop = false;
        _shopError = e.toString();
      });
    }
  }

  bool get _hasShopMapLocation =>
      _shopProfile?.latitude != null && _shopProfile?.longitude != null;

  String? get _shopMapPreviewUrl {
    if (!_hasShopMapLocation) return null;
    final latitude = _shopProfile!.latitude!;
    final longitude = _shopProfile!.longitude!;
    return 'https://staticmap.openstreetmap.de/staticmap.php?center=$latitude,$longitude&zoom=15&size=800x360&markers=$latitude,$longitude,lightgreen1';
  }

  Future<void> _openShopLocationInMaps() async {
    if (!_hasShopMapLocation) return;

    final latitude = _shopProfile!.latitude!;
    final longitude = _shopProfile!.longitude!;
    final label = _shopProfile!.shopName.isNotEmpty
        ? _shopProfile!.shopName
        : (widget.offer.shopName?.trim().isNotEmpty == true
            ? widget.offer.shopName!.trim()
            : 'Shop location');

    final geoUri = Uri.parse(
        'geo:$latitude,$longitude?q=$latitude,$longitude(${Uri.encodeComponent(label)})');
    final googleMapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    try {
      final launchedGeo = await launchUrl(
        geoUri,
        mode: LaunchMode.externalApplication,
      );
      if (launchedGeo) return;

      final launchedGoogleMaps = await launchUrl(
        googleMapsUri,
        mode: LaunchMode.externalApplication,
      );
      if (launchedGoogleMaps) return;
    } on MissingPluginException {
      await Clipboard.setData(ClipboardData(text: googleMapsUri.toString()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Maps plugin is not ready in this app session. Restart the app once. Link copied.',
          ),
        ),
      );
      return;
    } catch (_) {
      // Fall through to the generic error message below.
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open map application.')),
    );
  }

  Future<void> _claimOffer() async {
    if (_isClaimingDeal) return;

    final user = AuthStore.currentUser;
    final hasClaimCapability = user == null ||
        user.hasRole(UserRole.customer) ||
        user.hasRole(UserRole.ssa);

    if (!hasClaimCapability) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Your account does not have permission to claim offers'),
        ),
      );
      return;
    }

    setState(() => _isClaimingDeal = true);

    try {
      final claim = await AuthService.instance.claimOffer(widget.offer.id);
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: _P.surface,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLG)),
        ),
        builder: (_) => SafeArea(
          child: SingleChildScrollView(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: _P.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: _P.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.spaceMD),
                Text(
                  'Congratulations!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _P.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppTokens.spaceXS),
                Text(
                  claim.isRedeemed
                      ? 'This claimed deal is already redeemed.'
                      : 'Show this coupon code to the shopkeeper and ask them to scan your QR from Claims tab or enter code manually.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _P.textSecondary,
                      ),
                ),
                const SizedBox(height: AppTokens.spaceLG),
                Container(
                  padding: const EdgeInsets.all(AppTokens.spaceMD),
                  decoration: BoxDecoration(
                    color: _P.elevated,
                    borderRadius: BorderRadius.circular(AppTokens.radiusMD),
                    border: Border.all(color: _P.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your claimed coupon',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: _P.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: AppTokens.spaceSM),
                      Text(
                        claim.coupon.code,
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: _P.accent,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: AppTokens.spaceSM),
                      Text(
                        '1. Go to shop and open Claims tab for QR.\n'
                        '2. Ask shopkeeper to use Verify Customer Coupon.\n'
                        '3. They can scan QR or enter this code manually.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _P.textSecondary,
                              height: 1.5,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.spaceMD),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: claim.coupon.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coupon code copied')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _P.textSecondary,
                      side: const BorderSide(color: _P.border),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy Coupon Code'),
                  ),
                ),
                const SizedBox(height: AppTokens.spaceSM),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) =>
                              const CustomerDashboard(initialTabIndex: 2),
                        ),
                        (route) => route.isFirst,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _P.accent,
                      foregroundColor: _P.white,
                      minimumSize: const Size(double.infinity, 52),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.qr_code_2_rounded),
                    label: const Text('Open My Claims (QR)'),
                  ),
                ),
                if (widget.offer.validTo != null) ...[
                  const SizedBox(height: AppTokens.spaceSM),
                  Text(
                    'Valid until ${_formatDate(widget.offer.validTo!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _P.textMuted,
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                ],
                const SizedBox(height: AppTokens.spaceMD),
                Container(
                  padding: const EdgeInsets.all(AppTokens.spaceSM),
                  decoration: BoxDecoration(
                    color: _P.accentSoft.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                    border: Border.all(color: _P.accent.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_rounded, size: 16, color: _P.accent),
                      const SizedBox(width: AppTokens.spaceXS),
                      Expanded(
                        child: Text(
                          'Open Claims tab to show QR to shopkeeper',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: _P.accent,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isClaimingDeal = false);
      }
    }
  }

  void _negotiateOffer() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _P.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLG)),
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _P.textPrimary,
                  ),
            ),
            const SizedBox(height: AppTokens.spaceSM),
            Text(
              'The store will review your offer.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: _P.textSecondary),
            ),
            const SizedBox(height: AppTokens.spaceMD),
            TextField(
              controller: controller,
              maxLines: 3,
              style: const TextStyle(color: _P.textPrimary),
              decoration: InputDecoration(
                hintText: 'What would you like to negotiate?',
                hintStyle: const TextStyle(color: _P.textMuted),
                filled: true,
                fillColor: _P.elevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _P.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _P.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _P.accent, width: 1.5),
                ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: _P.accent,
                foregroundColor: _P.white,
                minimumSize: const Size(double.infinity, 52),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Send Request'),
            ),
          ],
        ),
      ),
    );
  }

  void _shareOffer() {
    final offer = widget.offer;
    final shopName = offer.shopName?.trim().isNotEmpty == true
        ? offer.shopName!
        : 'Local shop';
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

    const appLink = 'https://MyOffers.app/download';

    final text = StringBuffer()
      ..writeln('${offer.title} — $discountText')
      ..writeln('at $shopName on ${AppStrings.appName}')
      ..writeln()
      ..writeln('Download the app: $appLink');

    Share.share(text.toString());
  }

  Future<void> _showCallbackSheet() async {
    final controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _P.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLG)),
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _P.textPrimary,
                      ),
                ),
                const SizedBox(height: AppTokens.spaceXS),
                Text(
                  widget.offer.shopName?.isNotEmpty == true
                      ? widget.offer.shopName!
                      : 'Shop',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _P.textSecondary,
                      ),
                ),
                const SizedBox(height: AppTokens.spaceMD),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  maxLength: 200,
                  style: const TextStyle(color: _P.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Add a short note for the shop (optional)',
                    hintStyle: const TextStyle(color: _P.textMuted),
                    filled: true,
                    fillColor: _P.elevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _P.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _P.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: _P.accent, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.spaceMD),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                          foregroundColor: _P.textSecondary),
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
                                        e
                                            .toString()
                                            .replaceFirst('Exception: ', ''),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _P.accent,
                        foregroundColor: _P.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
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
      backgroundColor: _P.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLG)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppTokens.spaceSM),
            ListTile(
              leading: const Icon(Icons.share_outlined, color: _P.textSecondary),
              title: const Text('Share offer',
                  style: TextStyle(color: _P.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _shareOffer();
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone_callback_outlined,
                  color: _P.textSecondary),
              title: const Text('Request callback',
                  style: TextStyle(color: _P.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _showCallbackSheet();
              },
            ),
            if (widget.onChatPressed != null)
              ListTile(
                leading:
                    const Icon(Icons.chat_outlined, color: _P.textSecondary),
                title: const Text('Ask AI assistant',
                    style: TextStyle(color: _P.textPrimary)),
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
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final ctaReservedHeight = bottomInset + 190;
    final offer = widget.offer;
    final hasPhotos = offer.photos.isNotEmpty;

    final shopDisplayName = offer.shopName?.trim().isNotEmpty == true
        ? offer.shopName!
        : 'Local Shop';

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
      backgroundColor: _P.canvas,
      body: Stack(
        children: [
          // ── Scrollable content ─────────────────────────────────────────────
          CustomScrollView(
            slivers: [
              // ── Header (photo or typographic) ──────────────────────────────
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: _P.canvas,
                leading: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    margin: const EdgeInsets.all(AppTokens.spaceSM),
                    decoration: BoxDecoration(
                      color: _P.white.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _P.textPrimary.withValues(alpha: 0.08),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: _P.textPrimary),
                  ),
                ),
                actions: [
                  GestureDetector(
                    onTap: _showOverflowMenu,
                    child: Container(
                      margin: const EdgeInsets.all(AppTokens.spaceSM),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _P.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _P.textPrimary.withValues(alpha: 0.08),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.more_horiz_rounded,
                          color: _P.textPrimary),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: hasPhotos
                      ? _OfferPhotoCarousel(
                          photos: offer.photos,
                          offerId: offer.id,
                          controller: _offerPhotoController,
                          currentIndex: _currentOfferPhotoIndex,
                          onInteractionStart: _pauseOfferPhotoAutoPlay,
                          onInteractionEnd: _resumeOfferPhotoAutoPlay,
                          onPageChanged: (index) {
                            if (!mounted) return;
                            setState(() => _currentOfferPhotoIndex = index);
                          },
                          onTapPhoto: _showPhotoGallery,
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
                    AppTokens.spaceLG,
                    AppTokens.spaceLG,
                    AppTokens.spaceLG,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.title,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: _P.textPrimary,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: AppTokens.spaceXS),
                      Row(
                        children: [
                          ShopLogoWidget(
                            logoUrl: _shopProfile?.logoUrl ?? offer.shopLogoUrl,
                            radius: 11,
                          ),
                          const SizedBox(width: AppTokens.spaceXS),
                          Expanded(
                            child: Text(
                              shopDisplayName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: _P.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.spaceMD),
                      Wrap(
                        spacing: AppTokens.spaceSM,
                        runSpacing: AppTokens.spaceSM,
                        children: [
                          _InfoChip(
                            icon: Icons.local_offer_rounded,
                            label: discountText,
                            foreground: _P.accent,
                            background: _P.accentSoft,
                          ),
                          if (offer.category.trim().isNotEmpty)
                            _InfoChip(
                              icon: Icons.category_rounded,
                              label: offer.category,
                            ),
                          _InfoChip(
                            icon: isExpired
                                ? Icons.event_busy_rounded
                                : Icons.verified_rounded,
                            label: isExpired ? 'Expired' : 'Active deal',
                            foreground: isExpired ? _P.error : _P.accentGreen,
                            background:
                                isExpired ? _P.errorBg : _P.accentGreenBg,
                          ),
                          _InfoChip(
                            icon: Icons.favorite_outline_rounded,
                            label: '${offer.likesCount} likes',
                          ),
                        ],
                      ),

                      if (hasPhotos) ...[
                        const SizedBox(height: AppTokens.spaceMD),
                        SizedBox(
                          height: 76,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: offer.photos.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: AppTokens.spaceSM),
                            itemBuilder: (context, index) {
                              final isSelected =
                                  index == _currentOfferPhotoIndex;
                              return GestureDetector(
                                onTap: () => _selectOfferPhoto(index),
                                child: _PhotoThumbnailTile(
                                  imageUrl: offer.photos[index],
                                  isSelected: isSelected,
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: AppTokens.spaceLG),
                      const _SectionTitle('Offer description'),
                      const SizedBox(height: AppTokens.spaceSM),
                      _SectionCard(
                        child: Text(
                          offer.description.trim().isNotEmpty
                              ? offer.description
                              : 'No description was added for this offer yet.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: offer.description.trim().isNotEmpty
                                ? _P.textSecondary
                                : _P.textMuted,
                            height: 1.6,
                          ),
                        ),
                      ),

                      const SizedBox(height: AppTokens.spaceLG),
                      const _SectionTitle('Offer timeline'),
                      const SizedBox(height: AppTokens.spaceSM),
                      _SectionCard(
                        child: Column(
                          children: [
                            if (offer.createdAt != null)
                              _TimelineItem(
                                icon: Icons.add_circle_outline_rounded,
                                title: 'Created',
                                value: _formatDateTime(offer.createdAt!),
                              ),
                            if (offer.updatedAt != null)
                              _TimelineItem(
                                icon: Icons.update_rounded,
                                title: 'Last updated',
                                value: _formatDateTime(offer.updatedAt!),
                              ),
                            if (offer.validFrom != null)
                              _TimelineItem(
                                icon: Icons.event_available_rounded,
                                title: 'Valid from',
                                value: _formatDateTime(offer.validFrom!),
                              ),
                            if (offer.validTo != null)
                              _TimelineItem(
                                icon: Icons.event_busy_rounded,
                                title: 'Valid until',
                                value: _formatDateTime(offer.validTo!),
                              ),
                            _TimelineItem(
                              icon: Icons.flag_circle_rounded,
                              title: 'Status',
                              value: offer.status.toUpperCase(),
                              isLast: true,
                            ),
                          ],
                        ),
                      ),

                      if ((_shopProfile?.shopImages.isNotEmpty ?? false)) ...[
                        const SizedBox(height: AppTokens.spaceLG),
                        const _SectionTitle('Shop photos'),
                        const SizedBox(height: AppTokens.spaceSM),
                        SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _shopProfile!.shopImages.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: AppTokens.spaceSM),
                            itemBuilder: (context, index) => GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => _PhotoGalleryScreen(
                                      photos: _shopProfile!.shopImages,
                                      initialIndex: index,
                                      offerId:
                                          '${widget.offer.id}_shop_${_shopProfile!.id}',
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                child: _PhotoThumbnailTile(
                                  imageUrl: _shopProfile!.shopImages[index],
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Offer photos
                      if (hasPhotos && offer.photos.length > 1) ...[
                        const SizedBox(height: AppTokens.spaceLG),
                        const _SectionTitle('Offer photos'),
                        const SizedBox(height: AppTokens.spaceSM),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: offer.photos.length,
                            itemBuilder: (ctx, i) => GestureDetector(
                              onTap: () => _showPhotoGallery(i),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  right: AppTokens.spaceSM,
                                ),
                                child: _PhotoThumbnailTile(
                                  imageUrl: offer.photos[i],
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Terms (collapsible)
                      if (offer.termsAndConditions.trim().isNotEmpty) ...[
                        const SizedBox(height: AppTokens.spaceLG),
                        const _SectionTitle('Terms & conditions'),
                        const SizedBox(height: AppTokens.spaceSM),
                        _SectionCard(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () => setState(
                                    () => _termsExpanded = !_termsExpanded),
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Read important conditions before visiting the store',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: _P.textSecondary,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      _termsExpanded
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      color: _P.textMuted,
                                    ),
                                  ],
                                ),
                              ),
                              if (_termsExpanded) ...[
                                const SizedBox(height: AppTokens.spaceMD),
                                Text(
                                  offer.termsAndConditions,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: _P.textMuted,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: AppTokens.spaceLG),
                      const _SectionTitle('Shop details'),
                      const SizedBox(height: AppTokens.spaceSM),
                      if (_isLoadingShop)
                        _SectionCard(
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _P.accent,
                                ),
                              ),
                              const SizedBox(width: AppTokens.spaceSM),
                              Expanded(
                                child: Text(
                                  'Loading shop details...',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: _P.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_shopProfile != null)
                        _SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShopLogoWidget(
                                    logoUrl: _shopProfile!.logoUrl,
                                    radius: 24,
                                  ),
                                  const SizedBox(width: AppTokens.spaceSM),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _shopProfile!.shopName.isNotEmpty
                                              ? _shopProfile!.shopName
                                              : (widget.offer.shopName ??
                                                  'Shop details'),
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            color: _P.textPrimary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (_shopProfile!.category.isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 2),
                                            child: Text(
                                              _shopProfile!.category,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: _P.textSecondary,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTokens.spaceMD),
                              if ((_shopProfile!.ownerName ?? '').isNotEmpty)
                                _ShopDetailRow(
                                  icon: Icons.person_rounded,
                                  label: 'Owner',
                                  value: _shopProfile!.ownerName!,
                                ),
                              if ((_shopProfile!.ownerPhone ?? '').isNotEmpty)
                                _ShopDetailRow(
                                  icon: Icons.phone_rounded,
                                  label: 'Contact',
                                  value: '+91 ${_shopProfile!.ownerPhone}',
                                ),
                              if (_shopProfile!.address.isNotEmpty)
                                _ShopDetailRow(
                                  icon: Icons.location_on_rounded,
                                  label: 'Address',
                                  value: _shopProfile!.address,
                                  maxLines: 3,
                                ),
                              if (_shopProfile!.city.isNotEmpty ||
                                  _shopProfile!.pincode.isNotEmpty)
                                _ShopDetailRow(
                                  icon: Icons.map_rounded,
                                  label: 'Area',
                                  value: [
                                    if (_shopProfile!.city.isNotEmpty)
                                      _shopProfile!.city,
                                    if (_shopProfile!.pincode.isNotEmpty)
                                      _shopProfile!.pincode,
                                  ].join(', '),
                                ),
                              if (_hasShopMapLocation) ...[
                                const SizedBox(height: AppTokens.spaceMD),
                                Text(
                                  'Map location',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: _P.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: AppTokens.spaceSM),
                                GestureDetector(
                                  onTap: _openShopLocationInMaps,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _P.elevated,
                                      borderRadius: BorderRadius.circular(
                                        AppTokens.radiusMD,
                                      ),
                                      border: Border.all(color: _P.border),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Stack(
                                      children: [
                                        AspectRatio(
                                          aspectRatio: 16 / 9,
                                          child: CachedNetworkImage(
                                            imageUrl: _shopMapPreviewUrl!,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) =>
                                                ColoredBox(
                                              color: _P.elevated,
                                              child: const Center(
                                                child: SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: _P.accent,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            errorWidget: (_, __, ___) =>
                                                Container(
                                              color: _P.elevated,
                                              padding: const EdgeInsets.all(
                                                AppTokens.spaceMD,
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.map_outlined,
                                                    color: _P.textMuted,
                                                    size: 30,
                                                  ),
                                                  const SizedBox(
                                                    height: AppTokens.spaceSM,
                                                  ),
                                                  Text(
                                                    'Map preview unavailable',
                                                    style: theme
                                                        .textTheme.bodyMedium
                                                        ?.copyWith(
                                                      color: _P.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: AppTokens.spaceSM,
                                          right: AppTokens.spaceSM,
                                          bottom: AppTokens.spaceSM,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppTokens.spaceSM,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _P.white
                                                  .withValues(alpha: 0.9),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                AppTokens.radiusSM,
                                              ),
                                              border: Border.all(
                                                  color: _P.border),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.place_rounded,
                                                  color: _P.accent,
                                                  size: 18,
                                                ),
                                                const SizedBox(
                                                  width: AppTokens.spaceXS,
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    'Tap to open in Maps',
                                                    style: theme
                                                        .textTheme.bodySmall
                                                        ?.copyWith(
                                                      color: _P.textPrimary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.open_in_new_rounded,
                                                  color: _P.textSecondary,
                                                  size: 16,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              if (_shopProfile!.description.isNotEmpty)
                                _ShopDetailRow(
                                  icon: Icons.info_outline_rounded,
                                  label: 'About shop',
                                  value: _shopProfile!.description,
                                  maxLines: 4,
                                ),
                            ],
                          ),
                        )
                      else
                        _SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.storefront_outlined,
                                    color: _P.textMuted,
                                    size: 18,
                                  ),
                                  const SizedBox(width: AppTokens.spaceXS),
                                  Expanded(
                                    child: Text(
                                      offer.shopName?.trim().isNotEmpty == true
                                          ? offer.shopName!
                                          : 'Shop details unavailable',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: _P.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTokens.spaceXS),
                              Text(
                                _shopError != null
                                    ? 'Could not load full shop profile right now.'
                                    : 'Detailed shop profile is not available for this offer yet.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: _P.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Space for pinned CTA
                      SizedBox(height: ctaReservedHeight),
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
                    _P.canvas.withValues(alpha: 0),
                    _P.canvas,
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
                    onPressed: widget.offer.isClaimed
                        ? null
                        : ((isExpired || _isClaimingDeal) ? null : _claimOffer),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _P.accent,
                      foregroundColor: _P.white,
                      disabledBackgroundColor: _P.border,
                      disabledForegroundColor: _P.textMuted,
                      minimumSize: const Size(double.infinity, 54),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    child: Text(widget.offer.isClaimed
                        ? 'Already claimed ✓'
                        : (isExpired
                            ? 'This deal has expired'
                            : (_isClaimingDeal ? 'Claiming...' : 'Claim this deal'))),
                  ),
                  const SizedBox(height: AppTokens.spaceSM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _negotiateOffer,
                        style: TextButton.styleFrom(
                          foregroundColor: _P.textSecondary,
                        ),
                        child: const Text('Negotiate'),
                      ),
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
                                color: _isLiked ? _P.error : _P.textMuted,
                                size: AppTokens.iconMD,
                              ),
                              const SizedBox(width: AppTokens.spaceXS),
                              Text(
                                '$_likesCount',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: _P.textSecondary,
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

  String _formatDateTime(DateTime d) {
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';
    return '${d.day}/${d.month}/${d.year} • $hour:$minute $period';
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _OfferPhotoCarousel extends StatelessWidget {
  final List<String> photos;
  final String offerId;
  final PageController controller;
  final int currentIndex;
  final VoidCallback onInteractionStart;
  final VoidCallback onInteractionEnd;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onTapPhoto;

  const _OfferPhotoCarousel({
    required this.photos,
    required this.offerId,
    required this.controller,
    required this.currentIndex,
    required this.onInteractionStart,
    required this.onInteractionEnd,
    required this.onPageChanged,
    required this.onTapPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Listener(
          onPointerDown: (_) => onInteractionStart(),
          onPointerUp: (_) => onInteractionEnd(),
          onPointerCancel: (_) => onInteractionEnd(),
          child: PageView.builder(
            controller: controller,
            physics: const BouncingScrollPhysics(),
            itemCount: photos.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTapPhoto(index),
              child: Container(
                color: _P.elevated,
                alignment: Alignment.center,
                child: Hero(
                  tag: 'offer_photo_${offerId}_$index',
                  child: CachedNetworkImage(
                    imageUrl: photos[index],
                    fit: BoxFit.contain,
                    placeholder: (_, __) =>
                        const ColoredBox(color: _P.elevated),
                    errorWidget: (_, __, ___) =>
                        const ColoredBox(color: _P.elevated),
                  ),
                ),
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xAA000000), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.center,
              ),
            ),
          ),
        ),
        if (photos.length > 1)
          Positioned(
            top: kToolbarHeight + AppTokens.spaceSM,
            right: AppTokens.spaceLG,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spaceSM,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _P.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                ),
                child: Text(
                  '${currentIndex + 1}/${photos.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _P.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ),
        if (photos.length > 1)
          Positioned(
            left: AppTokens.spaceLG,
            right: AppTokens.spaceLG,
            bottom: AppTokens.spaceLG,
            child: IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  photos.length,
                  (index) => AnimatedContainer(
                    duration: AppTokens.durationFast,
                    width: index == currentIndex ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: index == currentIndex
                          ? _P.white
                          : _P.white.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(
                        AppTokens.radiusFull,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
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
      color: _P.surface,
      padding: const EdgeInsets.fromLTRB(
        AppTokens.spaceLG,
        AppTokens.space2XL,
        AppTokens.spaceLG,
        AppTokens.spaceMD,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            discountText,
            style: theme.textTheme.displayLarge?.copyWith(
              color: _P.accent,
              height: 1,
            ),
          ),
          const SizedBox(height: AppTokens.spaceSM),
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: _P.textPrimary,
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: _P.textPrimary,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.spaceMD),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMD),
        border: Border.all(color: _P.border),
        boxShadow: [
          BoxShadow(
            color: _P.textPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? foreground;
  final Color? background;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.foreground,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? _P.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceSM,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: background ?? _P.elevated,
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        border: Border.all(color: _P.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _PhotoThumbnailTile extends StatefulWidget {
  final String imageUrl;
  final double height;
  final BoxFit fit;
  final bool isSelected;

  const _PhotoThumbnailTile({
    required this.imageUrl,
    this.height = 76,
    this.fit = BoxFit.cover,
    this.isSelected = false,
  });

  @override
  State<_PhotoThumbnailTile> createState() => _PhotoThumbnailTileState();
}

class _PhotoThumbnailTileState extends State<_PhotoThumbnailTile> {
  static const double _minAspectRatio = 0.45;
  static const double _maxAspectRatio = 2.4;
  double _aspectRatio = 1;
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant _PhotoThumbnailTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _removeImageListener();
      _aspectRatio = 1;
      _resolveImage();
    }
  }

  @override
  void dispose() {
    _removeImageListener();
    super.dispose();
  }

  void _resolveImage() {
    final provider = CachedNetworkImageProvider(widget.imageUrl);
    final stream = provider.resolve(const ImageConfiguration());
    _imageStream = stream;
    _imageStreamListener = ImageStreamListener((info, _) {
      final image = info.image;
      if (!mounted || image.height == 0) return;
      final ratio = image.width / image.height;
      final normalizedRatio =
          ratio.clamp(_minAspectRatio, _maxAspectRatio).toDouble();
      if ((_aspectRatio - normalizedRatio).abs() > 0.005) {
        setState(() {
          _aspectRatio = normalizedRatio;
        });
      }
    });
    stream.addListener(_imageStreamListener!);
  }

  void _removeImageListener() {
    if (_imageStream != null && _imageStreamListener != null) {
      _imageStream!.removeListener(_imageStreamListener!);
    }
    _imageStream = null;
    _imageStreamListener = null;
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected ? _P.accent : _P.border;

    return AnimatedContainer(
      duration: AppTokens.durationFast,
      width: widget.height * _aspectRatio,
      height: widget.height,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: _P.elevated,
        borderRadius: BorderRadius.circular(AppTokens.radiusMD),
        border: Border.all(
          color: borderColor,
          width: widget.isSelected ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.radiusSM),
        child: CachedNetworkImage(
          imageUrl: widget.imageUrl,
          fit: widget.fit,
          placeholder: (_, __) => const ColoredBox(color: _P.elevated),
          errorWidget: (_, __, ___) => const ColoredBox(
            color: _P.elevated,
            child: Icon(Icons.broken_image_outlined, color: _P.textMuted),
          ),
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isLast;

  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppTokens.spaceMD),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _P.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: _P.accent),
          ),
          const SizedBox(width: AppTokens.spaceSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _P.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _P.textPrimary,
                  ),
                ),
              ],
            ),
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
            color: _P.textMuted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: _P.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ShopDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int maxLines;

  const _ShopDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _P.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _P.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _P.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
      backgroundColor: _P.black,
      appBar: AppBar(
        backgroundColor: _P.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: _P.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.photos.length}',
          style: const TextStyle(color: _P.white70),
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
                    color: _P.white54,
                    strokeWidth: 2,
                  ),
                ),
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_outlined,
                      size: 64, color: _P.white54),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
