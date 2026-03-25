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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = constraints.maxWidth < 360 ? 12.0 : 16.0;
                  final sectionGap = constraints.maxWidth < 360 ? 16.0 : 20.0;

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(horizontalPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPeriodSelector(),
                        SizedBox(height: sectionGap),
                        _buildOverviewSection(stats),
                        SizedBox(height: sectionGap),
                        _buildUserAnalytics(stats),
                        SizedBox(height: sectionGap),
                        _buildShopkeeperAnalytics(stats),
                        SizedBox(height: sectionGap),
                        _buildOfferAnalytics(stats),
                      ],
                    ),
                  );
                },
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 430;
            return Column(
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
                if (isCompact)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPeriodChip('7days', '7 Days'),
                      _buildPeriodChip('30days', '30 Days'),
                      _buildPeriodChip('90days', '90 Days'),
                      _buildPeriodChip('all', 'All Time'),
                    ],
                  )
                else
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String value, String label) {
    final isSelected = _selectedPeriod == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (!selected) return;
        setState(() {
          _selectedPeriod = value;
          _loadAnalytics();
        });
      },
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
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = width >= 1024
                ? 4
                : width >= 720
                    ? 3
                    : width >= 420
                        ? 2
                        : 1;
            final isCompact = width < 360;
            final childAspectRatio = crossAxisCount == 1
                ? (isCompact ? 2.7 : 3.1)
                : (isCompact ? 1.25 : 1.45);

            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: childAspectRatio,
              children: [
                FadeInUp(
                  child: _buildMetricCard(
                    'Total Users',
                    totalUsers.toString(),
                    Icons.people_rounded,
                    AppColors.primary,
                    compact: isCompact,
                  ),
                ),
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: _buildMetricCard(
                    'Shopkeepers',
                    totalShopkeepers.toString(),
                    Icons.store_rounded,
                    AppColors.accent,
                    compact: isCompact,
                  ),
                ),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: _buildMetricCard(
                    'Active Offers',
                    activeOffers.toString(),
                    Icons.local_offer_rounded,
                    AppColors.success,
                    compact: isCompact,
                  ),
                ),
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: _buildMetricCard(
                    'Pending Approvals',
                    pendingShopkeepers.toString(),
                    Icons.pending_rounded,
                    AppColors.warning,
                    compact: isCompact,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    {
    bool compact = false,
    }
  ) {
    return GradientCard(
      gradient: LinearGradient(
        colors: [color, color.withOpacity(0.7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.white, size: compact ? 20 : 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: compact ? 11 : 12,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.white,
                fontSize: compact ? 24 : 28,
                fontWeight: FontWeight.bold,
              ),
            ),
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
