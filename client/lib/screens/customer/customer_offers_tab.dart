import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';
import '../../services/location_service.dart';
import '../../models/offer_model.dart';
import '../../widgets/offer_card.dart';
import '../../core/utils/theme_helper.dart';
import '../../core/utils/dialog_helper.dart';
import 'dart:async';

class CustomerOffersTab extends StatelessWidget {
  const CustomerOffersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: ThemeHelper.getBackgroundGradient(context),
      ),
      child: const SafeArea(
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
  final _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;

  static const int _pageSize = 30;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  String? _errorText;
  String? _nextCursor;
  bool _hasMore = true;
  final List<OfferModel> _items = [];
  static const String _allKey = 'all';

  @override
  void dispose() {
    _cityController.dispose();
    _pincodeController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
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
      _nextCursor = null;
      _hasMore = true;
      _items.clear();
    });
    await _fetchPage();
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
      _errorText = null;
    });
    await _fetchPage();
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
        cursor: _nextCursor,
      );
      final offers = page['offers'] as List<OfferModel>;
      final pageInfo = (page['pageInfo'] as Map<String, dynamic>?) ?? const {};
      final nextCursor = pageInfo['nextCursor']?.toString();
      final hasMore = pageInfo['hasMore'] == true;

      if (!mounted) return;
      setState(() {
        _items.addAll(offers);
        _nextCursor = (nextCursor != null && nextCursor.isNotEmpty)
            ? nextCursor
            : null;
        _hasMore = hasMore && _nextCursor != null;
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
    final set = _items
        .map((o) => o.category.trim().toLowerCase())
        .where((c) => c.isNotEmpty)
        .toSet()
      ..remove(_allKey);
    final categories = set.toList()..sort();
    return [_allKey, ...categories];
  }

  String _displayLabel(String value) {
    if (value == _allKey) return 'All';
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
        AppBar(
          backgroundColor: AppColors.transparent,
          elevation: 0,
          title: Text(
            'Offers Near You',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Container(
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
                    hintText: 'Search offers...',
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: ThemeHelper.getSurfaceColor(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortBy,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                                value: 'newest', child: Text('Newest First')),
                            DropdownMenuItem(
                                value: 'most_liked', child: Text('Most Liked')),
                            DropdownMenuItem(
                                value: 'discount_high_to_low',
                                child: Text('Discount High to Low')),
                            DropdownMenuItem(
                                value: 'discount_low_to_high',
                                child: Text('Discount Low to High')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _sortBy = value;
                              });
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
                    child: OutlinedButton.icon(
                      onPressed: () => _showFilterDialog(context),
                      icon: Icon(
                        Icons.tune_rounded,
                        color: _hasActiveFilters
                            ? AppColors.primary
                            : Theme.of(context).iconTheme.color,
                      ),
                      label: Text(
                        'Filters',
                        style: TextStyle(
                          color: _hasActiveFilters
                              ? AppColors.primary
                              : Theme.of(context).textTheme.labelLarge?.color,
                          fontWeight:
                              _hasActiveFilters ? FontWeight.w600 : null,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        side: BorderSide(
                          color: _hasActiveFilters
                              ? AppColors.primary
                              : AppColors.grey400,
                          width: _hasActiveFilters ? 1.5 : 1,
                        ),
                        backgroundColor: _hasActiveFilters
                            ? AppColors.primary.withValues(alpha: 0.06)
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Current Location Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                        _isLoadingLocation ? null : _toggleCurrentLocation,
                    icon: _isLoadingLocation
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _useCurrentLocation
                                ? Iconsax.gps
                                : Iconsax.location,
                          ),
                    label: Text(
                      _isLoadingLocation
                          ? 'Detecting Location...'
                          : (_useCurrentLocation && _currentLocationText != null
                              ? 'Current: $_currentLocationText'
                              : 'Use Current Location'),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _useCurrentLocation
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : null,
                      side: BorderSide(
                        color: _useCurrentLocation
                            ? AppColors.primary
                            : AppColors.grey400,
                        width: _useCurrentLocation ? 2 : 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        _buildActiveFilters(context),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadInitial,
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
            color: ThemeHelper.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: CircularProgressIndicator()),
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
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load offers',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorText!,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadInitial,
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
                color: Theme.of(context).colorScheme.primary.withValues(
                      alpha: 0.5,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                _hasActiveFilters
                    ? 'No offers match your filters'
                    : 'No offers available',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _hasActiveFilters
                    ? 'Try adjusting your filters or search query'
                    : 'Check back later for new offers',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              if (_hasActiveFilters)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextButton.icon(
                    onPressed: _clearAllFilters,
                    icon: const Icon(Icons.clear_all_rounded),
                    label: const Text('Clear all filters'),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _items.length + 1,
      itemBuilder: (context, index) {
        if (index == _items.length) {
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

        final o = _items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: OfferCard(
            offer: o,
            onOfferUpdated: (updated) {
              final idx = _items.indexWhere((x) => x.id == updated.id);
              if (idx < 0) return;
              setState(() => _items[idx] = updated);
            },
          ),
        );
      },
    );
  }

  Widget _buildActiveFilters(BuildContext context) {
    if (!_hasActiveFilters) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (_categoryFilter != _allKey)
            Chip(
              avatar: const Icon(Icons.category_rounded, size: 16),
              label: Text('Category: ${_displayLabel(_categoryFilter)}'),
              onDeleted: () {
                setState(() {
                  _categoryFilter = _allKey;
                });
                _loadInitial();
              },
            ),
          if (!_useCurrentLocation &&
              _stateFilter != null &&
              _stateFilter!.isNotEmpty)
            Chip(
              avatar: const Icon(Icons.map_rounded, size: 16),
              label: Text('State: $_stateFilter'),
              onDeleted: () {
                setState(() {
                  _stateFilter = null;
                });
                _loadInitial();
              },
            ),
          if (!_useCurrentLocation &&
              _cityFilter != null &&
              _cityFilter!.isNotEmpty)
            Chip(
              avatar: const Icon(Icons.location_city_rounded, size: 16),
              label: Text('City: $_cityFilter'),
              onDeleted: () {
                setState(() {
                  _cityFilter = null;
                  _cityController.clear();
                });
                _loadInitial();
              },
            ),
          if (!_useCurrentLocation &&
              _pincodeFilter != null &&
              _pincodeFilter!.isNotEmpty)
            Chip(
              avatar: const Icon(Icons.pin_drop_rounded, size: 16),
              label: Text('Pincode: $_pincodeFilter'),
              onDeleted: () {
                setState(() {
                  _pincodeFilter = null;
                  _pincodeController.clear();
                });
                _loadInitial();
              },
            ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    final user = AuthStore.currentUser;
    final defaultPincode = user?.pincode ?? '';
    final categoryOptions = _availableCategories;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Filter Offers',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _hasActiveFilters
                      ? AppColors.primary
                      : Theme.of(context).textTheme.titleMedium?.color,
                ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _categoryFilter,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_rounded),
                    isDense: true,
                  ),
                  items: categoryOptions
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            value == _allKey
                                ? 'All Categories'
                                : _displayLabel(value),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      _categoryFilter = value ?? _allKey;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: ['Karnataka', 'Delhi', 'Maharashtra']
                          .contains(_stateFilter)
                      ? _stateFilter
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'State',
                    prefixIcon: Icon(Icons.map_rounded),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All States')),
                    DropdownMenuItem(
                        value: 'Karnataka', child: Text('Karnataka')),
                    DropdownMenuItem(value: 'Delhi', child: Text('Delhi')),
                    DropdownMenuItem(
                        value: 'Maharashtra', child: Text('Maharashtra')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _stateFilter = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city_rounded),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Pincode',
                    prefixIcon: const Icon(Icons.pin_drop_rounded),
                    hintText: defaultPincode.isNotEmpty ? defaultPincode : null,
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 24),
                // Row 1: Clear + Cancel
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
                      child: const Text('Clear'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Row 2: Apply aligned right
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _cityFilter = _cityController.text.trim().isEmpty
                            ? null
                            : _cityController.text.trim();
                        _pincodeFilter =
                            _pincodeController.text.trim().isEmpty
                                ? null
                                : _pincodeController.text.trim();
                      });
                      _loadInitial();
                      Navigator.pop(context);
                    },
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
}
