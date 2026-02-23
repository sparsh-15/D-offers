import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/theme_helper.dart';
import '../../services/super_admin_service.dart';
import 'users_management_screen.dart';
import 'shops_management_screen.dart';
import 'audit_logs_screen.dart';
import 'agent_coupon_governance_screen.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  Map<String, dynamic>? _analytics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final analytics =
          await SuperAdminService.instance.getDashboardAnalytics();
      if (mounted) {
        setState(() {
          _analytics = analytics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = ThemeHelper.isDarkMode(context);

    return Container(
      decoration: BoxDecoration(
        gradient: ThemeHelper.getBackgroundGradient(context),
      ),
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.transparent,
          elevation: 0,
          title: const Text('Super Admin Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadAnalytics,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text('Error: $_error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadAnalytics,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadAnalytics,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'System Overview',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildQuickStats(isDark, theme),
                          const SizedBox(height: 24),
                          _buildUsersByRole(isDark, theme),
                          const SizedBox(height: 24),
                          _buildSubscriptionStats(isDark, theme),
                          const SizedBox(height: 24),
                          _buildQuickActions(isDark, theme),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildQuickStats(bool isDark, ThemeData theme) {
    final usersByRole =
        _analytics?['usersByRole'] as Map<String, dynamic>? ?? {};
    final totalShops = _analytics?['totalShops'] as int? ?? 0;
    final subscriptions =
        _analytics?['subscriptions'] as Map<String, dynamic>? ?? {};
    final mrr = subscriptions['mrr'] as num? ?? 0;
    final recentActivity = _analytics?['recentActivityCount'] as int? ?? 0;

    int totalUsers = 0;
    usersByRole.forEach((role, data) {
      final roleData = data as Map<String, dynamic>;
      totalUsers += (roleData['total'] as int?) ?? 0;
    });

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Users',
          totalUsers.toString(),
          Icons.people_rounded,
          AppColors.primary,
          isDark,
          theme,
        ),
        _buildStatCard(
          'Total Shops',
          totalShops.toString(),
          Icons.store_rounded,
          AppColors.accent,
          isDark,
          theme,
        ),
        _buildStatCard(
          'MRR',
          '₹${mrr.toStringAsFixed(0)}',
          Icons.currency_rupee_rounded,
          AppColors.success,
          isDark,
          theme,
        ),
        _buildStatCard(
          'Recent Activity',
          recentActivity.toString(),
          Icons.history_rounded,
          AppColors.info,
          isDark,
          theme,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeHelper.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersByRole(bool isDark, ThemeData theme) {
    final usersByRole =
        _analytics?['usersByRole'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeHelper.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Users by Role',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...usersByRole.entries.map((entry) {
            final role = entry.key;
            final data = entry.value as Map<String, dynamic>;
            final total = data['total'] as int? ?? 0;
            final active = data['active'] as int? ?? 0;
            final inactive = data['inactive'] as int? ?? 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child:
                  _buildRoleRow(role, total, active, inactive, isDark, theme),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRoleRow(
    String role,
    int total,
    int active,
    int inactive,
    bool isDark,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackground : AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _formatRole(role),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Total: $total',
              style: theme.textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text('$active', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text('$inactive', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionStats(bool isDark, ThemeData theme) {
    final subscriptions =
        _analytics?['subscriptions'] as Map<String, dynamic>? ?? {};
    final byStatus = subscriptions['byStatus'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeHelper.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.subscriptions_rounded,
                  color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Subscriptions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...byStatus.entries.map((entry) {
            final status = entry.key;
            final data = entry.value as Map<String, dynamic>;
            final count = data['count'] as int? ?? 0;
            final revenue = data['revenue'] as num? ?? 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child:
                  _buildSubscriptionRow(status, count, revenue, isDark, theme),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSubscriptionRow(
    String status,
    int count,
    num revenue,
    bool isDark,
    ThemeData theme,
  ) {
    Color statusColor;
    switch (status) {
      case 'active':
        statusColor = AppColors.success;
        break;
      case 'inactive':
        statusColor = AppColors.warning;
        break;
      case 'expired':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.info;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackground : AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              status.toUpperCase(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$count shops',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(width: 16),
          Text(
            '₹${revenue.toStringAsFixed(0)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          'Manage Users',
          'View and manage all system users',
          Icons.people_rounded,
          AppColors.primary,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UsersManagementScreen(),
            ),
          ),
          isDark,
          theme,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          'Manage Shops',
          'View shops and subscriptions',
          Icons.store_rounded,
          AppColors.accent,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ShopsManagementScreen(),
            ),
          ),
          isDark,
          theme,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          'Agent & Coupon Governance',
          'Manage agents and track coupons',
          Icons.support_agent_rounded,
          AppColors.warning,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AgentCouponGovernanceScreen(),
            ),
          ),
          isDark,
          theme,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          'Audit Logs',
          'View system activity logs',
          Icons.history_rounded,
          AppColors.info,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AuditLogsScreen(),
            ),
          ),
          isDark,
          theme,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isDark,
    ThemeData theme,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ThemeHelper.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  String _formatRole(String role) {
    return role
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
