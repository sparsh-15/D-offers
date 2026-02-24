import 'dart:async';

import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';
import '../../models/offer_model.dart';
import '../../widgets/offer_card.dart';
import '../../core/utils/theme_helper.dart';

class CustomerHomeTab extends StatefulWidget {
  const CustomerHomeTab({
    super.key,
    this.onViewAllOffers,
  });

  final VoidCallback? onViewAllOffers;

  @override
  State<CustomerHomeTab> createState() => _CustomerHomeTabState();
}

class _CustomerHomeTabState extends State<CustomerHomeTab> {
  late Future<List<OfferModel>> _featuredOffersFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _useCurrentLocation = true;
  Timer? _flashDealTimer;
  Duration _flashDealCountdown =
      const Duration(hours: 2, minutes: 15, seconds: 20);

  static const List<String> _categories = [
    'Grocery',
    'Fashion',
    'Electronics',
    'Food',
    'Pharmacy',
    'Services',
  ];

  @override
  void dispose() {
    _flashDealTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _featuredOffersFuture = _fetchOffers();
    _startFlashCountdown();
  }

  Future<void> _refresh() async {
    setState(() {
      _featuredOffersFuture = _fetchOffers();
    });
  }

  void _goToOffers() {
    widget.onViewAllOffers?.call();
  }

