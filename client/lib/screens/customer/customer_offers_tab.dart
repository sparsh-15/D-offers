import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';
import '../../models/offer_model.dart';
import '../../widgets/offer_card.dart';

class CustomerOffersTab extends StatelessWidget {
  const CustomerOffersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.backgroundGradient
            : AppColors.lightBackgroundGradient,
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
  String _searchQuery = '';
  String _sortBy = 'newest';
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _searchController = TextEditingController();
  List<OfferModel> _allOffers = [];

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

  List<OfferModel> _filterAndSortOffers(List<OfferModel> offers) {
    var filtered = offers;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((offer) {
        return offer.title.toLowerCase().contains(query) ||
            offer.description.toLowerCase().contains(query);
      }).toList();
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
      case 'highest_discount':
        filtered.sort((a, b) {
          final aValue = _getDiscountValue(a);
          final bValue = _getDiscountValue(b);
          return bValue.compareTo(aValue);
        });
        break;
    }

    return filtered;
  }

  double _getDiscountValue(OfferModel offer) {
    if (offer.discountType == 'percentage' && offer.discountValue != null) {
      return (offer.discountValue as num).toDouble();
    } else if (offer.discountType == 'fixed' && offer.discountValue != null) {
      return (offer.discountValue as num).toDouble();
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        AppBar(
          backgroundColor: Colors.transparent,
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
                  color: isDark ? AppColors.surface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
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
                        color: isDark ? AppColors.surface : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortBy,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'newest', child: Text('Newest First')),
                            DropdownMenuItem(value: 'most_liked', child: Text('Most Liked')),
                            DropdownMenuItem(value: 'highest_discount', child: Text('Highest Discount')),
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
                  IconButton(
                    icon: const Icon(Icons.filter_list_rounded),
                    onPressed: () {
                      _showFilterDialog(context);
                    },
                    tooltip: 'Filters',
                  ),
                ],
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
                          _searchQuery.isNotEmpty || _stateFilter != null || _cityFilter != null || _pincodeFilter != null
                              ? Icons.search_off_rounded
                              : Icons.local_offer_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || _stateFilter != null || _cityFilter != null || _pincodeFilter != null
                              ? 'No offers match your filters'
                              : 'No offers available',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty || _stateFilter != null || _cityFilter != null || _pincodeFilter != null
                              ? 'Try adjusting your filters or search query'
                              : 'Check back later for new offers',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        if (_searchQuery.isNotEmpty || _stateFilter != null || _cityFilter != null || _pincodeFilter != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                  _stateFilter = null;
                                  _cityFilter = null;
                                  _pincodeFilter = null;
                                  _cityController.clear();
                                  _pincodeController.clear();
                                  _refresh();
                                });
                              },
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
    final hasFilters = _stateFilter != null || _cityFilter != null || _pincodeFilter != null;
    if (!hasFilters) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (_stateFilter != null && _stateFilter!.isNotEmpty)
            Chip(
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
              label: Text('Pincode: $_pincodeFilter'),
              onDeleted: () {
                setState(() {
                  _pincodeFilter = null;
                  _pincodeController.clear();
                  _refresh();
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
                  value: _stateFilter,
                  decoration: const InputDecoration(
                    labelText: 'State',
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All States')),
                    DropdownMenuItem(value: 'Karnataka', child: Text('Karnataka')),
                    DropdownMenuItem(value: 'Delhi', child: Text('Delhi')),
                    DropdownMenuItem(value: 'Maharashtra', child: Text('Maharashtra')),
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
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Pincode',
                    hintText: defaultPincode.isNotEmpty ? defaultPincode : null,
                    isDense: true,
                  ),
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
                  _refresh();
                });
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
