import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/theme_helper.dart';
import '../../services/agent_governance_service.dart';
import 'ssa_list_screen.dart';
import 'company_sales_agent_list_screen.dart';
import 'coupon_activations_screen.dart';

class AgentCouponGovernanceScreen extends StatefulWidget {
  const AgentCouponGovernanceScreen({super.key});

  @override
  State<AgentCouponGovernanceScreen> createState() =>
      _AgentCouponGovernanceScreenState();
}

class _AgentCouponGovernanceScreenState
    extends State<AgentCouponGovernanceScreen> {
  Map<String, dynamic>? _dashboard;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dashboard = await AgentGovernanceService.instance.getDashboard();
      if (mounted) {
        setState(() {
          _dashboard = dashboard;
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
          title: const Text('Agent & Coupon Governance'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadDashboard,
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
                          onPressed: _loadDashboard,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadDashboard,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overview',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildQuickStats(isDark, theme),
                          const SizedBox(height: 24),
                          Text(
                            'Quick Actions',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildQuickActions(isDark, theme),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildQuickStats(bool isDark, ThemeData theme) {
    final totalSSA = _dashboard?['totalSSA'] as int? ?? 0;
    final totalCompanySalesAgents =
        _dashboard?['totalCompanySalesAgents'] as int? ?? 0;
    final totalCouponActivations =
        _dashboard?['totalCouponActivations'] as int? ?? 0;
    final totalDiscounts = _dashboard?['totalDiscounts'] as num? ?? 0;
    final totalOnboardings = _dashboard?['totalOnboardings'] as int? ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'SSA Agents',
          totalSSA.toString(),
          Icons.support_agent_rounded,
          AppColors.primary,
          isDark,
          theme,
        ),
        _buildStatCard(
          'Sales Agents',
          totalCompanySalesAgents.toString(),
          Icons.business_center_rounded,
          AppColors.accent,
          isDark,
          theme,
        ),
        _buildStatCard(
          'Coupon Uses',
          totalCouponActivations.toString(),
          Icons.confirmation_number_rounded,
          AppColors.info,
          isDark,
          theme,
        ),
        _buildStatCard(
          'Total Discounts',
          '₹${totalDiscounts.toStringAsFixed(0)}',
          Icons.discount_rounded,
          AppColors.success,
          isDark,
          theme,
        ),
        _buildStatCard(
          'Onboardings',
          totalOnboardings.toString(),
          Icons.person_add_rounded,
          AppColors.warning,
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

  Widget _buildQuickActions(bool isDark, ThemeData theme) {
    return Column(
      children: [
        _buildActionButton(
          'View SSA List',
          'Manage State Sales Agents',
          Icons.support_agent_rounded,
          AppColors.primary,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SSAListScreen(),
            ),
          ),
          isDark,
          theme,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          'View Company Sales Agents',
          'Manage company sales representatives',
          Icons.business_center_rounded,
          AppColors.accent,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CompanySalesAgentListScreen(),
            ),
          ),
          isDark,
          theme,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          'Track Coupon Activations',
          'Monitor coupon usage and discounts',
          Icons.confirmation_number_rounded,
          AppColors.info,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CouponActivationsScreen(),
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
}
