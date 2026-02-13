import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/dialog_helper.dart';
import '../../widgets/theme_toggle.dart';
import '../role_selection/role_selection_screen.dart';
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';
import '../../models/offer_model.dart';
import '../../models/user_model.dart';
import '../../widgets/offer_card.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const OffersTab(),
    const FavoritesTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await DialogHelper.showExitDialog(context);
        return shouldExit;
      },
      child: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.local_offer_rounded),
                label: 'Offers',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_rounded),
                label: 'Favorites',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late Future<List<OfferModel>> _featuredOffersFuture;

  @override
  void initState() {
    super.initState();
    _featuredOffersFuture = AuthService.instance.getCustomerOffers();
  }

  Future<void> _refresh() async {
    setState(() {
      _featuredOffersFuture = AuthService.instance.getCustomerOffers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = AuthStore.currentUser;
    final name = (user != null && user.name.isNotEmpty) ? user.name : 'Customer';

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.backgroundGradient
            : AppColors.lightBackgroundGradient,
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
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
                            decoration: InputDecoration(
                              hintText: AppStrings.search,
                              border: InputBorder.none,
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.tune_rounded),
                                onPressed: () {
                                  // Navigate to offers tab with filters
                                  DefaultTabController.of(context).animateTo(1);
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FadeInLeft(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Featured Offers',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                // Navigate to offers tab
                                DefaultTabController.of(context).animateTo(1);
                              },
                              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                              label: const Text('View All'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<List<OfferModel>>(
                        future: _featuredOffersFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
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
                                    style: Theme.of(context).textTheme.titleMedium,
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
                          final featuredOffers = offers.take(6).toList();

                          if (featuredOffers.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.local_offer_outlined,
                                    size: 64,
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No offers available',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Check back later for new offers',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
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
                                      delay: Duration(milliseconds: 100 * index),
                                      child: Container(
                                        width: 280,
                                        margin: EdgeInsets.only(
                                          right: index < featuredOffers.length - 1 ? 12 : 0,
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
                              if (offers.length > 6)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Center(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        DefaultTabController.of(context).animateTo(1);
                                      },
                                      icon: const Icon(Icons.arrow_forward_rounded),
                                      label: Text('View ${offers.length - 6} more offers'),
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
                            color: isDark ? AppColors.surface : AppColors.lightSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.2),
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
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Browse all available offers and find the best deals near you',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward_rounded),
                                onPressed: () {
                                  DefaultTabController.of(context).animateTo(1);
                                },
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

class OffersTab extends StatelessWidget {
  const OffersTab({super.key});

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
        child: _CustomerOffersBody(),
      ),
    );
  }
}

class _CustomerOffersBody extends StatefulWidget {
  const _CustomerOffersBody();

  @override
  State<_CustomerOffersBody> createState() => _CustomerOffersBodyState();
}

class _CustomerOffersBodyState extends State<_CustomerOffersBody> {
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
    // Load all offers without filters initially
    _future = AuthService.instance.getCustomerOffers();
    print('[CUSTOMER_OFFERS] Initializing - Loading all offers');
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

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((offer) {
        return offer.title.toLowerCase().contains(query) ||
            offer.description.toLowerCase().contains(query);
      }).toList();
    }

    // Apply sorting
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
              // Search bar
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
              // Sort dropdown
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
              print('[CUSTOMER_OFFERS_UI] FutureBuilder state: ${snapshot.connectionState}, hasError: ${snapshot.hasError}, hasData: ${snapshot.hasData}');
              if (snapshot.hasData) {
                print('[CUSTOMER_OFFERS_UI] Data received: ${snapshot.data?.length ?? 0} offers');
                _allOffers = snapshot.data ?? [];
              }
              if (snapshot.hasError) {
                print('[CUSTOMER_OFFERS_UI] Error: ${snapshot.error}');
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

class FavoritesTab extends StatefulWidget {
  const FavoritesTab({super.key});

  @override
  State<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> {
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
                              onPressed: () {
                                // Navigate to offers tab
                                DefaultTabController.of(context).animateTo(1);
                              },
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

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late Future<UserModel> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = AuthService.instance.fetchCurrentUser();
  }

  Future<void> _reload() async {
    setState(() {
      _userFuture = AuthService.instance.fetchCurrentUser();
    });
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
        child: FutureBuilder<UserModel>(
          future: _userFuture,
          builder: (context, snapshot) {
            final user = snapshot.data;
            final displayName = user?.name.isEmpty == true || user == null
                ? 'Customer'
                : user.name;
            final displayPhone = user?.phone ?? '';

            return Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  title: const Text('Profile'),
                  actions: const [
                    ThemeToggleButton(),
                  ],
                ),
                const SizedBox(height: 20),
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary,
                  child:
                      Icon(Icons.person_rounded, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const CircularProgressIndicator()
                else ...[
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (displayPhone.isNotEmpty)
                    Text(
                      '+91 $displayPhone',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
                const SizedBox(height: 32),
                Expanded(
                  child: ListView(
                    children: [
                      const ThemeToggle(),
                      _buildProfileOption(
                        context,
                        icon: Icons.edit_rounded,
                        title: 'Edit Profile',
                        onTap: () => _openEditProfileDialog(context, user),
                      ),
                      _buildProfileOption(
                        context,
                        icon: Icons.location_on_rounded,
                        title: 'My Addresses',
                        onTap: () => _openEditProfileDialog(context, user),
                      ),
                      _buildProfileOption(
                        context,
                        icon: Icons.settings_rounded,
                        title: 'Settings',
                        onTap: () => _openSettingsDialog(context),
                      ),
                      _buildProfileOption(
                        context,
                        icon: Icons.help_rounded,
                        title: 'Help & Support',
                        onTap: () => _openHelpDialog(context),
                      ),
                      _buildProfileOption(
                        context,
                        icon: Icons.info_rounded,
                        title: 'About',
                        onTap: () => _openAboutDialog(context),
                      ),
                      _buildProfileOption(
                        context,
                        icon: Icons.logout_rounded,
                        title: 'Logout',
                        isDestructive: true,
                        onTap: () async {
                          final shouldLogout =
                              await DialogHelper.showLogoutDialog(context);
                          if (shouldLogout && context.mounted) {
                            AuthStore.clear();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (_) => const RoleSelectionScreen()),
                              (route) => false,
                            );
                            DialogHelper.showSuccessSnackBar(
                                context, 'Logged out successfully');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon,
            color: isDestructive ? AppColors.error : AppColors.primary),
        title: Text(
          title,
          style: TextStyle(color: isDestructive ? AppColors.error : null),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }

  Future<void> _openEditProfileDialog(
      BuildContext context, UserModel? user) async {
    final nameController =
        TextEditingController(text: user?.name ?? '');
    final pincodeController =
        TextEditingController(text: user?.pincode ?? '');
    final addressController =
        TextEditingController(text: user?.address ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration:
                      const InputDecoration(labelText: 'Full Name'),
                ),
                TextField(
                  controller: pincodeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Pincode'),
                ),
                TextField(
                  controller: addressController,
                  decoration:
                      const InputDecoration(labelText: 'Address'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != true) return;
    if (nameController.text.trim().isEmpty) {
      DialogHelper.showErrorSnackBar(context, 'Name is required');
      return;
    }

    try {
      await AuthService.instance.updateCurrentUser(
        name: nameController.text.trim(),
        address: addressController.text.trim().isEmpty
            ? null
            : addressController.text.trim(),
        pincode: pincodeController.text.trim().isEmpty
            ? null
            : pincodeController.text.trim(),
      );
      if (!mounted) return;
      await _reload();
      DialogHelper.showSuccessSnackBar(context, 'Profile updated');
    } catch (e) {
      if (!mounted) return;
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }

  void _openSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Settings'),
          content: const Text(
            'Use the theme toggle on this screen to switch between light and dark mode. Additional settings can be added here later.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _openHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Help & Support'),
          content: const Text(
            'For support, contact D\'Offer support team or your administrator. This screen can be extended with chat, email, or FAQ links.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _openAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('About D\'Offer'),
          content: const Text(
            'D\'Offer helps you discover hyperlocal deals near you.\n\nVersion 1.0.0',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
