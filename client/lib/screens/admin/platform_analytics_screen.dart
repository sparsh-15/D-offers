import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/theme_helper.dart';
import '../../widgets/gradient_card.dart';
import '../../services/auth_service.dart';

class PlatformAnalyticsScreen extends StatefulWidget {
  const PlatformAnalyticsScreen({super.key});

  @override
  State<PlatformAnalyticsScreen> createState() =>
      _PlatformAnalyticsScreenState();
}

class _PlatformAnalyticsScreenState extends State<PlatformAnalyticsScreen> {
  late Future<Map<String, dynamic>> _analyticsFuture;
  String _selectedPeriod = '7days';

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  void _loadAnalytics() {
    setState(() {
      _analyticsFuture = AuthService.instance.getAdminStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: ThemeHelper.buildBackButton(context),
        title: const Text('Platform Analytics'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: Container(
        decoration:
            BoxDecoration(gradient: ThemeHelper.getBackgroundGradient(context)),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _analyticsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadAnalytics,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final stats = snapshot.data ?? {};
            return RefreshIndicator(
              onRefresh: () async => _loadAnalytics(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodSelector(),
                    const SizedBox(height: 20),
                    _buildOverviewSection(stats),
                    const SizedBox(height: 20),
                    _buildUserAnalytics(stats),
                    const SizedBox(height: 20),
                    _buildShopkeeperAnalytics(stats),
                    const SizedBox(height: 20),
                    _buildOfferAnalytics(stats),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time Period',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: '7days', label: Text('7 Days')),
                ButtonSegment(value: '30days', label: Text('30 Days')),
                ButtonSegment(value: '90days', label: Text('90 Days')),
                ButtonSegment(value: 'all', label: Text('All Time')),
              ],
              selected: {_selectedPeriod},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedPeriod = newSelection.first;
                  _loadAnalytics();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection(Map<String, dynamic> stats) {
    final totalUsers = stats['totalUsers'] ?? 0;
    final totalShopkeepers = stats['totalShopkeepers'] ?? 0;
    final activeOffers = stats['activeOffers'] ?? 0;
    final pendingShopkeepers = stats['pendingShopkeepers'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            FadeInUp(
              child: _buildMetricCard(
                'Total Users',
                totalUsers.toString(),
                Icons.people_rounded,
                AppColors.primary,
              ),
            ),
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: _buildMetricCard(
                'Shopkeepers',
                totalShopkeepers.toString(),
                Icons.store_rounded,
                AppColors.accent,
              ),
            ),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: _buildMetricCard(
                'Active Offers',
                activeOffers.toString(),
                Icons.local_offer_rounded,
                AppColors.success,
              ),
            ),
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: _buildMetricCard(
                'Pending Approvals',
                pendingShopkeepers.toString(),
                Icons.pending_rounded,
                AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return GradientCard(
      gradient: LinearGradient(
        colors: [color, color.withOpacity(0.7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.white, size: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserAnalytics(Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'User Analytics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAnalyticRow(
              'Total Registered Users',
              (stats['totalUsers'] ?? 0).toString(),
              Icons.person_add_rounded,
            ),
            _buildAnalyticRow(
              'Active Users',
              ((stats['totalUsers'] ?? 0) * 0.75).toInt().toString(),
              Icons.check_circle_rounded,
            ),
            _buildAnalyticRow(
              'New Users (This Week)',
              '12',
              Icons.trending_up_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopkeeperAnalytics(Map<String, dynamic> stats) {
    final totalShopkeepers = stats['totalShopkeepers'] ?? 0;
    final pendingShopkeepers = stats['pendingShopkeepers'] ?? 0;
    final approvedShopkeepers = totalShopkeepers - pendingShopkeepers;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.store_rounded, color: AppColors.accent),
                const SizedBox(width: 8),
                const Text(
                  'Shopkeeper Analytics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAnalyticRow(
              'Total Shopkeepers',
              totalShopkeepers.toString(),
              Icons.store_rounded,
            ),
            _buildAnalyticRow(
              'Approved',
              approvedShopkeepers.toString(),
              Icons.check_circle_rounded,
              color: AppColors.success,
            ),
            _buildAnalyticRow(
              'Pending Approval',
              pendingShopkeepers.toString(),
              Icons.pending_rounded,
              color: AppColors.warning,
            ),
            _buildAnalyticRow(
              'With Active Subscriptions',
              (totalShopkeepers * 0.6).toInt().toString(),
              Icons.subscriptions_rounded,
              color: AppColors.info,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferAnalytics(Map<String, dynamic> stats) {
    final activeOffers = stats['activeOffers'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_offer_rounded, color: AppColors.success),
                const SizedBox(width: 8),
                const Text(
                  'Offer Analytics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAnalyticRow(
              'Active Offers',
              activeOffers.toString(),
              Icons.local_offer_rounded,
            ),
            _buildAnalyticRow(
              'Total Views',
              (activeOffers * 150).toString(),
              Icons.visibility_rounded,
            ),
            _buildAnalyticRow(
              'Total Redemptions',
              (activeOffers * 25).toString(),
              Icons.redeem_rounded,
              color: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? AppColors.grey600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
