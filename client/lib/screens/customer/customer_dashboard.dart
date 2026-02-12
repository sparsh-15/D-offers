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
import '../../services/auth_service.dart';
import '../../services/auth_store.dart';
import '../../models/offer_model.dart';
import '../../models/user_model.dart';

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

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

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
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.transparent,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, Customer!',
                    style: Theme.of(context).textTheme.titleMedium,
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
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: AppStrings.search,
                            border: InputBorder.none,
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.tune_rounded),
                              onPressed: () {},
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeInLeft(
                      child: Text(
                        'Featured Offers',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
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
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();

  @override
  void dispose() {
    _cityController.dispose();
    _pincodeController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Offers Near You'),
        ),
        _buildFilters(context),
        Expanded(
          child: FutureBuilder<List<OfferModel>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Failed to load offers\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }
              final offers = snapshot.data ?? [];
              if (offers.isEmpty) {
                return const Center(
                  child: Text('No offers found for the selected filters yet'),
                );
              }
              return RefreshIndicator(
                onRefresh: _refresh,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    int crossAxisCount;
                    if (width < 500) {
                      crossAxisCount = 1;
                    } else if (width < 900) {
                      crossAxisCount = 2;
                    } else {
                      crossAxisCount = 3;
                    }

                    if (crossAxisCount == 1) {
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: offers.length,
                        itemBuilder: (context, index) {
                          final o = offers[index];
                          return FadeInUp(
                            delay: Duration(milliseconds: 80 * index),
                            child: OfferCard(offer: o),
                          );
                        },
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 4 / 3,
                      ),
                      itemCount: offers.length,
                      itemBuilder: (context, index) {
                        final o = offers[index];
                        return FadeInUp(
                          delay: Duration(milliseconds: 80 * index),
                          child: OfferCard(offer: o),
                        );
                      },
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

  Widget _buildFilters(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 480;

    final user = AuthStore.currentUser;
    final defaultPincode = user?.pincode ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isNarrow
              ? Column(
                  children: _buildFilterFields(defaultPincode),
                )
              : Row(
                  children: _buildFilterFields(defaultPincode),
                ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (_stateFilter != null && _stateFilter!.isNotEmpty)
                Chip(label: Text('State: $_stateFilter')),
              if (_cityFilter != null && _cityFilter!.isNotEmpty)
                Chip(label: Text('City: $_cityFilter')),
              if (_pincodeFilter != null && _pincodeFilter!.isNotEmpty)
                Chip(label: Text('Pincode: $_pincodeFilter')),
              if ((_stateFilter == null || _stateFilter!.isEmpty) &&
                  (_cityFilter == null || _cityFilter!.isEmpty) &&
                  (_pincodeFilter == null || _pincodeFilter!.isEmpty))
                const Text('Showing all active offers'),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFilterFields(String defaultPincode) {
    return [
      Expanded(
        child: DropdownButtonFormField<String>(
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
            setState(() {
              _stateFilter = value;
            });
          },
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: TextField(
          controller: _cityController,
          decoration: const InputDecoration(
            labelText: 'City',
            isDense: true,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: TextField(
          controller: _pincodeController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Pincode',
            hintText: defaultPincode.isNotEmpty ? defaultPincode : null,
            isDense: true,
          ),
        ),
      ),
      const SizedBox(width: 8),
      ElevatedButton(
        onPressed: () {
          setState(() {
            _stateFilter = _stateFilter; // already bound by dropdown
            _cityFilter = _cityController.text.trim().isEmpty
                ? null
                : _cityController.text.trim();
            _pincodeFilter = _pincodeController.text.trim().isEmpty
                ? null
                : _pincodeController.text.trim();
            _future = AuthService.instance.getCustomerOffers(
              state: _stateFilter,
              city: _cityFilter,
              pincode: _pincodeFilter,
            );
          });
        },
        child: const Text('Apply'),
      ),
      const SizedBox(width: 4),
      TextButton(
        onPressed: () {
          setState(() {
            _stateFilter = null;
            _cityFilter = null;
            _pincodeFilter = null;
            _cityController.clear();
            _pincodeController.clear();
            _future = AuthService.instance.getCustomerOffers();
          });
        },
        child: const Text('Clear'),
      ),
    ];
  }
}

class FavoritesTab extends StatelessWidget {
  const FavoritesTab({super.key});

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
              title: const Text('Favorites'),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Your favorite shops will appear here',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
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
                          context, Icons.edit_rounded, 'Edit Profile'),
                      _buildProfileOption(
                          context, Icons.location_on_rounded, 'My Addresses'),
                      _buildProfileOption(
                          context, Icons.settings_rounded, 'Settings'),
                      _buildProfileOption(
                          context, Icons.help_rounded, 'Help & Support'),
                      _buildProfileOption(context, Icons.info_rounded, 'About'),
                      _buildProfileOption(
                          context, Icons.logout_rounded, 'Logout',
                          isDestructive: true),
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
}

Widget _buildProfileOption(BuildContext context, IconData icon, String title,
    {bool isDestructive = false}) {
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
      onTap: () async {
        if (title == 'Logout') {
          final shouldLogout = await DialogHelper.showLogoutDialog(context);
          if (shouldLogout && context.mounted) {
            AuthStore.clear();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
              (route) => false,
            );
            DialogHelper.showSuccessSnackBar(
                context, 'Logged out successfully');
          }
        }
      },
    ),
  );
}
