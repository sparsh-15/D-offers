import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_design_tokens.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';
import '../../services/location_service.dart';
import '../../models/offer_model.dart';
import '../../widgets/offer_card.dart';
import '../../core/utils/dialog_helper.dart';
import '../../services/subscription_service.dart';
import 'dart:async';

class CustomerHomeTab extends StatefulWidget {
  const CustomerHomeTab({super.key, this.onViewAllOffers});

  final VoidCallback? onViewAllOffers;

  @override
  State<CustomerHomeTab> createState() => _CustomerHomeTabState();
}

class _CustomerHomeTabState extends State<CustomerHomeTab> {
  bool _isLoadingDeals = true;
  String? _dealsError;
  List<OfferModel> _featuredDeals = const [];
  List<OfferModel> _allPreviewDeals = const [];
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';
  bool _useCurrentLocation = false;
  bool _isLoadingLocation = false;
  String? _currentLocationText;
  String? _currentPincode;
  String? _currentCity;
  String? _currentState;
  String? _selectedCategory;
   String _sortBy = 'newest';
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadDeals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    await _loadDeals();
  }

  Future<void> _loadDeals() async {
    setState(() {
      _isLoadingDeals = true;
      _dealsError = null;
    });
    try {
      final deals = await _fetchDeals();
      if (!mounted) return;
      setState(() {
        _featuredDeals = deals.featured;
        _allPreviewDeals = deals.allPreview;
        _isLoadingDeals = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dealsError = e.toString();
        _isLoadingDeals = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    try {
      final list = await SubscriptionService.instance.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = list;
      });
    } catch (_) {
      // Ignore failures; category chips are optional.
    }
  }

  Future<_HomeDeals> _fetchDeals() async {
    String? pincode;
    String? city;
    String? state;

    if (_useCurrentLocation && _currentPincode != null) {
      pincode = _currentPincode;
      city = _currentCity;
      state = _currentState;
    } else {
      final user = AuthStore.currentUser;
      if (user != null) {
        final p = user.pincode.trim();
        final c = user.city.trim();
        final s = user.state.trim();
        pincode = p.isEmpty ? null : p;
        city = c.isEmpty ? null : c;
        state = s.isEmpty ? null : s;
      }
    }

    final q = _searchQuery.trim().isEmpty ? null : _searchQuery.trim();
    final category = _selectedCategory?.trim();

    final results = await Future.wait([
      AuthService.instance.getCustomerOffers(
        pincode: pincode,
        city: city,
        state: state,
        q: q,
        category: category,
        segment: 'featured',
        limit: 8,
      ),
      AuthService.instance.getCustomerOffers(
        pincode: pincode,
        city: city,
        state: state,
        q: q,
        category: category,
        sort: _sortBy,
        limit: 20,
      ),
    ]);

    return _HomeDeals(
      featured: results[0],
      allPreview: results[1],
    );
  }

  Future<void> _getCurrentLocation() async {
    // Avoid IME open/close jank while toggling location from app bar.
    FocusScope.of(context).unfocus();
    setState(() => _isLoadingLocation = true);
    try {
      final locationData =
          await LocationService.instance.getCurrentLocationWithAddress();
      if (!mounted) return;
      final pincode = (locationData['pincode'] as String?)?.trim();
      final city = (locationData['city'] as String?)?.trim();
      final state = (locationData['state'] as String?)?.trim();
      if (pincode == null || pincode.isEmpty) {
        setState(() {
          _isLoadingLocation = false;
          _useCurrentLocation = false;
        });
        DialogHelper.showErrorSnackBar(
          context,
          'Could not detect pincode from current location.',
        );
        return;
      }
      setState(() {
        _currentPincode = pincode;
        _currentCity = city;
        _currentState = state;
        _currentLocationText = [
          if (_currentCity?.isNotEmpty == true) _currentCity,
          if (_currentPincode?.isNotEmpty == true) _currentPincode,
          if (_currentState?.isNotEmpty == true) _currentState,
        ].join(', ');
        _useCurrentLocation = true;
        _isLoadingLocation = false;
      });
      _refresh();
      DialogHelper.showSuccessSnackBar(
        context,
        'Applied pincode filter: $_currentPincode',
      );
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
    FocusScope.of(context).unfocus();
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

    // Compute location summary for hero header
    String locationLine;
    if (_useCurrentLocation && (_currentLocationText ?? '').isNotEmpty) {
      locationLine = _currentLocationText!;
    } else {
      final parts = <String>[];
      final city = (user?.city ?? '').trim();
      final pincode = (user?.pincode ?? '').trim();
      if (city.isNotEmpty) parts.add(city);
      if (pincode.isNotEmpty) parts.add(pincode);
      locationLine =
          parts.isNotEmpty ? parts.join(', ') : 'Set your area for better deals';
    }

    final totalDeals = _featuredDeals.length + _allPreviewDeals.length;
    String dealsLine;
    if (_isLoadingDeals) {
      dealsLine = 'Finding the best deals near you...';
    } else if (totalDeals <= 0) {
      dealsLine = 'No deals near you yet – try another category or area.';
    } else {
      dealsLine = '$totalDeals deals near you';
    }

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
            // ── App bar (compact) ────────────────────────────────────────────
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
                    style: theme.textTheme.titleLarge,
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
                  // ── Hero summary under app bar ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.spaceMD,
                      AppTokens.spaceSM,
                      AppTokens.spaceMD,
                      0,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppTokens.spaceSM),
                      decoration: BoxDecoration(
                        color: AppColors.elevated,
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusLG),
                        border: Border.all(
                          color: AppColors.borderSubtle,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.place_rounded,
                            size: AppTokens.iconMD,
                            color: AppColors.accentDim,
                          ),
                          const SizedBox(width: AppTokens.spaceSM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  locationLine,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dealsLine,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

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
                                onTap: () {
                                  _searchDebounce?.cancel();
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                  _refresh();
                                },
                                child: const Icon(Icons.close_rounded,
                                    color: AppColors.textMuted,
                                    size: AppTokens.iconMD),
                              )
                            : null,
                      ),
                      onChanged: (v) {
                        setState(() => _searchQuery = v);
                        _searchDebounce?.cancel();
                        _searchDebounce = Timer(
                          const Duration(milliseconds: 350),
                          _refresh,
                        );
                      },
                    ),
                  ),

                  // ── Category chips ─────────────────────────────────────────
                  const SizedBox(height: AppTokens.spaceMD),
                  if (_categories.isNotEmpty)
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.spaceMD,
                        ),
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length + 1,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: AppTokens.spaceSM),
                        itemBuilder: (ctx, i) {
                          if (i == 0) {
                            final bool isSelected = _selectedCategory == null;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategory = null;
                                });
                                _refresh();
                              },
                              child: AnimatedContainer(
                                duration: AppTokens.durationFast,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTokens.spaceMD,
                                  vertical: AppTokens.spaceXS,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.accentDim
                                          .withValues(alpha: 0.25)
                                      : AppColors.elevated,
                                  borderRadius: BorderRadius.circular(
                                      AppTokens.radiusFull),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.accentDim
                                        : AppColors.borderSubtle,
                                  ),
                                ),
                                child: Text(
                                  'All',
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
                          }

                          final cat = _categories[i - 1];
                          final value = cat['value']?.toString() ?? '';
                          final label = cat['label']?.toString() ?? value;
                          final isSelected = _selectedCategory == value;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory =
                                    isSelected ? null : value;
                              });
                              _refresh();
                            },
                            child: AnimatedContainer(
                              duration: AppTokens.durationFast,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTokens.spaceMD,
                                vertical: AppTokens.spaceXS,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.accentDim
                                        .withValues(alpha: 0.25)
                                    : AppColors.elevated,
                                borderRadius:
                                    BorderRadius.circular(AppTokens.radiusFull),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.accentDim
                                      : AppColors.borderSubtle,
                                ),
                              ),
                              child: Text(
                                label,
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
                  Builder(
                    builder: (ctx) {
                      if (_isLoadingDeals) {
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

                      if (_dealsError != null) {
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
                              const SizedBox(height: AppTokens.spaceXS),
                              Text(
                                _dealsError!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                                textAlign: TextAlign.center,
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

                      final featured = _featuredDeals;
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
                        height: MediaQuery.of(context).size.width * 0.78,
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
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: SizedBox(
                                    width: cardWidth,
                                    child: OfferCard(
                                      offer: featured[i],
                                      onOfferUpdated: (updated) {
                                        final idx = _featuredDeals.indexWhere(
                                            (x) => x.id == updated.id);
                                        if (idx < 0) return;
                                        setState(() {
                                          final next = [..._featuredDeals];
                                          next[idx] = updated;
                                          _featuredDeals = next;
                                        });
                                      },
                                    ),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _sortBy == 'most_liked'
                                    ? 'Trending deals near you'
                                    : 'All deals near you',
                                style: theme.textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Based on your location and category filters',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppTokens.spaceMD),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color:
                                AppColors.elevated.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(
                              AppTokens.radiusFull,
                            ),
                            border: Border.all(
                              color: AppColors.borderSubtle,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _SortPill(
                                label: 'Newest',
                                isSelected: _sortBy == 'newest',
                                onTap: () {
                                  if (_sortBy == 'newest') return;
                                  setState(() => _sortBy = 'newest');
                                  _refresh();
                                },
                              ),
                              _SortPill(
                                label: 'Trending',
                                isSelected: _sortBy == 'most_liked',
                                onTap: () {
                                  if (_sortBy == 'most_liked') return;
                                  setState(() => _sortBy = 'most_liked');
                                  _refresh();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceMD),

                  Builder(
                    builder: (ctx) {
                      if (_isLoadingDeals) {
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

                      final preview = _allPreviewDeals;
                      if (preview.isEmpty) {
                        return _EmptyState(
                          message:
                              'No more deals match your filters here.\nTry changing category or pincode, or browse all offers.',
                          onBrowseAll: widget.onViewAllOffers,
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.spaceMD,
                        ),
                        itemCount: preview.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppTokens.spaceSM),
                        itemBuilder: (ctx2, i) => OfferCard(
                          offer: preview[i],
                          onOfferUpdated: (updated) {
                            final idx = _allPreviewDeals
                                .indexWhere((x) => x.id == updated.id);
                            if (idx < 0) return;
                            setState(() {
                              final next = [..._allPreviewDeals];
                              next[idx] = updated;
                              _allPreviewDeals = next;
                            });
                          },
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

class _HomeDeals {
  final List<OfferModel> featured;
  final List<OfferModel> allPreview;

  const _HomeDeals({
    required this.featured,
    required this.allPreview,
  });
}

class _SortPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTokens.durationFast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceSM,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentDim.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isSelected ? AppColors.accent : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
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
          const SizedBox(height: AppTokens.spaceSM),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (onBrowseAll != null) ...[
            const SizedBox(height: AppTokens.spaceMD),
            TextButton.icon(
              onPressed: onBrowseAll,
              icon: const Icon(
                Icons.local_offer_outlined,
                color: AppColors.accentDim,
              ),
              label: const Text('Browse all offers'),
            ),
          ],
        ],
      ),
    );
  }
}
