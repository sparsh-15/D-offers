import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';
import '../../services/location_service.dart';
import '../../models/offer_model.dart';
import '../../widgets/offer_card.dart';
import '../../core/utils/theme_helper.dart';
import '../../core/utils/dialog_helper.dart';

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
  late Future<List<OfferModel>> _future;
  String? _stateFilter;
  String? _cityFilter;
  String? _pincodeFilter;
  String _categoryFilter = 'all';
  String _genderFilter = 'all';
  String _ageGroupFilter = 'all';
  String _searchQuery = '';
  String _sortBy = 'newest';
  double _minRating = 0.0;
  bool _useCurrentLocation = false;
  bool _isLoadingLocation = false;
  String? _currentLocationText;
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _searchController = TextEditingController();
  List<OfferModel> _allOffers = [];
  static const String _allKey = 'all';
  static const List<String> _genderOptions = [
    _allKey,
    'men',
    'women',
    'unisex',
  ];
  static const List<String> _ageGroupOptions = [
    _allKey,
    'kids',
    'teens',
    'adults',
    'seniors',
  ];

  @override
  void dispose() {
    _cityController.dispose();
    _pincodeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _future = AuthService.instance.getCustomerOffers();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = AuthService.instance.getCustomerOffers(
        state: _stateFilter,
        city: _cityFilter,
        pincode: _pincodeFilter,
      );
    });
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
      });

      // Update controllers
      if (pincode != null) _pincodeController.text = pincode;
      if (city != null) _cityController.text = city;

      // Refresh offers with new location
      _refresh();

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
      });
    } else {
      // Get current location
      _getCurrentLocation();
    }
  }

  List<OfferModel> _filterAndSortOffers(List<OfferModel> offers) {
    var filtered = offers;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((offer) {
        return offer.title.toLowerCase().contains(query) ||
            offer.description.toLowerCase().contains(query) ||
            offer.category.toLowerCase().contains(query);
      }).toList();
    }

    if (_categoryFilter != _allKey) {
      filtered = filtered
          .where((offer) => offer.category.toLowerCase() == _categoryFilter)
          .toList();
    }

    if (_genderFilter != _allKey) {
      filtered = filtered
          .where((offer) => _matchesGender(offer, _genderFilter))
          .toList();
    }

    if (_ageGroupFilter != _allKey) {
      filtered = filtered
          .where((offer) => _matchesAgeGroup(offer, _ageGroupFilter))
          .toList();
    }

    switch (_sortBy) {
      case 'newest':
        filtered.sort((a, b) {
          final aDate = a.createdAt ?? DateTime(1970);
          final bDate = b.createdAt ?? DateTime(1970);
          return bDate.compareTo(aDate);
        });
        break;
      case 'most_liked':
        filtered.sort((a, b) => b.likesCount.compareTo(a.likesCount));
        break;
      case 'nearest':
        // Sort by nearest - for now using a placeholder
        // In production, this would use actual distance calculation
        filtered.sort((a, b) => 0);
        break;
      case 'discount_high_to_low':
        filtered.sort((a, b) {
          final aValue = _getDiscountValue(a);
          final bValue = _getDiscountValue(b);
          return bValue.compareTo(aValue);
        });
        break;
      case 'discount_low_to_high':
        filtered.sort((a, b) {
          final aValue = _getDiscountValue(a);
          final bValue = _getDiscountValue(b);
          return aValue.compareTo(bValue);
        });
        break;
    }

    return filtered;
  }

  bool _matchesGender(OfferModel offer, String filter) {
    final haystack = _normalizedText(offer);
    switch (filter) {
      case 'men':
        return _containsAny(
            haystack, const [' men ', ' male', 'gents', 'boys']);
      case 'women':
        return _containsAny(
            haystack, const [' women ', ' female', 'ladies', 'girls']);
      case 'unisex':
        return _containsAny(haystack, const ['unisex', 'all genders']);
      default:
        return true;
    }
  }

  bool _matchesAgeGroup(OfferModel offer, String filter) {
    final haystack = _normalizedText(offer);
    switch (filter) {
      case 'kids':
        return _containsAny(
            haystack, const ['kids', 'kid', 'children', 'child', 'toddler']);
      case 'teens':
        return _containsAny(haystack, const ['teen', 'teenager', 'youth']);
      case 'adults':
        return _containsAny(
            haystack, const ['adult', 'men', 'women', 'working']);
      case 'seniors':
        return _containsAny(
            haystack, const ['senior', 'elderly', 'aged', 'retired']);
      default:
        return true;
    }
  }

  String _normalizedText(OfferModel offer) {
    final text =
        '${offer.title} ${offer.description} ${offer.category}'.toLowerCase();
    return ' $text ';
  }

  bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }

  double _getDiscountValue(OfferModel offer) {
    if (offer.discountType == 'percentage' && offer.discountValue != null) {
      return (offer.discountValue as num).toDouble();
    } else if (offer.discountType == 'fixed' && offer.discountValue != null) {
      return (offer.discountValue as num).toDouble();
    }
    return 0;
  }

  List<String> get _availableCategories {
    final set = _allOffers
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
    return _searchQuery.isNotEmpty ||
        _stateFilter != null ||
        _cityFilter != null ||
        _pincodeFilter != null ||
        _categoryFilter != _allKey ||
        _genderFilter != _allKey ||
        _ageGroupFilter != _allKey ||
        _minRating > 0.0;
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _stateFilter = null;
      _cityFilter = null;
      _pincodeFilter = null;
      _categoryFilter = _allKey;
      _genderFilter = _allKey;
      _ageGroupFilter = _allKey;
      _minRating = 0.0;
      _cityController.clear();
      _pincodeController.clear();
    });
    _refresh();
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
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
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
                                value: 'nearest', child: Text('Nearest')),
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
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showFilterDialog(context),
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Filters'),
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
          child: FutureBuilder<List<OfferModel>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                _allOffers = snapshot.data ?? [];
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      height: 120,
                      decoration: BoxDecoration(
                        color: ThemeHelper.getSurfaceColor(context),
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
                          'Failed to load offers',
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
              final offers = _filterAndSortOffers(_allOffers);
              if (offers.isEmpty) {
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
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.5),
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
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: offers.length,
                  itemBuilder: (context, index) {
                    final o = offers[index];
                    return FadeInUp(
                      delay: Duration(milliseconds: 50 * index),
                      child: OfferCard(
                        offer: o,
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
              },
            ),
          if (_genderFilter != _allKey)
            Chip(
              avatar: const Icon(Icons.wc_rounded, size: 16),
              label: Text('Gender: ${_displayLabel(_genderFilter)}'),
              onDeleted: () {
                setState(() {
                  _genderFilter = _allKey;
                });
              },
            ),
          if (_ageGroupFilter != _allKey)
            Chip(
              avatar: const Icon(Icons.cake_rounded, size: 16),
              label: Text('Age: ${_displayLabel(_ageGroupFilter)}'),
              onDeleted: () {
                setState(() {
                  _ageGroupFilter = _allKey;
                });
              },
            ),
          if (_stateFilter != null && _stateFilter!.isNotEmpty)
            Chip(
              avatar: const Icon(Icons.map_rounded, size: 16),
              label: Text('State: $_stateFilter'),
              onDeleted: () {
                setState(() {
                  _stateFilter = null;
                  _refresh();
                });
              },
            ),
          if (_cityFilter != null && _cityFilter!.isNotEmpty)
            Chip(
              avatar: const Icon(Icons.location_city_rounded, size: 16),
              label: Text('City: $_cityFilter'),
              onDeleted: () {
                setState(() {
                  _cityFilter = null;
                  _cityController.clear();
                  _refresh();
                });
              },
            ),
          if (_pincodeFilter != null && _pincodeFilter!.isNotEmpty)
            Chip(
              avatar: const Icon(Icons.pin_drop_rounded, size: 16),
              label: Text('Pincode: $_pincodeFilter'),
              onDeleted: () {
                setState(() {
                  _pincodeFilter = null;
                  _pincodeController.clear();
                  _refresh();
                });
              },
            ),
          if (_minRating > 0.0)
            Chip(
              avatar: const Icon(Icons.star_rounded, size: 16),
              label: Text('Rating: ${_minRating.toStringAsFixed(1)}+'),
              onDeleted: () {
                setState(() {
                  _minRating = 0.0;
                });
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
          title: const Text('Filter Offers'),
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
                  initialValue: _genderFilter,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: Icon(Icons.wc_rounded),
                    isDense: true,
                  ),
                  items: _genderOptions
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            value == _allKey
                                ? 'All Genders'
                                : _displayLabel(value),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      _genderFilter = value ?? _allKey;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _ageGroupFilter,
                  decoration: const InputDecoration(
                    labelText: 'Age Group',
                    prefixIcon: Icon(Icons.cake_rounded),
                    isDense: true,
                  ),
                  items: _ageGroupOptions
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            value == _allKey
                                ? 'All Ages'
                                : _displayLabel(value),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      _ageGroupFilter = value ?? _allKey;
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
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Minimum Rating: ${_minRating.toStringAsFixed(1)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    Slider(
                      value: _minRating,
                      min: 0.0,
                      max: 5.0,
                      divisions: 10,
                      label: _minRating.toStringAsFixed(1),
                      onChanged: (value) {
                        setDialogState(() {
                          _minRating = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  _stateFilter = null;
                  _cityFilter = null;
                  _pincodeFilter = null;
                  _categoryFilter = _allKey;
                  _genderFilter = _allKey;
                  _ageGroupFilter = _allKey;
                  _minRating = 0.0;
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
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _cityFilter = _cityController.text.trim().isEmpty
                      ? null
                      : _cityController.text.trim();
                  _pincodeFilter = _pincodeController.text.trim().isEmpty
                      ? null
                      : _pincodeController.text.trim();
                });
                _refresh();
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}
