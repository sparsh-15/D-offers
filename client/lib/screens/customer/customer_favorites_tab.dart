import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/offer_model.dart';
import '../../screens/common/offer_detail_screen.dart';
import '../../services/auth_service.dart';
import '../../widgets/shop_logo_widget.dart';

class CustomerFavoritesTab extends StatefulWidget {
  const CustomerFavoritesTab({super.key, this.onBrowseOffers});

  final VoidCallback? onBrowseOffers;

  @override
  State<CustomerFavoritesTab> createState() => _CustomerFavoritesTabState();
}

class _CustomerFavoritesTabState extends State<CustomerFavoritesTab> {
  bool _loading = true;
  String? _errorText;
  List<OfferModel> _favorites = const [];

  static const _cardGradients = <List<Color>>[
    [Color(0xFF2A2150), Color(0xFF421A78), Color(0xFF231B42)],
    [Color(0xFF2F6A67), Color(0xFF71A67D), Color(0xFF243A45)],
    [Color(0xFFFF76C6), Color(0xFFFA5D9E), Color(0xFF7A315C)],
    [Color(0xFF5A4A96), Color(0xFF8F78FF), Color(0xFF2A2457)],
    [Color(0xFF5D3B4C), Color(0xFFE36F93), Color(0xFF6A3554)],
  ];

  static const _warmCanvas = Color(0xFFF3F5F8);
  static const _cardBorder = Color(0xFFDCE3EC);
  static const _footerText = Color(0xFF1E2433);
  static const _mutedText = Color(0xFF667085);

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> reloadFavorites() => _refresh();

  Future<void> _refresh() async {
    await _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _loading = true;
      _errorText = null;
    });
    try {
      final list = await AuthService.instance.getLikedOffers();
      if (!mounted) return;
      setState(() {
        _favorites = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.toString();
        _loading = false;
      });
    }
  }

  void _applyUpdatedOffer(OfferModel updated) {
    setState(() {
      if (!updated.isLiked) {
        _favorites =
            _favorites.where((offer) => offer.id != updated.id).toList();
        return;
      }

      final index = _favorites.indexWhere((offer) => offer.id == updated.id);
      if (index < 0) return;

      final next = [..._favorites];
      next[index] = updated;
      _favorites = next;
    });
  }

  List<Color> _gradientForIndex(int index) =>
      _cardGradients[index % _cardGradients.length];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 16,
        title: Text(
          'Your Picks',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF1E2433),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
      backgroundColor: _warmCanvas,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFFE88428),
        backgroundColor: Colors.white,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 6)),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFE88428),
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (_errorText != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFE24D69),
                          size: 42,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Could not load your picks',
                          style: GoogleFonts.dmSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _footerText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _errorText!,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: _mutedText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        TextButton(
                          onPressed: _refresh,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_favorites.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.bookmark_border_rounded,
                          color: Color(0xFF9E92A6),
                          size: 50,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Nothing saved yet.',
                          style: GoogleFonts.dmSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _footerText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Like an offer to save it here.',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: _mutedText,
                          ),
                        ),
                        if (widget.onBrowseOffers != null) ...[
                          const SizedBox(height: 14),
                          OutlinedButton(
                            onPressed: widget.onBrowseOffers,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(160, 48),
                              foregroundColor: const Color(0xFF1E1B24),
                              side: const BorderSide(color: _cardBorder),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Browse deals'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _PickDealCard(
                        offer: _favorites[index],
                        gradientColors: _gradientForIndex(index),
                        onOfferUpdated: _applyUpdatedOffer,
                      ),
                    ),
                    childCount: _favorites.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 36)),
          ],
        ),
      ),
    );
  }
}

class _PickDealCard extends StatelessWidget {
  const _PickDealCard({
    required this.offer,
    required this.gradientColors,
    required this.onOfferUpdated,
  });

  final OfferModel offer;
  final List<Color> gradientColors;
  final ValueChanged<OfferModel> onOfferUpdated;

  static const _footerText = Color(0xFF1E1B24);
  static const _softCard = Color(0xFFF7FAFD);
  static const _cardBorder = Color(0xFFDCE3EC);
  static const _chipGreenBg = Color(0xFFE4F6EC);
  static const _chipGreenFg = Color(0xFF1C9961);
  static const _chipSandBg = Color(0xFFEFF4FA);
  static const _chipSandFg = Color(0xFF5A6B80);
  static const _chipRoseBg = Color(0xFFFCE7ED);
  static const _chipRoseFg = Color(0xFFE24D69);

