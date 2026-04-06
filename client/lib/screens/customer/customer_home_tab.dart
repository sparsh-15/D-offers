import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_design_tokens.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';
import '../../services/campaign_service.dart';
import '../../services/location_service.dart';
import '../../services/reward_service.dart';
import '../../models/offer_model.dart';
import '../../widgets/offer_card.dart';
import '../../core/utils/dialog_helper.dart';
import '../../services/subscription_service.dart';
import 'dart:async';
import 'customer_inbox_screen.dart';
import '../common/offer_detail_screen.dart';
import '../common/reward_wallet_screen.dart';

class CustomerHomeTab extends StatefulWidget {
  const CustomerHomeTab({super.key, this.onViewAllOffers});

  final VoidCallback? onViewAllOffers;

  @override
  State<CustomerHomeTab> createState() => _CustomerHomeTabState();
}

class _CustomerHomeTabState extends State<CustomerHomeTab> {
  static const _canvasColor = _HomePalette.canvas;
  static const _surfaceColor = _HomePalette.surface;
  static const _borderColor = _HomePalette.border;
  static const _accentColor = _HomePalette.accent;
  static const _accentSoftColor = _HomePalette.accentSoft;
  static const _textPrimaryColor = _HomePalette.textPrimary;
  static const _textSecondaryColor = _HomePalette.textSecondary;
  static const _textMutedColor = _HomePalette.textMuted;
  static const _errorColor = _HomePalette.error;

  bool _isLoadingDeals = true;
  String? _dealsError;
  List<OfferModel> _featuredDeals = const [];
  List<OfferModel> _allPreviewDeals = const [];
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';
  bool _useCurrentLocation = false;
  bool _isLoadingLocation = false;
  bool _loadingInboxCount = false;
  String? _currentLocationText;
  String? _currentPincode;
  String? _currentCity;
  String? _currentState;
  String? _selectedCategory;
  String _sortBy = 'newest';
  List<Map<String, dynamic>> _categories = [];
  int _unreadInboxCount = 0;
  int _walletBalance = 0;
  bool _loadingWallet = false;

  void _onWalletBalanceChanged() {
    final balance = RewardService.instance.latestWalletBalance;
    if (!mounted || balance == null) return;
    if (_walletBalance == balance) return;
    setState(() {
      _walletBalance = balance;
    });
  }

  @override
  void initState() {
    super.initState();
    RewardService.instance.walletBalanceNotifier
        .addListener(_onWalletBalanceChanged);
    _loadCategories();
    _loadDeals();
    _loadUnreadInboxCount();
    _loadWalletBalance();
  }

  @override
  void dispose() {
    RewardService.instance.walletBalanceNotifier
        .removeListener(_onWalletBalanceChanged);
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([
      _loadDeals(),
      _loadUnreadInboxCount(),
      _loadWalletBalance(),
    ]);
  }

