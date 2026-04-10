import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';
import '../../services/location_service.dart';
import '../../services/subscription_service.dart';
import '../../models/offer_model.dart';
import '../../widgets/offer_card.dart';
import '../../core/utils/dialog_helper.dart';
import 'dart:async';

// ── Light palette (consistent with home/profile/loans/offer_detail) ──────────
class _OP {
  static const canvas        = Color(0xFFF3F5F8);
  static const surface       = Color(0xFFFFFFFF);
  static const elevated      = Color(0xFFF4F7FB);
  static const border        = Color(0xFFDCE3EC);
  static const accent        = Color(0xFFE88428);
  static const accentSoft    = Color(0xFFFBE7D6);
  static const textPrimary   = Color(0xFF1E2433);
  static const textSecondary = Color(0xFF334155);
  static const textMuted     = Color(0xFF667085);
  static const error         = Color(0xFFE24D69);
  static const white         = Color(0xFFFFFFFF);
}

class CustomerOffersTab extends StatelessWidget {
  const CustomerOffersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: _OP.canvas,
      child: SafeArea(
        child: CustomerOffersBody(),
      ),
    );
  }
}

class CustomerOffersBody extends StatefulWidget {
  const CustomerOffersBody({super.key});

  @override
  State<CustomerOffersBody> createState() => _CustomerOffersBodyState();
}

class _CustomerOffersBodyState extends State<CustomerOffersBody> {
  String? _stateFilter;
  String? _cityFilter;
  String? _pincodeFilter;
  String _categoryFilter = 'all';
  String _searchQuery = '';
  String _sortBy = 'newest';
  bool _useCurrentLocation = false;
  bool _isLoadingLocation = false;
  String? _currentLocationText;
  bool _locationFromCurrent = false;
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _stateController = TextEditingController();
  final _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;

  static const int _pageSize = 30;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _isFilterPincodeLoading = false;
  String? _errorText;
  int _nextOffset = 0;
  bool _hasMore = true;
  final List<OfferModel> _items = [];
  static const String _allKey = 'all';
  List<Map<String, dynamic>> _categories = [];

  @override
  void dispose() {
    _cityController.dispose();
    _pincodeController.dispose();
    _stateController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initializeOffers();
  }