  String _titleCase(String input) {
    final text = input.trim();
    if (text.isEmpty) return '';
    return text
        .split(RegExp(r'[\s_-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) =>
            '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
        .join(' ');
  }

  String _discountText() {
    final dynamic rawDiscount = offer.discountValue;
    final num? discountValue = rawDiscount is num
        ? rawDiscount
        : num.tryParse(rawDiscount?.toString() ?? '');

    if (offer.discountType == 'percentage' && discountValue != null) {
      final decimals = discountValue % 1 == 0 ? 0 : 1;
      return '${discountValue.toStringAsFixed(decimals)}% OFF';
    }

    if (offer.discountType == 'fixed' && discountValue != null) {
      final decimals = discountValue % 1 == 0 ? 0 : 1;
      return '₹${discountValue.toStringAsFixed(decimals)} OFF';
    }

    return 'SPECIAL OFFER';
  }

  String _mainLabel() {
    if (offer.shopName?.trim().isNotEmpty == true) {
      return offer.shopName!.trim().toUpperCase();
    }
    if (offer.title.trim().isNotEmpty) {
      return offer.title.trim().toUpperCase();
    }
    return 'PICK';
  }

  String _categoryLabel() {
    if (offer.category.trim().isNotEmpty) {
      return _titleCase(offer.category);
    }
    if (offer.shopRankingTier.trim().isNotEmpty &&
        offer.shopRankingTier != 'normal') {
      return _titleCase(offer.shopRankingTier);
    }
    return 'Retail';
  }

  String _statusLabel() {
    if (offer.status.trim().isNotEmpty) {
      return _titleCase(offer.status);
    }
    return 'Active';
  }

  String _subtitleText() {
    if (offer.description.trim().isNotEmpty) {
      return offer.description.trim();
    }
    return 'Tap for details';
  }

  IconData _visualIcon() {
    final text =
        '${offer.category} ${offer.title} ${offer.shopName}'.toLowerCase();
    if (text.contains('restaurant') ||
        text.contains('food') ||
        text.contains('cafe')) {
      return Icons.coffee_rounded;
    }
    if (text.contains('fashion') ||
        text.contains('cloth') ||
        text.contains('wear')) {
      return Icons.checkroom_rounded;
    }
    if (text.contains('beauty') ||
        text.contains('spa') ||
        text.contains('salon')) {
      return Icons.spa_rounded;
    }
    if (text.contains('jewel') ||
        text.contains('ring') ||
        text.contains('gold')) {
      return Icons.diamond_rounded;
    }
    return Icons.local_mall_rounded;
  }

  void _openDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OfferDetailScreen(
          offer: offer,
          onOfferUpdated: onOfferUpdated,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = offer.photos.isNotEmpty;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => _openDetails(context),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _cardBorder),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E1B24).withValues(alpha: 0.08),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 290,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: gradientColors,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: 14,
                                top: 14,
                                child: _TopBadge(label: _mainLabel()),
                              ),
                              Positioned.fill(
                                child: Center(
                                  child: hasPhoto
                                      ? Container(
                                          width: 152,
                                          height: 152,
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.14),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.12),
                                                blurRadius: 20,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: ClipOval(
                                            child: CachedNetworkImage(
                                              imageUrl: offer.photos.first,
                                              fit: BoxFit.contain,
                                              placeholder: (_, __) =>
                                                  const Center(
                                                child: SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              errorWidget: (_, __, ___) => Icon(
                                                _visualIcon(),
                                                size: 66,
                                                color: Colors.white
                                                    .withValues(alpha: 0.92),
                                              ),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          width: 124,
                                          height: 124,
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.16),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white
                                                  .withValues(alpha: 0.2),
                                              width: 1,
                                            ),
                                          ),
                                          child: Icon(
                                            _visualIcon(),
                                            size: 58,
                                            color: Colors.white
                                                .withValues(alpha: 0.94),
                                          ),
                                        ),
                                ),
                              ),
                              Positioned(
                                left: 16,
                                bottom: 54,
                                child: Text(
                                  _discountText(),
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 0.9,
                                    letterSpacing: -0.6,
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 16,
                                bottom: 34,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 15,
                                      color:
                                          Colors.white.withValues(alpha: 0.84),
                                    ),
                                    const SizedBox(width: 4),
                                    SizedBox(
                                      width: 220,
                                      child: Text(
                                        _subtitleText(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white
                                              .withValues(alpha: 0.82),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  height: 30,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF242235),
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(28),
                                      bottomRight: Radius.circular(28),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.place_outlined,
                                        size: 14,
                                        color: Colors.white
                                            .withValues(alpha: 0.72),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          _categoryLabel(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white
                                                .withValues(alpha: 0.78),
                                          ),
                                        ),
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
                  ),
                ),
                Container(
                  color: _softCard,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ShopLogoWidget(
                            logoUrl: offer.shopLogoUrl,
                            radius: 17,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              offer.shopName?.trim().isNotEmpty == true
                                  ? offer.shopName!.trim()
                                  : 'Saved Deal',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _footerText,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.favorite_rounded,
                                color: Color(0xFFE54C6C),
                                size: 18,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${offer.likesCount}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _footerText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _Pill(
                            label: _discountText().replaceAll(' OFF', ''),
                            backgroundColor: _chipGreenBg,
                            foregroundColor: _chipGreenFg,
                          ),
                          _Pill(
                            label: _categoryLabel(),
                            backgroundColor: _chipSandBg,
                            foregroundColor: _chipSandFg,
                          ),
                          _Pill(
                            label: _statusLabel(),
                            backgroundColor: _chipRoseBg,
                            foregroundColor: _chipRoseFg,
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
      ),
    );
  }
}

class _TopBadge extends StatelessWidget {
  const _TopBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE88428),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: foregroundColor,
        ),
      ),
    );
  }
}
