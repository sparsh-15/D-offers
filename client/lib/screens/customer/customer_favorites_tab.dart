import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_design_tokens.dart';
import '../../services/auth_service.dart';
import '../../models/offer_model.dart';
import '../../widgets/offer_card.dart';

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

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  /// Allow the parent dashboard to force a refresh when this tab is selected.
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.accent,
        backgroundColor: AppColors.elevated,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ── Header ───────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.spaceMD,
                AppTokens.spaceLG,
                AppTokens.spaceMD,
                AppTokens.spaceMD,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Your Picks',
                      style: theme.textTheme.headlineMedium,
                    ),
                    if (_favorites.isNotEmpty) ...[
                      const SizedBox(width: AppTokens.spaceSM),
                      Text(
                        '${_favorites.length}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Content ───────────────────────────────────────────────────────
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accentDim,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (_errorText != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.spaceLG),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.error, size: 40),
                        const SizedBox(height: AppTokens.spaceMD),
                        Text(
                          'Could not load your picks',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppTokens.spaceXS),
                        Text(
                          _errorText!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTokens.spaceMD),
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
                    padding: const EdgeInsets.all(AppTokens.spaceLG),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.bookmark_border_rounded,
                          color: AppColors.textMuted,
                          size: 48,
                        ),
                        const SizedBox(height: AppTokens.spaceMD),
                        Text(
                          'Nothing saved yet.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppTokens.spaceXS),
                        Text(
                          'Like an offer to save it here.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (widget.onBrowseOffers != null) ...[
                          const SizedBox(height: AppTokens.spaceLG),
                          OutlinedButton(
                            onPressed: widget.onBrowseOffers,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(160, 48),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spaceMD,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx2, i) => Padding(
                      padding: const EdgeInsets.only(bottom: AppTokens.spaceSM),
                      child: OfferCard(
                        offer: _favorites[i],
                        onOfferUpdated: (updated) {
                          setState(() {
                            if (!updated.isLiked) {
                              _favorites = _favorites
                                  .where((o) => o.id != updated.id)
                                  .toList();
                              return;
                            }
                            final idx = _favorites
                                .indexWhere((x) => x.id == updated.id);
                            if (idx < 0) return;
                            final next = [..._favorites];
                            next[idx] = updated;
                            _favorites = next;
                          });
                        },
                      ),
                    ),
                    childCount: _favorites.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space3XL)),
          ],
        ),
      ),
    );
  }
}