  void _startFlashCountdown() {
    _flashDealTimer?.cancel();
    _flashDealTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_flashDealCountdown.inSeconds <= 0) {
        timer.cancel();
        return;
      }
      setState(() {
        _flashDealCountdown -= const Duration(seconds: 1);
      });
    });
  }

  Future<List<OfferModel>> _fetchOffers() {
    final user = AuthStore.currentUser;
    if (!_useCurrentLocation || user == null) {
      return AuthService.instance.getCustomerOffers();
    }

    final pincode = user.pincode.trim();
    final city = user.city.trim();
    final state = user.state.trim();

    return AuthService.instance.getCustomerOffers(
      pincode: pincode.isEmpty ? null : pincode,
      city: city.isEmpty ? null : city,
      state: state.isEmpty ? null : state,
    );
  }

  List<OfferModel> _searchFiltered(List<OfferModel> offers) {
    if (_searchQuery.trim().isEmpty) return offers;
    final query = _searchQuery.toLowerCase().trim();
    return offers.where((offer) {
      return offer.title.toLowerCase().contains(query) ||
          offer.description.toLowerCase().contains(query) ||
          offer.category.toLowerCase().contains(query) ||
          (offer.shopName?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  String _formatCountdown(Duration duration) {
    final hours = duration.inHours.remainder(100).toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Widget _buildRecommendationCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: ThemeHelper.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashDealCard(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.22),
            AppColors.primary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Limited',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.timer_rounded, size: 18),
                const SizedBox(width: 6),
                Text(
                  _formatCountdown(_flashDealCountdown),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateRow(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedEmptyState(BuildContext context, String locationLabel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ThemeHelper.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'We are scanning stores near you',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildEmptyStateRow(
            context,
            icon: Icons.place_rounded,
            text: locationLabel.isEmpty
                ? 'Locating top offers in your area'
                : 'Scanning $locationLabel',
          ),
          const SizedBox(height: 6),
          _buildEmptyStateRow(
            context,
            icon: Icons.local_offer_rounded,
            text: '3 stores are preparing new deals',
          ),
          const SizedBox(height: 6),
          _buildEmptyStateRow(
            context,
            icon: Icons.notifications_active_rounded,
            text: 'Enable notifications to get first access',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthStore.currentUser;
    final name =
        (user != null && user.name.isNotEmpty) ? user.name : 'Customer';
    final locationLabel = [
      if ((user?.city ?? '').trim().isNotEmpty) user!.city.trim(),
      if ((user?.state ?? '').trim().isNotEmpty) user!.state.trim(),
      if ((user?.pincode ?? '').trim().isNotEmpty) user!.pincode.trim(),
    ].join(' • ');

    return Container(
      decoration: BoxDecoration(
        gradient: ThemeHelper.getBackgroundGradient(context),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: AppColors.transparent,
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $name!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      AppStrings.exploreOffers,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_rounded),
                    onPressed: () {},
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInDown(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: ThemeHelper.getSurfaceColor(context),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: AppStrings.search,
                              border: InputBorder.none,
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.tune_rounded),
                                      onPressed: _goToOffers,
                                    ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            onSubmitted: (_) => _goToOffers(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FadeInDown(
                        delay: const Duration(milliseconds: 30),
                        child: SizedBox(
                          height: 44,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length + 1,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              if (index < _categories.length) {
                                final label = _categories[index];
                                return ActionChip(
                                  label: Text(label),
                                  onPressed: _goToOffers,
                                );
                              }
                              return FilterChip(
                                selected: _useCurrentLocation,
                                onSelected: (selected) {
                                  setState(() {
                                    _useCurrentLocation = selected;
                                  });
                                  _refresh();
                                },
                                avatar: const Icon(Icons.my_location_rounded,
                                    size: 18),
                                label: Text(
                                  locationLabel.isEmpty
                                      ? 'Near me'
                                      : 'Near me: $locationLabel',
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FadeInLeft(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recommended For You',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            TextButton(
                              onPressed: _goToOffers,
                              child: const Text('See All'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 150,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildRecommendationCard(
                              context,
                              title: 'Popular in your area',
                              subtitle: 'High demand offers this week',
                              icon: Icons.trending_up_rounded,
                            ),
                            _buildRecommendationCard(
                              context,
                              title: 'Best for students',
                              subtitle: 'Budget-friendly picks near you',
                              icon: Icons.school_rounded,
                            ),
                            _buildRecommendationCard(
                              context,
                              title: 'High rated nearby',
                              subtitle: 'Top reviewed shops',
                              icon: Icons.star_rounded,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      FadeInLeft(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Limited Time Deals',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formatCountdown(_flashDealCountdown),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 170,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildFlashDealCard(
                              context,
                              title: 'Weekend Mega Discount',
                              subtitle: 'Save up to 50%',
                            ),
                            _buildFlashDealCard(
                              context,
                              title: 'New Arrivals Drop',
                              subtitle: 'Limited inventory',
                            ),
                            _buildFlashDealCard(
                              context,
                              title: 'Lunch Hour Specials',
                              subtitle: 'Today only',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      FadeInLeft(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Featured Offers',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            TextButton.icon(
                              onPressed: _goToOffers,
                              icon: const Icon(Icons.arrow_forward_rounded,
                                  size: 18),
                              label: const Text('View All'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<List<OfferModel>>(
                        future: _featuredOffersFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return SizedBox(
                              height: 200,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    size: 48,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Failed to load offers',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: _refresh,
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Retry'),
                                  ),
                                ],
                              ),
                            );
                          }

                          final offers = snapshot.data ?? [];
                          final searchedOffers = _searchFiltered(offers);
                          final featuredOffers =
                              searchedOffers.take(6).toList();

                          if (featuredOffers.isEmpty) {
                            if (_searchQuery.isNotEmpty) {
                              return Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.search_off_rounded,
                                      size: 64,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No offers match your search',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Try a different keyword',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              );
                            }
                            return _buildFeaturedEmptyState(
                              context,
                              locationLabel,
                            );
                          }

                          return Column(
                            children: [
                              SizedBox(
                                height: 240,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: featuredOffers.length,
                                  itemBuilder: (context, index) {
                                    final offer = featuredOffers[index];
                                    return FadeInRight(
                                      delay:
                                          Duration(milliseconds: 100 * index),
                                      child: Container(
                                        width: 280,
                                        margin: EdgeInsets.only(
                                          right:
                                              index < featuredOffers.length - 1
                                                  ? 12
                                                  : 0,
                                        ),
                                        child: OfferCard(
                                          offer: offer,
                                          onLikeChanged: _refresh,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              if (searchedOffers.length > 6)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Center(
                                    child: OutlinedButton.icon(
                                      onPressed: _goToOffers,
                                      icon: const Icon(
                                          Icons.arrow_forward_rounded),
                                      label: Text(
                                          'View ${searchedOffers.length - 6} more offers'),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      FadeInUp(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ThemeHelper.getSurfaceColor(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.local_offer_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Discover More',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Browse all available offers and find the best deals near you',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward_rounded),
                                onPressed: _goToOffers,
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
      ),
    );
  }
}
