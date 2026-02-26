import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_design_tokens.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';
import '../../services/location_service.dart';
import '../../models/offer_model.dart';
import '../../widgets/offer_card.dart';
import '../../core/utils/dialog_helper.dart';

class CustomerHomeTab extends StatefulWidget {
  const CustomerHomeTab({super.key, this.onViewAllOffers});

  final VoidCallback? onViewAllOffers;

  @override
  State<CustomerHomeTab> createState() => _CustomerHomeTabState();
}

class _CustomerHomeTabState extends State<CustomerHomeTab> {
  late Future<List<OfferModel>> _offersFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _useCurrentLocation = false;
  bool _isLoadingLocation = false;
  String? _currentLocationText;
  String? _currentPincode;
  String? _currentCity;
  String? _currentState;
  String? _selectedCategory;

  static const List<String> _categories = [
    'Grocery', 'Fashion', 'Electronics', 'Food', 'Pharmacy', 'Services',
  ];

  @override
  void initState() {
    super.initState();
    _offersFuture = _fetchOffers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _offersFuture = _fetchOffers());
  }

  Future<List<OfferModel>> _fetchOffers() async {
    if (_useCurrentLocation && _currentPincode != null) {
      final offers = await AuthService.instance.getCustomerOffers(
        pincode: _currentPincode,
        city: _currentCity,
        state: _currentState,
      );
      if (offers.isNotEmpty) return offers;
      return AuthService.instance.getCustomerOffers();
    }

    final user = AuthStore.currentUser;
    if (user != null) {
      final pincode = user.pincode.trim();
      final city = user.city.trim();
      final state = user.state.trim();
      if (pincode.isNotEmpty || city.isNotEmpty || state.isNotEmpty) {
        final offers = await AuthService.instance.getCustomerOffers(
          pincode: pincode.isEmpty ? null : pincode,
          city: city.isEmpty ? null : city,
          state: state.isEmpty ? null : state,
        );
        if (offers.isNotEmpty) return offers;
      }
    }

    return AuthService.instance.getCustomerOffers();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final locationData =
          await LocationService.instance.getCurrentLocationWithAddress();
      if (!mounted) return;
      setState(() {
        _currentPincode = locationData['pincode'] as String?;
        _currentCity = locationData['city'] as String?;
        _currentState = locationData['state'] as String?;
        _currentLocationText = [
          if (_currentCity?.isNotEmpty == true) _currentCity,
          if (_currentPincode?.isNotEmpty == true) _currentPincode,
        ].join(', ');
        _useCurrentLocation = true;
        _isLoadingLocation = false;
      });
      _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingLocation = false;
        _useCurrentLocation = false;
      });
      String msg = 'Could not detect location';
      if (e.toString().contains('denied')) {
        msg = 'Location permission denied.';
      } else if (e.toString().contains('disabled')) {
        msg = 'Location services are disabled.';
      }
      DialogHelper.showErrorSnackBar(context, msg);
    }
  }

  void _toggleLocation() {
    if (_useCurrentLocation) {
      setState(() {
        _useCurrentLocation = false;
        _currentLocationText = null;
        _currentPincode = null;
        _currentCity = null;
        _currentState = null;
      });
      _refresh();
    } else {
      _getCurrentLocation();
    }
  }

  List<OfferModel> _filter(List<OfferModel> offers) {
    var result = offers;
    if (_selectedCategory != null) {
      result = result
          .where((o) =>
              o.category.toLowerCase() ==
              _selectedCategory!.toLowerCase())
          .toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((o) =>
              o.title.toLowerCase().contains(q) ||
              o.description.toLowerCase().contains(q) ||
              o.category.toLowerCase().contains(q) ||
              (o.shopName?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    return result;
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthStore.currentUser;
    final firstName = (user?.name ?? '').trim().split(' ').first;
    final displayName = firstName.isEmpty ? 'there' : firstName;

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
            // ── App bar ──────────────────────────────────────────────────────
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: AppColors.background,
              surfaceTintColor: AppColors.transparent,
              titleSpacing: AppTokens.spaceMD,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_greeting()}, $displayName',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Explore deals',
                    style: theme.textTheme.headlineMedium,
                  ),
                ],
              ),
              actions: [
                GestureDetector(
                  onTap: _toggleLocation,
                  child: Container(
                    margin: const EdgeInsets.only(right: AppTokens.spaceMD),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.spaceSM + 2,
                      vertical: AppTokens.spaceXS + 2,
                    ),
                    decoration: BoxDecoration(
                      color: _useCurrentLocation
                          ? AppColors.accentDim.withValues(alpha: 0.25)
                          : AppColors.elevated,
                      borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                      border: Border.all(
                        color: _useCurrentLocation
                            ? AppColors.accentDim
                            : AppColors.borderSubtle,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isLoadingLocation)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.accent,
                            ),
                          )
                        else
                          Icon(
                            _useCurrentLocation
                                ? Icons.location_on_rounded
                                : Icons.location_off_outlined,
                            size: 14,
                            color: _useCurrentLocation
                                ? AppColors.accent
                                : AppColors.textMuted,
                          ),
                        if (_useCurrentLocation &&
                            _currentLocationText != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            _currentLocationText!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Search bar ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.spaceMD, AppTokens.spaceSM,
                      AppTokens.spaceMD, 0,
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: AppTokens.iconMD,
                          color: AppColors.textMuted,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () => setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                }),
                                child: const Icon(Icons.close_rounded,
                                    color: AppColors.textMuted,
                                    size: AppTokens.iconMD),
                              )
                            : null,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),

                  // ── Category chips ─────────────────────────────────────────
                  const SizedBox(height: AppTokens.spaceMD),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.spaceMD,
                      ),
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppTokens.spaceSM),
                      itemBuilder: (ctx, i) {
                        final cat = _categories[i];
                        final isSelected = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedCategory = isSelected ? null : cat;
                          }),
                          child: AnimatedContainer(
                            duration: AppTokens.durationFast,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTokens.spaceMD,
                              vertical: AppTokens.spaceXS,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accentDim.withValues(alpha: 0.25)
                                  : AppColors.elevated,
                              borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accentDim
                                    : AppColors.borderSubtle,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isSelected
                                    ? AppColors.accent
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: AppTokens.spaceLG),

                  // ── Featured header ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.spaceMD,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Featured',
                          style: theme.textTheme.headlineMedium,
                        ),
                        GestureDetector(
                          onTap: widget.onViewAllOffers,
                          child: Text(
                            'See all',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.accentDim,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTokens.spaceMD),

                  // ── Offer carousel ─────────────────────────────────────────
                  FutureBuilder<List<OfferModel>>(
                    future: _offersFuture,
                    builder: (ctx, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 240,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accentDim,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(AppTokens.spaceLG),
                          child: Column(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: AppColors.error, size: 40),
                              const SizedBox(height: AppTokens.spaceSM),
                              Text(
                                'Could not load deals',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppTokens.spaceSM),
                              TextButton(
                                onPressed: _refresh,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      final all = snapshot.data ?? [];
                      final filtered = _filter(all);
                      final featured = filtered.take(8).toList();

                      if (featured.isEmpty) {
                        return _EmptyState(
                          message: _searchQuery.isNotEmpty
                              ? 'No deals match your search'
                              : 'No deals in your area yet.',
                          onBrowseAll: widget.onViewAllOffers,
                        );
                      }

                      final cardWidth =
                          MediaQuery.of(context).size.width * 0.82;

                      return SizedBox(
                        height: 240,
                        child: PageView.builder(
                          controller: PageController(
                            viewportFraction: 0.84,
                          ),
                          physics: const BouncingScrollPhysics(),
                          itemCount: featured.length,
                          itemBuilder: (ctx2, i) {
                            return AnimatedOpacity(
                              duration: AppTokens.durationNormal,
                              opacity: 1.0,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: i < featured.length - 1
                                      ? AppTokens.spaceSM
                                      : 0,
                                  left: i == 0 ? AppTokens.spaceSM : 0,
                                ),
                                child: SizedBox(
                                  width: cardWidth,
                                  child: OfferCard(
                                    offer: featured[i],
                                    onLikeChanged: _refresh,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  // ── All offers section ─────────────────────────────────────
                  const SizedBox(height: AppTokens.spaceLG),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.spaceMD,
                    ),
                    child: Text(
                      'All deals',
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceMD),

                  FutureBuilder<List<OfferModel>>(
                    future: _offersFuture,
                    builder: (ctx, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 120,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accentDim,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      }

                      final all = snapshot.data ?? [];
                      final filtered = _filter(all);

                      if (filtered.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.spaceMD,
                        ),
                        itemCount: filtered.length > 20 ? 20 : filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppTokens.spaceSM),
                        itemBuilder: (ctx2, i) => OfferCard(
                          offer: filtered[i],
                          onLikeChanged: _refresh,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: AppTokens.space3XL),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final VoidCallback? onBrowseAll;

  const _EmptyState({required this.message, this.onBrowseAll});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceLG,
        vertical: AppTokens.spaceLG,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.storefront_outlined,
            color: AppColors.textMuted,
            size: 48,
          ),
          const SizedBox(height: AppTokens.spaceMD),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (onBrowseAll != null) ...[
            const SizedBox(height: AppTokens.spaceMD),
            TextButton(
              onPressed: onBrowseAll,
              child: const Text('Browse all deals'),
            ),
          ],
        ],
      ),
    );
  }
}
