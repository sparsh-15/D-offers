import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/theme_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../widgets/gradient_card.dart';
import '../../services/auth_service.dart';
import '../../services/subscription_service.dart';
import '../../models/offer_model.dart';
import 'shop_profile_body.dart';
import '../../widgets/offer_card.dart';
import '../common/offer_detail_screen.dart';
import 'offer_details_screen.dart';
import 'onboarding_flow.dart';

class ShopDashboard extends StatefulWidget {
  const ShopDashboard({super.key});

  @override
  State<ShopDashboard> createState() => _ShopDashboardState();
}

class _ShopDashboardState extends State<ShopDashboard> {
  int _selectedIndex = 0;
  VoidCallback? _refreshOffers;
  bool _showOnboarding = true;
  bool _hasActiveSubscription = false;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
    _screens = [
      const ShopHomeTab(),
      OffersManagementTab(
        onRefreshCallbackSet: (callback) {
          _refreshOffers = callback;
        },
      ),
      const LeadsTab(),
      const ShopProfileTab(),
    ];
  }

  Future<void> _checkSubscriptionStatus() async {
    try {
      final subscription = await SubscriptionService.instance.getSubscription();
      final isActive = subscription['isActive'] == true ||
          subscription['status'] == 'active';
      if (!mounted) return;
      setState(() {
        _hasActiveSubscription = isActive;
        if (!_hasActiveSubscription) {
          _selectedIndex = 3;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasActiveSubscription = false;
        _selectedIndex = 3;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to verify subscription. Please log in again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return OnboardingFlow(
        onComplete: () {
          setState(() => _showOnboarding = false);
          _checkSubscriptionStatus();
        },
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await DialogHelper.showExitDialog(context);
        if (shouldExit && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            // If no active subscription, only allow Profile tab (index 3)
            if (!_hasActiveSubscription && index != 3) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please subscribe to access this feature'),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
            setState(() => _selectedIndex = index);
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.dashboard_rounded,
                color: !_hasActiveSubscription ? AppColors.grey : null,
              ),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.local_offer_rounded,
                color: !_hasActiveSubscription ? AppColors.grey : null,
              ),
              label: 'Offers',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.people_rounded,
                color: !_hasActiveSubscription ? AppColors.grey : null,
              ),
              label: 'Leads',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.store_rounded),
              label: 'Shop',
            ),
          ],
        ),
        floatingActionButton: _selectedIndex == 1 && _hasActiveSubscription
            ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OfferDetailsScreen(
                        onSaved: () {
                          _refreshOffers?.call();
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Offer'),
              )
            : null,
      ),
    );
  }
}

class ShopHomeTab extends StatefulWidget {
  const ShopHomeTab({super.key});

  @override
  State<ShopHomeTab> createState() => _ShopHomeTabState();
}

class _ShopHomeTabState extends State<ShopHomeTab> {
  late Future<List<OfferModel>> _offersFuture;

  @override
  void initState() {
    super.initState();
    _offersFuture = AuthService.instance.getShopkeeperOffers();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          BoxDecoration(gradient: ThemeHelper.getBackgroundGradient(context)),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.transparent,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Shop Dashboard',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Manage your business',
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
              child: FutureBuilder<List<OfferModel>>(
                future: _offersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'Failed to load stats\n${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  final offers = snapshot.data ?? [];
                  final activeOffers = offers
                      .where((o) => o.status == 'active')
                      .length
                      .toString();
                  final totalLikes =
                      offers.fold<int>(0, (sum, o) => sum + o.likesCount);

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInDown(
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  'Active Offers',
                                  activeOffers,
                                  Icons.local_offer_rounded,
                                  AppColors.primaryGradient,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  'Total Offers',
                                  offers.length.toString(),
                                  Icons.list_alt_rounded,
                                  AppColors.primaryGradient,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        FadeInDown(
                          delay: const Duration(milliseconds: 100),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  'Total Likes',
                                  totalLikes.toString(),
                                  Icons.favorite_rounded,
                                  AppColors.primaryGradient,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  'Avg. Likes',
                                  offers.isEmpty
                                      ? '0'
                                      : (totalLikes / offers.length)
                                          .toStringAsFixed(1),
                                  Icons.trending_up_rounded,
                                  AppColors.primaryGradient,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeInLeft(
                          child: Text(
                            'Quick Actions',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInUp(
                          child: _buildQuickAction(
                            context,
                            'Add New Offer',
                            'Create attractive offers for customers',
                            Icons.add_circle_rounded,
                            AppColors.primary,
                          ),
                        ),
                        FadeInUp(
                          delay: const Duration(milliseconds: 100),
                          child: _buildQuickAction(
                            context,
                            'View My Offers',
                            'Manage your existing offers',
                            Icons.local_offer_rounded,
                            AppColors.accent,
                          ),
                        ),
                      ],
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

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Gradient gradient,
  ) {
    return GradientCard(
      gradient: gradient,
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.white, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.white.withValues(alpha: 0.9),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () {
          if (title == 'Add New Offer') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OfferDetailsScreen(
                  onSaved: () {
                    setState(() {
                      _offersFuture =
                          AuthService.instance.getShopkeeperOffers();
                    });
                  },
                ),
              ),
            );
          } else if (title == 'View My Offers') {
            // Switch to offers tab
            final dashboardState =
                context.findAncestorStateOfType<_ShopDashboardState>();
            dashboardState?.setState(() {
              dashboardState._selectedIndex = 1;
            });
          }
        },
      ),
    );
  }
}

class OffersManagementTab extends StatelessWidget {
  final Function(VoidCallback)? onRefreshCallbackSet;