  Future<void> _initializeOffers() async {
    await _loadCategories();
    await _tryAutoApplyCurrentLocation();
    await _loadInitial();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || _isInitialLoading) return;
    final position = _scrollController.position;
    if (!position.hasPixels) return;
    if (position.maxScrollExtent - position.pixels < 350) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isInitialLoading = true;
      _isLoadingMore = false;
      _errorText = null;
      _nextOffset = 0;
      _hasMore = true;
      _items.clear();
    });
    await _fetchPage();
  }

  Future<void> _tryAutoApplyCurrentLocation() async {
    try {
      final locationData =
          await LocationService.instance.getCurrentLocationWithAddress();
      if (!mounted) return;

      final pincode = locationData['pincode'] as String?;
      final city = locationData['city'] as String?;
      final state = locationData['state'] as String?;

      if ((pincode == null || pincode.isEmpty) &&
          (city == null || city.isEmpty) &&
          (state == null || state.isEmpty)) {
        return;
      }

      setState(() {
        _pincodeFilter = (pincode?.isNotEmpty ?? false) ? pincode : null;
        _cityFilter = (city?.isNotEmpty ?? false) ? city : null;
        _stateFilter = (state?.isNotEmpty ?? false) ? state : null;
        _currentLocationText = [
          if (city?.isNotEmpty == true) city,
          if (pincode?.isNotEmpty == true) pincode,
        ].join(', ');
        _useCurrentLocation = true;
        _locationFromCurrent = true;
      });

      if (pincode != null && pincode.isNotEmpty) {
        _pincodeController.text = pincode;
      }
      if (city != null && city.isNotEmpty) {
        _cityController.text = city;
      }
      if (state != null && state.isNotEmpty) {
        _stateController.text = state;
      }
    } catch (_) {
      // Silent fallback: if location isn't available, user can set filters manually.
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
      // If categories fail to load, we just fall back to "All"
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
      _errorText = null;
    });
    await _fetchPage();
  }

  Future<void> _lookupFilterPincode(String pincode) async {
    setState(() {
      _isFilterPincodeLoading = true;
    });
    try {
      final result = await AuthService.instance.lookupPincode(pincode);
      if (!mounted) return;
      final state = result['state']?.toString() ?? '';
      final district = result['district']?.toString() ?? '';

      setState(() {
        _pincodeFilter = pincode;
        _cityController.text = district;
        _stateController.text = state;
        _cityFilter = district.isNotEmpty ? district : null;
        _stateFilter = state.isNotEmpty ? state : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cityController.clear();
        _stateController.clear();
        _cityFilter = null;
        _stateFilter = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isFilterPincodeLoading = false;
        });
      }
    }
  }

  Future<void> _fetchPage() async {
    try {
      final page = await AuthService.instance.getCustomerOffersPage(
        state: _stateFilter,
        city: _cityFilter,
        pincode: _pincodeFilter,
        q: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
        category: _categoryFilter == _allKey ? null : _categoryFilter,
        sort: _sortBy,
        limit: _pageSize,
        offset: _nextOffset,
      );
      final offers = page['offers'] as List<OfferModel>;
      final pageInfo = (page['pageInfo'] as Map<String, dynamic>?) ?? const {};
      final dynamic nextOffsetValue = pageInfo['nextOffset'];
      final parsedNextOffset = nextOffsetValue is int
          ? nextOffsetValue
          : int.tryParse(nextOffsetValue?.toString() ?? '');
      final hasMore = pageInfo['hasMore'] == true;

      if (!mounted) return;
      setState(() {
        _items.addAll(offers);
        _nextOffset = parsedNextOffset ?? (_nextOffset + offers.length);
        _hasMore = hasMore;
        _isInitialLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.toString();
        _isInitialLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final locationData =
          await LocationService.instance.getCurrentLocationWithAddress();

      if (!mounted) return;

      final pincode = locationData['pincode'] as String?;
      final city = locationData['city'] as String?;
      final state = locationData['state'] as String?;

      setState(() {
        _pincodeFilter = pincode;
        _cityFilter = city;
        _stateFilter = state;
        _currentLocationText = [
          if (city?.isNotEmpty == true) city,
          if (pincode?.isNotEmpty == true) pincode,
        ].join(', ');
        _useCurrentLocation = true;
        _isLoadingLocation = false;
        _locationFromCurrent = true;
      });

      // Update controllers
      if (pincode != null) _pincodeController.text = pincode;
      if (city != null) _cityController.text = city;

      // Refresh offers with new location
      _loadInitial();

      DialogHelper.showSuccessSnackBar(
        context,
        'Location detected: $_currentLocationText',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingLocation = false;
        _useCurrentLocation = false;
      });

      String errorMessage = 'Failed to get current location';
      if (e.toString().contains('denied')) {
        errorMessage =
            'Location permission denied. Please enable location access in settings.';
      } else if (e.toString().contains('disabled')) {
        errorMessage = 'Location services are disabled. Please enable them.';
      }

      DialogHelper.showErrorSnackBar(context, errorMessage);
    }
  }

  void _toggleCurrentLocation() {
    if (_useCurrentLocation) {
      // Turn off current location
      setState(() {
        _useCurrentLocation = false;
        _currentLocationText = null;
        if (_locationFromCurrent) {
          _stateFilter = null;
          _cityFilter = null;
          _pincodeFilter = null;
          _cityController.clear();
          _pincodeController.clear();
          _locationFromCurrent = false;
        }
      });
      _loadInitial();
    } else {
      // Get current location
      _getCurrentLocation();
    }
  }

  List<String> get _availableCategories {
    if (_categories.isEmpty) {
      return const [_allKey];
    }
    final set = _categories
        .map((c) => (c['value'] ?? '').toString().trim())
        .where((v) => v.isNotEmpty)
        .toSet();
    final categories = set.toList()..sort();
    return [_allKey, ...categories];
  }

  String _displayLabel(String value) {
    if (value == _allKey) return 'All';
    final lower = value.trim().toLowerCase();
    final match = _categories.firstWhere(
      (c) => (c['value'] ?? '').toString().trim().toLowerCase() == lower,
      orElse: () => const {},
    );
    final label = match['label']?.toString();
    if (label != null && label.isNotEmpty) return label;

    final words = value.split(' ');
    return words
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  bool get _hasActiveFilters {
    final hasLocationFilters =
        _stateFilter != null || _cityFilter != null || _pincodeFilter != null;

    return _searchQuery.isNotEmpty ||
        (!_useCurrentLocation && hasLocationFilters) ||
        _categoryFilter != _allKey;
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _stateFilter = null;
      _cityFilter = null;
      _pincodeFilter = null;
      _categoryFilter = _allKey;
      _cityController.clear();
      _pincodeController.clear();
    });
    _loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── App bar ──────────────────────────────────────────────────────────
        Container(
          color: _OP.canvas,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Offers Near You',
                style: GoogleFonts.dmSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _OP.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              // ── Search bar ────────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: _OP.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _OP.border),
                  boxShadow: [
                    BoxShadow(
                      color: _OP.textPrimary.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.dmSans(
                    color: _OP.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search offers...',
                    hintStyle: GoogleFonts.dmSans(
                      color: _OP.textMuted,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: _OP.textMuted, size: 20),
                    filled: true,
                    fillColor: _OP.surface,
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                color: _OP.textMuted, size: 18),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                              _loadInitial();
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _searchDebounce?.cancel();
                    _searchDebounce = Timer(
                      const Duration(milliseconds: 350),
                      _loadInitial,
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              // ── Sort + Filter row ─────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: _OP.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _OP.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortBy,
                          isExpanded: true,
                          dropdownColor: _OP.surface,
                          style: GoogleFonts.dmSans(
                            color: _OP.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: _OP.textMuted),
                          items: const [
                            DropdownMenuItem(
                                value: 'newest',
                                child: Text('Newest First')),
                            DropdownMenuItem(
                                value: 'most_liked',
                                child: Text('Most Liked')),
                            DropdownMenuItem(
                                value: 'discount_high_to_low',
                                child: Text('Discount ↓')),
                            DropdownMenuItem(
                                value: 'discount_low_to_high',
                                child: Text('Discount ↑')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _sortBy = value);
                              _loadInitial();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () => _showFilterDialog(context),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: _hasActiveFilters
                              ? _OP.accentSoft
                              : _OP.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _hasActiveFilters
                                ? _OP.accent
                                : _OP.border,
                            width: _hasActiveFilters ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 18,
                              color: _hasActiveFilters
                                  ? _OP.accent
                                  : _OP.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Filters',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _hasActiveFilters
                                    ? _OP.accent
                                    : _OP.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // ── Location button ───────────────────────────────────────────
              GestureDetector(
                onTap: _isLoadingLocation ? null : _toggleCurrentLocation,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: _useCurrentLocation ? _OP.accentSoft : _OP.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _useCurrentLocation ? _OP.accent : _OP.border,
                      width: _useCurrentLocation ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      _isLoadingLocation
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: _OP.accent),
                            )
                          : Icon(
                              _useCurrentLocation
                                  ? Iconsax.gps
                                  : Iconsax.location,
                              size: 18,
                              color: _useCurrentLocation
                                  ? _OP.accent
                                  : _OP.textMuted,
                            ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isLoadingLocation
                              ? 'Detecting location...'
                              : (_useCurrentLocation &&
                                      _currentLocationText != null
                                  ? 'Current: $_currentLocationText'
                                  : 'Use current location'),
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _useCurrentLocation
                                ? _OP.accent
                                : _OP.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_useCurrentLocation)
                        const Icon(Icons.close_rounded,
                            size: 16, color: _OP.accent),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        // ── List ─────────────────────────────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadInitial,
            color: _OP.accent,
            backgroundColor: _OP.surface,
            child: _buildList(context),
          ),
        ),
      ],
    );
  }

  Widget _buildList(BuildContext context) {
    if (_isInitialLoading) {
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 120,
          decoration: BoxDecoration(
            color: _OP.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _OP.border),
          ),
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: _OP.accent),
          ),
        ),
      );
    }

    if (_errorText != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 64, color: _OP.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load offers',
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _OP.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorText!,
                style: GoogleFonts.dmSans(fontSize: 13, color: _OP.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadInitial,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _OP.accent,
                  foregroundColor: _OP.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _hasActiveFilters
                    ? Icons.search_off_rounded
                    : Icons.local_offer_outlined,
                size: 64,
                color: _OP.textMuted,
              ),
              const SizedBox(height: 16),
              Text(
                _hasActiveFilters
                    ? 'No offers match your filters'
                    : 'No offers available',
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _OP.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _hasActiveFilters
                    ? 'Try adjusting your filters or search query'
                    : 'Check back later for new offers',
                style: GoogleFonts.dmSans(fontSize: 13, color: _OP.textMuted),
                textAlign: TextAlign.center,
              ),
              if (_hasActiveFilters)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextButton.icon(
                    onPressed: _clearAllFilters,
                    style: TextButton.styleFrom(foregroundColor: _OP.accent),
                    icon: const Icon(Icons.clear_all_rounded),
                    label: const Text('Clear all filters'),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final int rowCount = (_items.length / 2).ceil();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: rowCount + 1, // extra row for footer (load more/end)
      itemBuilder: (context, index) {
        if (index == rowCount) {
          if (_isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          if (!_hasMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('You’ve reached the end')),
            );
          }
          if (_errorText != null) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: TextButton.icon(
                  onPressed: _loadMore,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tap to retry'),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        final int leftIndex = index * 2;
        final int rightIndex = leftIndex + 1;

        final leftOffer = _items[leftIndex];
        final OfferModel? rightOffer =
            rightIndex < _items.length ? _items[rightIndex] : null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: OfferCard(
                    offer: leftOffer,
                    onOfferUpdated: (updated) {
                      final idx = _items.indexWhere((x) => x.id == updated.id);
                      if (idx < 0) return;
                      setState(() => _items[idx] = updated);
                    },
                  ),
                ),
              ),
              if (rightOffer != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: OfferCard(
                      offer: rightOffer,
                      onOfferUpdated: (updated) {
                        final idx = _items.indexWhere((x) => x.id == updated.id);
                        if (idx < 0) return;
                        setState(() => _items[idx] = updated);
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showFilterDialog(BuildContext context) {
    final user = AuthStore.currentUser;
    final defaultPincode = user?.pincode ?? '';
    final categoryOptions = _availableCategories;

    _cityController.text = _cityFilter ?? '';
    _pincodeController.text = _pincodeFilter ?? '';
    _stateController.text = _stateFilter ?? '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _OP.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Filter Offers',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _hasActiveFilters ? _OP.accent : _OP.textPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _categoryFilter,
                  dropdownColor: _OP.surface,
                  style: GoogleFonts.dmSans(
                      color: _OP.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: const TextStyle(color: _OP.textMuted),
                    prefixIcon:
                        const Icon(Icons.category_rounded, color: _OP.textMuted),
                    isDense: true,
                    filled: true,
                    fillColor: _OP.elevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _OP.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _OP.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: _OP.accent, width: 1.5),
                    ),
                  ),
                  items: categoryOptions
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(value == _allKey
                                ? 'All Categories'
                                : _displayLabel(value)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      _categoryFilter = value ?? _allKey;
                    });
                  },
                ),
                const SizedBox(height: 14),
                _filterField(
                  controller: _stateController,
                  label: 'State (auto)',
                  icon: Icons.map_rounded,
                  readOnly: true,
                ),
                const SizedBox(height: 14),
                _filterField(
                  controller: _cityController,
                  label: 'City',
                  icon: Icons.location_city_rounded,
                ),
                const SizedBox(height: 14),
                _filterField(
                  controller: _pincodeController,
                  label: 'Pincode',
                  icon: Icons.pin_drop_rounded,
                  hint: defaultPincode.isNotEmpty
                      ? 'e.g. $defaultPincode'
                      : 'Optional',
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final trimmed = value.trim();
                    if (trimmed.length == 6) {
                      _lookupFilterPincode(trimmed);
                    } else {
                      setState(() {
                        _cityController.clear();
                        _stateController.clear();
                        _cityFilter = null;
                        _stateFilter = null;
                        _pincodeFilter = null;
                      });
                    }
                  },
                ),
                if (_isFilterPincodeLoading) ...[
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(
                      minHeight: 2, color: _OP.accent),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          _stateFilter = null;
                          _cityFilter = null;
                          _pincodeFilter = null;
                          _categoryFilter = _allKey;
                          _cityController.clear();
                          _pincodeController.clear();
                        });
                      },
                      style: TextButton.styleFrom(
                          foregroundColor: _OP.textSecondary),
                      child: const Text('Clear'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                          foregroundColor: _OP.textSecondary),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      final normalizedCity = _cityController.text
                          .trim()
                          .replaceAll(RegExp(r'\s+'), ' ');
                      setState(() {
                        _stateFilter =
                            _stateController.text.trim().isEmpty
                                ? null
                                : _stateController.text.trim();
                        _cityFilter = normalizedCity.isEmpty
                            ? null
                            : normalizedCity;
                        _pincodeFilter =
                            _pincodeController.text.trim().isEmpty
                                ? null
                                : _pincodeController.text.trim();
                      });
                      _loadInitial();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _OP.accent,
                      foregroundColor: _OP.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool readOnly = false,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      style: GoogleFonts.dmSans(color: _OP.textPrimary, fontSize: 14),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _OP.textMuted),
        hintText: hint,
        hintStyle: const TextStyle(color: _OP.textMuted),
        prefixIcon: Icon(icon, color: _OP.textMuted, size: 20),
        isDense: true,
        filled: true,
        fillColor: _OP.elevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _OP.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _OP.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _OP.accent, width: 1.5),
        ),
      ),
    );
  }
}