  Future<void> _loadWalletBalance() async {
    setState(() => _loadingWallet = true);
    try {
      final wallet = await RewardService.instance.getMyWallet();
      if (!mounted) return;
      setState(() {
        _walletBalance = (wallet['balance'] as num?)?.toInt() ?? 0;
        _loadingWallet = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingWallet = false);
    }
  }

  Future<void> _loadUnreadInboxCount() async {
    setState(() => _loadingInboxCount = true);
    try {
      final count = await CampaignService.instance.getUnreadInboxCount();
      if (!mounted) return;
      setState(() {
        _unreadInboxCount = count;
        _loadingInboxCount = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingInboxCount = false);
    }
  }

  Future<void> _openInbox() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CustomerInboxScreen()),
    );
    _loadUnreadInboxCount();
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
      locationLine = parts.isNotEmpty
          ? parts.join(', ')
          : 'Set your area for better deals';
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
      backgroundColor: _canvasColor,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: _accentColor,
        backgroundColor: _surfaceColor,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ── App bar (compact) ────────────────────────────────────────────
            SliverAppBar(
              floating: false,
              snap: false,
              pinned: true,
              toolbarHeight: 72,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: _canvasColor,
              surfaceTintColor: Colors.transparent,
              titleSpacing: AppTokens.spaceMD,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_greeting()}, $displayName',
                    style: GoogleFonts.dmSans(
                      color: _textSecondaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Explore deals',
                    style: GoogleFonts.dmSans(
                      color: _textPrimaryColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      backgroundColor: _surfaceColor,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusFull),
                        side: const BorderSide(color: _borderColor),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RewardWalletScreen(
                              title: 'Customer Wallet'),
                        ),
                      );
                    },
                    icon: _loadingWallet
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.monetization_on_rounded,
                            size: 16,
                            color: _accentColor,
                          ),
                    label: Text(
                      _loadingWallet ? '...' : '$_walletBalance',
                      style: GoogleFonts.dmSans(
                        color: _textPrimaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    right: AppTokens.spaceMD,
                    left: 2,
                  ),
                  child: Tooltip(
                    message: 'Campaigns',
                    child: Material(
                      color: _surfaceColor,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusFull),
                        side: const BorderSide(color: _borderColor),
                      ),
                      child: InkWell(
                        onTap: _openInbox,
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusFull),
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.campaign_rounded,
                                size: 20,
                                color: _textPrimaryColor.withValues(alpha: 0.9),
                              ),
                              if (_loadingInboxCount)
                                const Positioned(
                                  right: 6,
                                  top: 6,
                                  child: SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _accentColor,
                                    ),
                                  ),
                                )
                              else if (_unreadInboxCount > 0)
                                Positioned(
                                  right: 3,
                                  top: 3,
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _accentColor,
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _accentColor
                                              .withValues(alpha: 0.35),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      _unreadInboxCount > 9
                                          ? '9+'
                                          : '$_unreadInboxCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
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
                        color: _surfaceColor,
                        borderRadius: BorderRadius.circular(AppTokens.radiusLG),
                        border: Border.all(
                          color: _borderColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.place_rounded,
                            size: AppTokens.iconMD,
                            color: _accentColor,
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
                                  style: GoogleFonts.dmSans(
                                    color: _textSecondaryColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dealsLine,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.dmSans(
                                    color: _textMutedColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppTokens.spaceSM),
                          GestureDetector(
                            onTap: _toggleLocation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTokens.spaceSM + 2,
                                vertical: AppTokens.spaceXS + 2,
                              ),
                              decoration: BoxDecoration(
                                color: _useCurrentLocation
                                    ? _accentSoftColor.withValues(alpha: 0.5)
                                    : _surfaceColor,
                                borderRadius:
                                    BorderRadius.circular(AppTokens.radiusFull),
                                border: Border.all(
                                  color: _useCurrentLocation
                                      ? _accentSoftColor
                                      : _borderColor,
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
                                        color: _accentColor,
                                      ),
                                    )
                                  else
                                    Icon(
                                      _useCurrentLocation
                                          ? Icons.location_on_rounded
                                          : Icons.location_off_outlined,
                                      size: 14,
                                      color: _useCurrentLocation
                                          ? _accentColor
                                          : _textMutedColor,
                                    ),
                                  if (_useCurrentLocation &&
                                      _currentLocationText != null) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      _currentLocationText!,
                                      style: GoogleFonts.dmSans(
                                        color: _accentColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Search bar ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.spaceMD,
                      AppTokens.spaceSM,
                      AppTokens.spaceMD,
                      0,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _surfaceColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: _textPrimaryColor.withValues(alpha: 0.05),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.dmSans(
                          color: _textPrimaryColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search deals, shops, categories...',
                          hintStyle: GoogleFonts.dmSans(
                            color: _textMutedColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: _accentSoftColor.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.search_rounded,
                                size: 18,
                                color: _accentColor,
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minHeight: 44,
                            minWidth: 54,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: IconButton(
                                    onPressed: () {
                                      _searchDebounce?.cancel();
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                      });
                                      _refresh();
                                    },
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: _textMutedColor,
                                      size: AppTokens.iconMD,
                                    ),
                                  ),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: _accentColor.withValues(alpha: 0.45),
                              width: 1.2,
                            ),
                          ),
                          filled: true,
                          fillColor: _surfaceColor,
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
                                      ? _accentSoftColor.withValues(alpha: 0.5)
                                      : _surfaceColor,
                                  borderRadius: BorderRadius.circular(
                                      AppTokens.radiusFull),
                                  border: Border.all(
                                    color: isSelected
                                        ? _accentSoftColor
                                        : _borderColor,
                                  ),
                                ),
                                child: Text(
                                  'All',
                                  style: GoogleFonts.dmSans(
                                    color: isSelected
                                        ? _accentColor
                                        : _textSecondaryColor,
                                    fontSize: 12,
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
                                _selectedCategory = isSelected ? null : value;
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
                                    ? _accentSoftColor.withValues(alpha: 0.5)
                                    : _surfaceColor,
                                borderRadius:
                                    BorderRadius.circular(AppTokens.radiusFull),
                                border: Border.all(
                                  color: isSelected
                                      ? _accentSoftColor
                                      : _borderColor,
                                ),
                              ),
                              child: Text(
                                label,
                                style: GoogleFonts.dmSans(
                                  color: isSelected
                                      ? _accentColor
                                      : _textSecondaryColor,
                                  fontSize: 12,
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
                          style: GoogleFonts.dmSans(
                            color: _textPrimaryColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onViewAllOffers,
                          child: Text(
                            'See all',
                            style: GoogleFonts.dmSans(
                              color: _accentColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
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
                              color: _accentColor,
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
                                  color: _errorColor, size: 40),
                              const SizedBox(height: AppTokens.spaceSM),
                              Text(
                                'Could not load deals',
                                style: GoogleFonts.dmSans(
                                  color: _textPrimaryColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppTokens.spaceXS),
                              Text(
                                _dealsError!,
                                style: GoogleFonts.dmSans(
                                  color: _textMutedColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
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

                  // ── Near You section ───────────────────────────────────────
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
                                'Near You',
                                style: GoogleFonts.dmSans(
                                  color: _textPrimaryColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppTokens.spaceMD),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: _surfaceColor.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(
                              AppTokens.radiusFull,
                            ),
                            border: Border.all(
                              color: _borderColor,
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
                              color: _accentColor,
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
                        itemBuilder: (ctx2, i) => _NearYouDealCard(
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
          horizontal: AppTokens.spaceMD,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1F2A3C)
              : const Color(0xFFEBEEF2),
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            color: isSelected
                ? Colors.white
                : const Color(0xFF6B7280),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
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
            color: _HomePalette.textMuted,
            size: 48,
          ),
          const SizedBox(height: AppTokens.spaceSM),
          Text(
            message,
            style: GoogleFonts.dmSans(
              color: _HomePalette.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          if (onBrowseAll != null) ...[
            const SizedBox(height: AppTokens.spaceMD),
            TextButton.icon(
              onPressed: onBrowseAll,
              icon: const Icon(
                Icons.local_offer_outlined,
                color: _HomePalette.accent,
              ),
              label: const Text('Browse all offers'),
            ),
          ],
        ],
      ),
    );
  }
}

class _HomePalette {
  static const canvas = Color(0xFFF3F5F8);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFDCE3EC);
  static const accent = Color(0xFFE88428);
  static const accentSoft = Color(0xFFFBE7D6);
  static const textPrimary = Color(0xFF1E2433);
  static const textSecondary = Color(0xFF334155);
  static const textMuted = Color(0xFF667085);
  static const error = Color(0xFFE24D69);
}

class _NearYouDealCard extends StatelessWidget {
  const _NearYouDealCard({
    required this.offer,
    required this.onOfferUpdated,
  });

  final OfferModel offer;
  final ValueChanged<OfferModel> onOfferUpdated;

  String _discountText() {
    final dynamic rawDiscount = offer.discountValue;
    final num? value = rawDiscount is num
        ? rawDiscount
        : num.tryParse(rawDiscount?.toString() ?? '');
    if (value == null) return 'SPECIAL OFFER';
    if (offer.discountType == 'percentage') {
      return '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}% OFF';
    }
    return '₹${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)} OFF';
  }

  String _categoryText() {
    if (offer.category.trim().isEmpty) return 'Retail';
    final category = offer.category.trim();
    return '${category[0].toUpperCase()}${category.substring(1).toLowerCase()}';
  }

  String _statusText() {
    final status = offer.status.trim();
    if (status.isEmpty) return 'Active';
    return '${status[0].toUpperCase()}${status.substring(1).toLowerCase()}';
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
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openDetails(context),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDCE3EC)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: hasPhoto
                      ? CachedNetworkImage(
                          imageUrl: offer.photos.first,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: const Color(0xFFF4F7FB),
                            alignment: Alignment.center,
                            child: const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFFF4F7FB),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.local_offer_rounded,
                              size: 42,
                              color: const Color(0xFFB8C2D0),
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFF4F7FB),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.local_offer_rounded,
                            size: 42,
                            color: const Color(0xFFB8C2D0),
                          ),
                        ),
                ),
                Container(
                  color: const Color(0xFFF8FAFC),
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              offer.shopName?.trim().isNotEmpty == true
                                  ? offer.shopName!.trim()
                                  : 'Saved Deal',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E2433),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.favorite_rounded,
                                color: Color(0xFFE53935),
                                size: 19,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${offer.likesCount}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: const Color(0xFFE53935),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _NearChip(
                            label: _discountText().replaceAll(' OFF', ''),
                            bg: const Color(0xFFE4F6EC),
                            fg: const Color(0xFF1F9D65),
                          ),
                          _NearChip(
                            label: _categoryText(),
                            bg: const Color(0xFFEDEFF3),
                            fg: const Color(0xFF6B7280),
                          ),
                          _NearChip(
                            label: _statusText(),
                            bg: const Color(0xFFFDEBEC),
                            fg: const Color(0xFFE24D69),
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

class _NearChip extends StatelessWidget {
  const _NearChip({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