  const OffersManagementTab({super.key, this.onRefreshCallbackSet});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          BoxDecoration(gradient: ThemeHelper.getBackgroundGradient(context)),
      child: SafeArea(
        child: _OffersManagementBody(
          onRefreshCallbackSet: onRefreshCallbackSet,
        ),
      ),
    );
  }
}

class _OffersManagementBody extends StatefulWidget {
  final Function(VoidCallback)? onRefreshCallbackSet;

  const _OffersManagementBody({this.onRefreshCallbackSet});

  @override
  State<_OffersManagementBody> createState() => _OffersManagementBodyState();
}

class _OffersManagementBodyState extends State<_OffersManagementBody> {
  late Future<List<OfferModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = AuthService.instance.getShopkeeperOffers();
    // Register the refresh callback
    widget.onRefreshCallbackSet?.call(_refresh);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = AuthService.instance.getShopkeeperOffers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          backgroundColor: AppColors.transparent,
          title: const Text('My Offers'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _refresh,
            ),
          ],
        ),
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
                return const Center(child: Text('No offers yet'));
              }
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: offers.length,
                  itemBuilder: (context, index) {
                    final o = offers[index];
                    return FadeInUp(
                      delay: Duration(milliseconds: 100 * index),
                      child: OfferCard(
                        offer: o,
                        showLikes: false,
                        openDetailOnTap: false,
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'view') {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => OfferDetailScreen(
                                    offer: o,
                                    onChatPressed: null,
                                  ),
                                ),
                              );
                            } else if (value == 'edit') {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => OfferDetailsScreen(
                                    offer: o,
                                    onSaved: _refresh,
                                  ),
                                ),
                              );
                            } else if (value == 'delete') {
                              _deleteOffer(context, o);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility_rounded, size: 20),
                                  SizedBox(width: 12),
                                  Text('View'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_rounded, size: 20),
                                  SizedBox(width: 12),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_rounded,
                                      size: 20, color: AppColors.error),
                                  SizedBox(width: 12),
                                  Text('Delete',
                                      style: TextStyle(color: AppColors.error)),
                                ],
                              ),
                            ),
                          ],
                        ),
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

  Future<void> _deleteOffer(BuildContext context, OfferModel offer) async {
    final confirm = await DialogHelper.showConfirmDialog(
      context: context,
      title: 'Delete Offer',
      message: 'Are you sure you want to delete "${offer.title}"?',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDestructive: true,
    );
    if (!confirm) return;
    try {
      await AuthService.instance.deleteOffer(offer.id);
      if (!context.mounted) return;
      DialogHelper.showSuccessSnackBar(context, 'Offer deleted');
      await _refresh();
    } catch (e) {
      if (!context.mounted) return;
      DialogHelper.showErrorSnackBar(context, e.toString());
    }
  }
}

class LeadsTab extends StatelessWidget {
  const LeadsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          BoxDecoration(gradient: ThemeHelper.getBackgroundGradient(context)),
      child: SafeArea(
        child: Column(
          children: [
            AppBar(
              backgroundColor: AppColors.transparent,
              title: const Text('Customer Leads'),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Customer leads will appear here',
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

class ShopProfileTab extends StatefulWidget {
  const ShopProfileTab({super.key});

  @override
  State<ShopProfileTab> createState() => _ShopProfileTabState();
}

class _ShopProfileTabState extends State<ShopProfileTab> {
  Map<String, dynamic>? _subscription;
  int? _offerCount;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionDetails();
  }

  Future<void> _loadSubscriptionDetails() async {
    setState(() => _loading = true);
    try {
      final dashboard = await AuthService.instance.getShopkeeperDashboard();
      final subscription = dashboard['subscription'] as Map<String, dynamic>?;
      int? offerCount;
      if (subscription != null &&
          (subscription['status'] == 'active' ||
              subscription['isActive'] == true)) {
        final offers = await AuthService.instance.getShopkeeperOffers();
        offerCount = offers.where((o) => o.status != 'inactive').length;
      }
      if (!mounted) return;
      setState(() {
        _subscription = subscription;
        _offerCount = offerCount;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '—';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return '—';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Widget _buildSubscriptionCard(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: LinearProgressIndicator(),
      );
    }
    if (_subscription == null) {
      return const SizedBox.shrink();
    }
    final planSnapshot =
        _subscription?['planSnapshot'] as Map<String, dynamic>?;
    final planName =
        planSnapshot?['displayName'] ?? planSnapshot?['name'] ?? 'Plan';
    final status = (_subscription?['status'] ?? 'inactive').toString();
    final maxOffers = planSnapshot?['maxOffers'];
    final offerLimitLabel = maxOffers == null || maxOffers == -1
        ? 'Unlimited offers'
        : '${_offerCount ?? 0} / $maxOffers offers used';
    final startDate = _formatDate(_subscription?['startDate']);
    final endDate = _formatDate(_subscription?['endDate']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: ThemeHelper.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subscription',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '$planName • ${status.toUpperCase()}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Text(
            offerLimitLabel,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Valid: $startDate → $endDate',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState =
        context.findAncestorStateOfType<_ShopDashboardState>();
    final hasSubscription = dashboardState?._hasActiveSubscription ?? false;

    return Container(
      decoration:
          BoxDecoration(gradient: ThemeHelper.getBackgroundGradient(context)),
      child: SafeArea(
        child: Column(
          children: [
            _buildSubscriptionCard(context),
            if (!hasSubscription)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: AppColors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Subscribe to Unlock All Features',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create offers, reach customers, and grow your business',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.white.withValues(alpha: 0.9),
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Subscription plans coming soon'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.white,
                        foregroundColor: AppColors.accent,
                      ),
                      child: const Text('View Plans'),
                    ),
                  ],
                ),
              ),
            const Expanded(
              child: ShopProfileBody(),
            ),
          ],
        ),
      ),
    );
  }
}
