import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/theme_helper.dart';
import '../../services/agent_governance_service.dart';

class CompanySalesAgentListScreen extends StatefulWidget {
  const CompanySalesAgentListScreen({super.key});

  @override
  State<CompanySalesAgentListScreen> createState() =>
      _CompanySalesAgentListScreenState();
}

class _CompanySalesAgentListScreenState
    extends State<CompanySalesAgentListScreen> {
  List<dynamic> _agentList = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  bool? _filterActive;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAgentList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAgentList() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result =
          await AgentGovernanceService.instance.getCompanySalesAgentList(
        search: _searchController.text.isEmpty ? null : _searchController.text,
        isActive: _filterActive,
        page: _currentPage,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _agentList = result['agents'] as List<dynamic>;
          _totalPages = result['totalPages'] as int;
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

  void _onSearch() {
    setState(() {
      _currentPage = 1;
    });
    _loadAgentList();
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
          leading: ThemeHelper.buildBackButton(context),
          backgroundColor: AppColors.transparent,
          elevation: 0,
          title: const Text('Company Sales Agents'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadAgentList,
            ),
          ],
        ),
        body: Column(
          children: [
            _buildFilters(isDark, theme),
            Expanded(
              child: _isLoading
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
                                onPressed: _loadAgentList,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _agentList.isEmpty
                          ? const Center(
                              child: Text('No company sales agents found'))
                          : RefreshIndicator(
                              onRefresh: _loadAgentList,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(20),
                                itemCount: _agentList.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == _agentList.length) {
                                    return _buildPagination(theme);
                                  }
                                  return _buildAgentCard(
                                      _agentList[index], isDark, theme);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeHelper.getSurfaceColor(context),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name, email, or phone',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        _onSearch();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (_) => _onSearch(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SegmentedButton<bool?>(
                  segments: const [
                    ButtonSegment(value: null, label: Text('All')),
                    ButtonSegment(value: true, label: Text('Active')),
                    ButtonSegment(value: false, label: Text('Inactive')),
                  ],
                  selected: {_filterActive},
                  onSelectionChanged: (Set<bool?> newSelection) {
                    setState(() {
                      _filterActive = newSelection.first;
                      _currentPage = 1;
                    });
                    _loadAgentList();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgentCard(
      Map<String, dynamic> agent, bool isDark, ThemeData theme) {
    final name = agent['name'] as String? ?? 'N/A';
    final email = agent['email'] as String? ?? 'N/A';
    final phone = agent['phone'] as String? ?? 'N/A';
    final workingHours = agent['workingHours'] as String?;
    final isActive = agent['isActive'] as bool? ?? false;
    final onboardingCount = agent['onboardingCount'] as int? ?? 0;
    final totalDiscounts = agent['totalDiscounts'] as num? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeHelper.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: isActive
                    ? AppColors.success.withValues(alpha: 0.2)
                    : AppColors.error.withValues(alpha: 0.2),
                child: Icon(
                  Icons.business_center_rounded,
                  color: isActive ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.success.withValues(alpha: 0.2)
                                : AppColors.error.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isActive ? 'Active' : 'Inactive',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isActive
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: theme.dividerColor.withValues(alpha: 0.1)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.email_rounded,
                  size: 16, color: theme.textTheme.bodySmall?.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  email,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.phone_rounded,
                  size: 16, color: theme.textTheme.bodySmall?.color),
              const SizedBox(width: 8),
              Text(
                phone,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  'Onboardings',
                  onboardingCount.toString(),
                  Icons.person_add_rounded,
                  AppColors.primary,
                  isDark,
                  theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetric(
                  'Discounts',
                  '₹${totalDiscounts.toStringAsFixed(0)}',
                  Icons.discount_rounded,
                  AppColors.success,
                  isDark,
                  theme,
                ),
              ),
            ],
          ),
          if (workingHours != null && workingHours.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Hours: ${workingHours.trim()}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetric(
    String label,
    String value,
    IconData icon,
    Color color,
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
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(ThemeData theme) {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                    _loadAgentList();
                  }
                : null,
          ),
          Text(
            'Page $_currentPage of $_totalPages',
            style: theme.textTheme.bodyMedium,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: _currentPage < _totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                    _loadAgentList();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
