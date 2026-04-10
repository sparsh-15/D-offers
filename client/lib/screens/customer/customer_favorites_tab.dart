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

  static const _canvas  = Color(0xFFF3F5F8);
  static const _accent  = Color(0xFFE88428);
  static const _border  = Color(0xFFDCE3EC);
  static const _text    = Color(0xFF1E2433);
  static const _muted   = Color(0xFF667085);
  static const _error   = Color(0xFFE24D69);

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> reloadFavorites() => _refresh();
  Future<void> _refresh() async => _loadFavorites();

  Future<void> _loadFavorites() async {
    setState(() { _loading = true; _errorText = null; });
    try {
      final list = await AuthService.instance.getLikedOffers();
      if (!mounted) return;
      setState(() { _favorites = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _errorText = e.toString(); _loading = false; });
    }
  }

  void _applyUpdatedOffer(OfferModel updated) {
    setState(() {
      if (!updated.isLiked) {
        _favorites = _favorites.where((o) => o.id != updated.id).toList();
        return;
      }
      final idx = _favorites.indexWhere((o) => o.id == updated.id);
      if (idx < 0) return;
      final next = [..._favorites];
      next[idx] = updated;
      _favorites = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        backgroundColor: _canvas,
        surfaceTintColor: _canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 16,
        title: Text(
          'Your Picks',
          style: GoogleFonts.dmSans(
            color: _text, fontSize: 22, fontWeight: FontWeight.w800),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: _accent,
        backgroundColor: Colors.white,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 4)),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFFE88428), strokeWidth: 2),
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
                        const Icon(Icons.error_outline_rounded,
                            color: _error, size: 42),
                        const SizedBox(height: 14),
                        Text('Could not load your picks',
                            style: GoogleFonts.dmSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _text)),
                        const SizedBox(height: 6),
                        Text(_errorText!,
                            style: GoogleFonts.dmSans(
                                fontSize: 13, color: _muted),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 14),
                        TextButton(
                          onPressed: _refresh,
                          style: TextButton.styleFrom(
                              foregroundColor: _accent),
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
                        const Icon(Icons.bookmark_border_rounded,
                            color: Color(0xFF9E92A6), size: 50),
                        const SizedBox(height: 14),
                        Text('Nothing saved yet.',
                            style: GoogleFonts.dmSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _text)),
                        const SizedBox(height: 6),
                        Text('Like an offer to save it here.',
                            style: GoogleFonts.dmSans(
                                fontSize: 13, color: _muted)),
                        if (widget.onBrowseOffers != null) ...[
                          const SizedBox(height: 14),
                          OutlinedButton(
                            onPressed: widget.onBrowseOffers,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(160, 48),
                              foregroundColor: _text,
                              side: const BorderSide(color: _border),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
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
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PickCard(
                        offer: _favorites[index],
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

// ── Card ──────────────────────────────────────────────────────────────────────

class _PickCard extends StatelessWidget {
  const _PickCard({required this.offer, required this.onOfferUpdated});

  final OfferModel offer;
  final ValueChanged<OfferModel> onOfferUpdated;

  static const _surface  = Color(0xFFFFFFFF);
  static const _border   = Color(0xFFDCE3EC);
  static const _elevated = Color(0xFFF4F7FB);
  static const _accent   = Color(0xFFE88428);
  static const _text     = Color(0xFF1E2433);
  static const _muted    = Color(0xFF667085);
  static const _error    = Color(0xFFE24D69);

  String _discountLabel() {
    final dynamic raw = offer.discountValue;
    final num? val = raw is num ? raw : num.tryParse(raw?.toString() ?? '');
    if (offer.discountType == 'percentage' && val != null) {
      return '${val.toStringAsFixed(val % 1 == 0 ? 0 : 1)}%';
    }
    if (offer.discountType == 'fixed' && val != null) {
      return '${val.toStringAsFixed(val % 1 == 0 ? 0 : 1)}';
    }
    return 'Offer';
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = offer.photos.isNotEmpty;
    final shopName = offer.shopName?.trim().isNotEmpty == true
        ? offer.shopName!.trim()
        : 'Saved Deal';
    final isExpired = offer.status == 'expired';

    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OfferDetailScreen(
              offer: offer,
              onOfferUpdated: onOfferUpdated,
            ),
          ),
        ),
        splashColor: _accent.withValues(alpha: 0.08),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Photo
                hasPhoto
                    ? CachedNetworkImage(
                        imageUrl: offer.photos.first,
                        fit: BoxFit.fitWidth,
                        width: double.infinity,
                        placeholder: (_, __) => Container(
                          height: 180,
                          color: _elevated,
                          child: const Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _accent),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 180,
                          color: _elevated,
                          child: const Center(
                            child: Icon(Icons.local_offer_rounded,
                                size: 42, color: _muted),
                          ),
                        ),
                      )
                    : Container(
                        height: 180,
                        color: _elevated,
                        child: const Center(
                          child: Icon(Icons.local_offer_rounded,
                              size: 42, color: _muted),
                        ),
                      ),
                // Info strip
                Container(
                  color: _surface,
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ShopLogoWidget(
                              logoUrl: offer.shopLogoUrl, radius: 10),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              shopName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _text,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _discountLabel(),
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _accent,
                            ),
                          ),
                          if (offer.discountType == 'percentage')
                            Text(' OFF',
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _accent)),
                          if (isExpired) ...[
                            const SizedBox(width: 4),
                            Text('EXPIRED',
                                style: GoogleFonts.dmSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: _error)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Border overlay
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _border),
                  ),
                ),
              ),
            ),
            // Likes badge
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: _surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_rounded,
                        size: 11, color: _error),
                    const SizedBox(width: 3),
                    Text(
                      '${offer.likesCount}',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
