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
  late Future<List<OfferModel>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _favoritesFuture = AuthService.instance.getLikedOffers();
  }

  /// Allow the parent dashboard to force a refresh when this tab is selected.
  Future<void> reloadFavorites() => _refresh();

  Future<void> _refresh() async {
    setState(() {
      _favoritesFuture = AuthService.instance.getLikedOffers();
    });
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
                child: FutureBuilder<List<OfferModel>>(
                  future: _favoritesFuture,
                  builder: (ctx, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'Your Picks',
                          style: theme.textTheme.headlineMedium,
                        ),
                        if (count > 0) ...[
                          const SizedBox(width: AppTokens.spaceSM),
                          Text(
                            '$count',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),

            // ── Content ───────────────────────────────────────────────────────
            FutureBuilder<List<OfferModel>>(
              future: _favoritesFuture,
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentDim,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return SliverFillRemaining(
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
                            const SizedBox(height: AppTokens.spaceMD),
                            TextButton(
                              onPressed: _refresh,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final favorites = snapshot.data ?? [];

                if (favorites.isEmpty) {
                  return SliverFillRemaining(
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
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spaceMD,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx2, i) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppTokens.spaceSM),
                        child: OfferCard(
                          offer: favorites[i],
                          onLikeChanged: _refresh,
                        ),
                      ),
                      childCount: favorites.length,
                    ),
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space3XL)),
          ],
        ),
      ),
    );
  }
}
