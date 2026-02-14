import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../models/offer_model.dart';
import '../../widgets/offer_card.dart';

class CustomerFavoritesTab extends StatefulWidget {
  const CustomerFavoritesTab({
    super.key,
    this.onBrowseOffers,
  });

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

  Future<void> _refresh() async {
    setState(() {
      _favoritesFuture = AuthService.instance.getLikedOffers();
    });
  }

  void _goToOffers() {
    widget.onBrowseOffers?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.backgroundGradient
            : AppColors.lightBackgroundGradient,
      ),
      child: SafeArea(
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'Favorites',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _refresh,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            Expanded(
              child: FutureBuilder<List<OfferModel>>(
                future: _favoritesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          height: 120,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surface : AppColors.lightSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 64,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load favorites',
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _refresh,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final favorites = snapshot.data ?? [];

                  if (favorites.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite_border_rounded,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No favorites yet',
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Like offers to save them here for easy access',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            OutlinedButton.icon(
                              onPressed: _goToOffers,
                              icon: const Icon(Icons.local_offer_rounded),
                              label: const Text('Browse Offers'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        final offer = favorites[index];
                        return FadeInUp(
                          delay: Duration(milliseconds: 50 * index),
                          child: OfferCard(
                            offer: offer,
                            onLikeChanged: _refresh,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
